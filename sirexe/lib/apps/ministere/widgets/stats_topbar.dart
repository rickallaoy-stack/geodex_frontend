import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/permis_minier.dart';

class StatsTopbar extends StatelessWidget implements PreferredSizeWidget {
  final int alerteCount;
  final VoidCallback onAlerteTap;
  const StatsTopbar({super.key,
    required this.alerteCount, required this.onAlerteTap});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final actifs    = permisDemo.where((p) => p.statut == StatutPermis.actif).length;
    final suspendus = permisDemo.where((p) => p.statut == StatutPermis.suspendu).length;
    final expires   = permisDemo.where((p) => p.statut == StatutPermis.expire).length;

    return Container(
      color: SirexeTheme.surface,
      child: Column(children: [
        Container(height: 0.5, color: SirexeTheme.border),
        SizedBox(height: 51.5,
          child: Row(children: [
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SirexeTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: SirexeTheme.accentBlue.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: SirexeTheme.accentBlue, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                const Text('GEODEX', style: TextStyle(
                  color: SirexeTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13, letterSpacing: 2)),
              ]),
            ),
            const SizedBox(width: 10),
            const Text('Système de gestion des permis miniers · CI',
              style: TextStyle(
                color: SirexeTheme.textSecondary, fontSize: 12)),
            const Spacer(),
            _StatPill(count: actifs,    label: 'actifs',
              color: SirexeTheme.accent),
            const SizedBox(width: 6),
            _StatPill(count: suspendus, label: 'suspendus',
              color: SirexeTheme.warning),
            const SizedBox(width: 6),
            _StatPill(count: expires,   label: 'expirés',
              color: SirexeTheme.textSecondary),
            const SizedBox(width: 8),
            if (alerteCount > 0)
              GestureDetector(
                onTap: onAlerteTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SirexeTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: SirexeTheme.danger.withOpacity(0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.warning_amber_rounded,
                      color: SirexeTheme.danger, size: 13),
                    const SizedBox(width: 5),
                    Text('$alerteCount alerte${alerteCount > 1 ? 's' : ''} fraude',
                      style: const TextStyle(color: SirexeTheme.danger,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            const SizedBox(width: 16),
          ]),
        ),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatPill({required this.count,
    required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SirexeTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SirexeTheme.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$count $label', style: const TextStyle(
          color: SirexeTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }
}
