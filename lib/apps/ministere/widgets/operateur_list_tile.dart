import 'package:flutter/material.dart';

class OperateurListTile extends StatelessWidget {
  final dynamic operateur;
  final VoidCallback? onTap;
  const OperateurListTile({super.key, required this.operateur, this.onTap});

  Color _colorForType(String? t) {
    switch (t) {
      case 'artisanal':
        return Colors.orange.shade300;
      case 'semi_industriel':
        return Colors.deepOrange;
      case 'industriel':
        return Colors.blue.shade600;
      case 'non_repertorie':
      default:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = operateur['classification'] ?? {};
    final type = cls['type'] as String?;
    final color = _colorForType(type);

    final total = (operateur['quota_jour_kg'] ?? 0).toDouble();
    final used = (operateur['quota_jour_consomme_kg'] ?? 0).toDouble();
    final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text((operateur['nom'] as String?)?.substring(0, 1).toUpperCase() ?? '?'),
        ),
        title: Text(operateur['nom'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${operateur['permis_id'] ?? '—'} • ${operateur['site_nom'] ?? ''}'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withOpacity(0.25)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(cls['label'] ?? '', style: TextStyle(color: color.darken(0.2), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12))
          ],
        ),
      ),
    );
  }
}

extension _ColorDarken on Color {
  Color darken([double amount = .1]) {
    final h = HSLColor.fromColor(this);
    final h2 = h.withLightness((h.lightness - amount).clamp(0.0, 1.0));
    return h2.toColor();
  }
}
