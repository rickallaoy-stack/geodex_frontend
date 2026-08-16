import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/permis_minier.dart';

class PermisDetailPanel extends StatelessWidget {
  final PermisMinier permis;
  final VoidCallback onClose;
  final VoidCallback? onSimulerAlerte;
  const PermisDetailPanel({super.key, required this.permis,
    required this.onClose, this.onSimulerAlerte});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        border: Border(
          top: BorderSide(color: permis.couleur, width: 2),
          left: BorderSide(color: SirexeTheme.border, width: 0.5),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: permis.couleur.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: permis.couleur.withOpacity(0.5)),
              ),
              child: Text(permis.statutLabel, style: TextStyle(
                color: permis.couleur, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(permis.nom, style: const TextStyle(
              color: SirexeTheme.textPrimary,
              fontSize: 15, fontWeight: FontWeight.w700))),
            IconButton(
              icon: const Icon(Icons.close, color: SirexeTheme.textSecondary, size: 18),
              onPressed: onClose, padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(permis.id, style: const TextStyle(
            color: SirexeTheme.textSecondary, fontSize: 11)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            _Chip(Icons.business_outlined,  permis.societe),
            _Chip(Icons.diamond_outlined,   permis.ressource),
            _Chip(Icons.straighten,
              '${permis.superficieHa.toStringAsFixed(0)} ha'),
            _Chip(Icons.calendar_today_outlined,
              permis.dateExpiration != null
                ? 'Exp. ${permis.dateExpiration!.day}/${permis.dateExpiration!.month}/${permis.dateExpiration!.year}'
                : 'Exp. —',
              color: permis.statut == StatutPermis.revoque
                ? SirexeTheme.danger : null),
          ]),
        ),
        if (permis.statut == StatutPermis.illegal) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SirexeTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SirexeTheme.danger.withOpacity(0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded,
                  color: SirexeTheme.danger, size: 15),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Site hors permis détecté — Alerte transmise au ministère',
                  style: TextStyle(color: SirexeTheme.danger, fontSize: 11))),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(color: SirexeTheme.border, height: 0.5),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _ActionBtn(Icons.bar_chart_rounded, 'Tonnages'),
            const SizedBox(width: 6),
            _ActionBtn(Icons.history, 'Historique'),
            const SizedBox(width: 6),
            if (onSimulerAlerte != null)
              _ActionBtn(Icons.sensors, 'Simuler GPS',
                danger: true, onTap: onSimulerAlerte),
          ]),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SirexeTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SirexeTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: c, fontSize: 11)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;
  const _ActionBtn(this.icon, this.label, {this.danger = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = danger ? SirexeTheme.danger : SirexeTheme.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: SirexeTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: danger ? SirexeTheme.danger.withOpacity(0.4) : SirexeTheme.border),
          ),
          child: Column(children: [
            Icon(icon, size: 15, color: c),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: c, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
