import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_icon.dart';
import '../../../models/terrain_modules.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  final List<_PhotoEntry> _photos = [];

  Future<void> _classifier(_PhotoEntry entry) async {
    final classificateur = TerrainServices.classificateur;
    final result = await classificateur.classifier(
      imageBytes: entry.bytes,
      permisId: 'demo-001',
    );
    if (!mounted) return;
    setState(() => entry.resultat = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      appBar: AppBar(
        backgroundColor: SirexeTheme.surface,
        title: const Text('Classification roche', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _photos.isEmpty
        ? const Center(child: Text('Ajoutez une photo pour classer', style: TextStyle(color: SirexeTheme.textSecondary)))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PhotoCard(
              entry: _photos[i],
              onClassify: () => _classifier(_photos[i]),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _photos.add(_PhotoEntry(bytes: [], resultat: null)));
        },
        backgroundColor: SirexeTheme.accent,
        icon: AppIcon.fromIconData(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
        label: const Text('Ajouter photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PhotoEntry {
  List<int> bytes;
  ResultatClassification? resultat;
  _PhotoEntry({required this.bytes, this.resultat});
}

class _PhotoCard extends StatelessWidget {
  final _PhotoEntry entry;
  final VoidCallback onClassify;
  const _PhotoCard({required this.entry, required this.onClassify});

  @override
  Widget build(BuildContext context) {
    final result = entry.resultat;
    final color = result == null
      ? SirexeTheme.textSecondary
      : result.categorie == CategorieRoche.minerai
        ? SirexeTheme.accent
        : result.categorie == CategorieRoche.sterile
          ? SirexeTheme.warning
          : SirexeTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SirexeTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: SirexeTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppIcon.fromIconData(Icons.image_outlined, color: SirexeTheme.textSecondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result == null ? 'Photo non classée' : result.categorie.name.toUpperCase(), style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(result == null ? 'Appuyez pour classer' : 'Confiance : ${(result.confidence * 100).toStringAsFixed(0)}%', style: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
          ])),
          if (result == null)
            TextButton.icon(
              onPressed: onClassify,
              icon: AppIcon.fromIconData(Icons.auto_fix_high_outlined, color: SirexeTheme.accentBlue, size: 16),
              label: const Text('Classer', style: TextStyle(color: SirexeTheme.accentBlue, fontSize: 12)),
            )
          else
            AppIcon.fromIconData(Icons.check_circle_outline, color: SirexeTheme.accent, size: 18),
        ]),
      ]),
    );
  }
}
