import 'package:flutter/material.dart';

class RapportScreen extends StatelessWidget {
  final Map<String, dynamic> rapport;
  const RapportScreen({super.key, required this.rapport});

  @override
  Widget build(BuildContext context) {
    final profil = rapport['profil'] ?? {};
    final quotas = rapport['quotas'] ?? {};
    final pesees = rapport['historique_pesees'] as List<dynamic>? ?? [];
    final alertes = rapport['alertes'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Rapport imprimable')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rapport', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Profil', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Nom: ${profil['nom'] ?? '—'}'),
                  Text('Permis: ${profil['permis'] ?? '—'}'),
                  Text('Statut: ${profil['statut'] ?? '—'}'),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Quota journalier'),
                      const SizedBox(height: 6),
                      Text('${quotas['journalier']?['consommeKg'] ?? 0} / ${quotas['journalier']?['totalKg'] ?? 0} kg'),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Quota mensuel'),
                      const SizedBox(height: 6),
                      Text('${quotas['mensuel']?['consommeKg'] ?? 0} / ${quotas['mensuel']?['totalKg'] ?? 0} kg'),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('Historique des pesées', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...pesees.take(200).map((p) => ListTile(
                  title: Text('${p['poids_mesure_kg']} kg'),
                  subtitle: Text(p['date_releve'] ?? ''),
                  trailing: Text('${p['latitude'] ?? ''}, ${p['longitude'] ?? ''}'),
                )),
            const SizedBox(height: 8),
            const Text('Alertes récentes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...alertes.map((a) => ListTile(title: Text(a['type_anomalie'] ?? ''), subtitle: Text(a['description_detaillee'] ?? '')))
          ],
        ),
      ),
    );
  }
}
