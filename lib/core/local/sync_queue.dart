import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pesee.dart';
import '../services/pesee_service.dart';

class SyncQueue {
  static const _key = 'pending_pesees';

  static Future<List<Map<String, dynamic>>> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = json.decode(raw);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(queue));
    } catch (_) {}
  }

  static Future<void> enqueue(
    Pesee p, {
    required String capteurId,
    String signature = '',
  }) async {
    final queue = await _loadQueue();
    final entry = <String, dynamic>{
      'id': p.id,
      'camion_id': p.camionId,
      'permis_id': p.permisId,
      'capteur_id': capteurId,
      'poids_net': p.poidsNet,
      'poids_brut': p.poidsBrut,
      'tare': p.tare,
      'hash': p.hash,
      'signature': signature,
      'gps_lat': p.latitude,
      'gps_lng': p.longitude,
      'timestamp': p.timestamp.toIso8601String(),
      'synced': 0,
    };
    queue.add(entry);
    await _saveQueue(queue);
  }

  static Future<int> countPending() async {
    final queue = await _loadQueue();
    return queue.where((e) => e['synced'] == 0).length;
  }

  static Future<void> syncAll() async {
    final queue = await _loadQueue();
    final pending = queue.where((e) => e['synced'] == 0).toList();
    if (pending.isEmpty) return;

    for (final row in pending) {
      try {
        final res = await PeseeService.envoyerPesee(
          capteurId:           row['capteur_id']?.toString() ?? '',
          poidsMesureKg:       ((row['poids_net'] as num?)?.toDouble() ?? 0.0) * 1000,
          latitude:            (row['gps_lat'] as num?)?.toDouble() ?? 0.0,
          longitude:           (row['gps_lng'] as num?)?.toDouble() ?? 0.0,
          signatureEquipement: row['signature']?.toString() ?? '',
        );
        if (res['success'] == true) {
          row['synced'] = 1;
        }
      } catch (_) {}
    }

    await _saveQueue(queue);
  }

  static Future<void> clear() async {
    await _saveQueue([]);
  }

  static Future<List<Pesee>> fetchPending() async {
    final queue = await _loadQueue();
    return queue
        .where((e) => e['synced'] == 0)
        .map((row) => Pesee(
              id: row['id']?.toString() ?? '',
              camionId: row['camion_id']?.toString() ?? '',
              permisId: row['permis_id']?.toString() ?? '',
              nomSite: 'Hors ligne',
              poidsNet: (row['poids_net'] as num?)?.toDouble() ?? 0.0,
              poidsBrut: (row['poids_brut'] as num?)?.toDouble() ?? 0.0,
              tare: (row['tare'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.tryParse(row['timestamp']?.toString() ?? '') ?? DateTime.now(),
              latitude: (row['gps_lat'] as num?)?.toDouble() ?? 0.0,
              longitude: (row['gps_lng'] as num?)?.toDouble() ?? 0.0,
              hash: row['hash']?.toString() ?? '',
              statut: StatutPesee.valide,
            ))
        .toList();
  }
}
