import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_icon.dart';
import '../../../models/terrain_modules.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SessionPesee>> _future;

  @override
  void initState() {
    super.initState();
    _future = TerrainServices.pesee.getPourPermis('demo-001');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      appBar: AppBar(
        backgroundColor: SirexeTheme.surface,
        title: const Text('Historique', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = TerrainServices.pesee.getPourPermis('demo-001')),
            icon: AppIcon.fromIconData(Icons.refresh_outlined, color: SirexeTheme.textSecondary, size: 18),
          ),
        ],
      ),
      body: FutureBuilder<List<SessionPesee>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: SirexeTheme.accentBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: SirexeTheme.danger)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune pesée enregistrée', style: TextStyle(color: SirexeTheme.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _HistoryCard(session: items[i]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SessionPesee session;
  const _HistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SirexeTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: SirexeTheme.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon.fromIconData(Icons.scale_outlined, color: SirexeTheme.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(session.camion, style: const TextStyle(color: SirexeTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${session.netTonnes.toStringAsFixed(1)} t net · ${session.id}', style: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
        ])),
        Text('${session.horodatage.hour.toString().padLeft(2, '0')}:${session.horodatage.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }
}
