import 'package:flutter/material.dart';

class AlertesOperateur extends StatelessWidget {
  final List<dynamic> alertes;
  const AlertesOperateur({super.key, required this.alertes});

  @override
  Widget build(BuildContext context) {
    if (alertes.isEmpty) return const Text('Aucune alerte');
    return Column(
      children: alertes.map((a) => ListTile(
        dense: true,
        title: Text(a['type_anomalie'] ?? ''),
        subtitle: Text(a['description_detaillee'] ?? ''),
        trailing: Text(a['date_alerte'] ?? ''),
      )).toList(),
    );
  }
}
