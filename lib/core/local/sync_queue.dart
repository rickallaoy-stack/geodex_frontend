import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/pesee.dart';
import '../services/pesee_service.dart';

class SyncQueue {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'geodex_queue.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE pesees_queue (
          id TEXT PRIMARY KEY,
          camion_id TEXT,
          permis_id TEXT,
          poids_net REAL,
          poids_brut REAL,
          tare REAL,
          hash TEXT,
          signature TEXT,
          gps_lat REAL,
          gps_lng REAL,
          timestamp TEXT,
          synced INTEGER DEFAULT 0
        )
      '''),
    );
    return _db!;
  }

  static Future<void> enqueue(Pesee p, {String signature = ''}) async {
    final d = await db;
    await d.insert('pesees_queue', {
      'id':         p.id,
      'camion_id':  p.camionId,
      'permis_id':  p.permisId,
      'poids_net':  p.poidsNet,
      'poids_brut': p.poidsBrut,
      'tare':       p.tare,
      'hash':       p.hash,
      'signature':  signature,
      'gps_lat':    p.latitude,
      'gps_lng':    p.longitude,
      'timestamp':  p.timestamp.toIso8601String(),
      'synced':     0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> countPending() async {
    final d   = await db;
    final res = await d.rawQuery(
      'SELECT COUNT(*) as n FROM pesees_queue WHERE synced = 0');
    return (res.first['n'] as int?) ?? 0;
  }

  static Future<void> syncAll() async {
    final d    = await db;
    final rows = await d.query('pesees_queue',
      where: 'synced = ?', whereArgs: [0]);

    for (final row in rows) {
      try {
        final res = await PeseeService.envoyerPesee(
          capteurId:           row['permis_id'] as String,
          poidsMesureKg:       row['poids_net'] as double,
          latitude:            row['gps_lat'] as double,
          longitude:           row['gps_lng'] as double,
          signatureEquipement: row['signature'] as String? ?? '',
        );
        if (res['success'] == true) {
          await d.update('pesees_queue', {'synced': 1},
            where: 'id = ?', whereArgs: [row['id']]);
        }
      } catch (_) {
      }
    }
  }
}
