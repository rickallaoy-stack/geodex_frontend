import 'package:flutter/material.dart';

class HistoriquePesees extends StatelessWidget {
  final List<dynamic> pesees;
  const HistoriquePesees({super.key, required this.pesees});

  @override
  Widget build(BuildContext context) {
    if (pesees.isEmpty) return const Text('Aucune pesée disponible');
    return Column(
      children: pesees.map((p) {
        return ListTile(
          dense: true,
          title: Text('${p['poids_mesure_kg']} kg'),
          subtitle: Text(p['date_releve'] ?? ''),
        );
      }).toList(),
    );
  }
}
