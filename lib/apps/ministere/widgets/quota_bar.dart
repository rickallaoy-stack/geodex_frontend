import 'package:flutter/material.dart';

class QuotaBar extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const QuotaBar({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    final total = (profile?['quota_jour_kg'] ?? 0).toDouble();
    final used = (profile?['quota_jour_consomme_kg'] ?? 0).toDouble();
    final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final color = pct < 0.6 ? Colors.green : (pct < 0.9 ? Colors.orange : Colors.red);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quota journalier', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withValues(alpha: 0.2))),
              const SizedBox(width: 12),
              Text('${(pct * 100).toStringAsFixed(0)}%')
            ]),
            const SizedBox(height: 8),
            Text('${used.toString()} kg utilisés / ${total.toString()} kg'),
          ],
        ),
      ),
    );
  }
}
