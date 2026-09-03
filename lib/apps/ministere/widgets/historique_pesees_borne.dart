import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';
import '../../../core/config/api_config.dart';

class HistoriqueBorneTable extends StatefulWidget {
  final String rfidUid;
  const HistoriqueBorneTable({super.key, required this.rfidUid});

  @override
  State<HistoriqueBorneTable> createState() => _HistoriqueBorneTableState();
}

class _HistoriqueBorneTableState extends State<HistoriqueBorneTable> {
  List<dynamic> _cycles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/inspecteur/${widget.rfidUid}/historique'),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      setState(() => _cycles = data['data'] ?? []);
    } catch (_) {
      if (!mounted) return;
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_cycles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Aucun cycle borne enregistré', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Poids kg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Site', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Hors zone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Distance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Statut', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Borne', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
        rows: _cycles.map((c) {
          final date = DateTime.tryParse(c['date_cycle']?.toString() ?? '')?.toLocal();
          final dateStr = date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
            : '—';
          final horsZone = c['hors_zone'] == true || c['hors_zone'] == 't';
          return DataRow(
            cells: [
              DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
              DataCell(Text((c['poids_net_kg'] as num?)?.toStringAsFixed(2) ?? '—', style: const TextStyle(fontSize: 12))),
              DataCell(Text(c['site_nom'] ?? '—', style: const TextStyle(fontSize: 12))),
              DataCell(Text(horsZone ? 'Oui' : 'Non', style: TextStyle(fontSize: 12, color: horsZone ? SirexeTheme.warning : SirexeTheme.success))),
              DataCell(Text('${c['distance_zone_m'] ?? 0} m', style: const TextStyle(fontSize: 12))),
              DataCell(Text(c['statut'] ?? '—', style: TextStyle(fontSize: 12, color: c['statut'] == 'valide' ? SirexeTheme.success : SirexeTheme.danger))),
              DataCell(Text(c['borne_id'] ?? '—', style: const TextStyle(fontSize: 12))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
