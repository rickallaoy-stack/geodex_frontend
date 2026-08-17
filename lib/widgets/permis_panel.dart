import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/permis_minier.dart';
import 'app_icon.dart';

class PermisPanel extends StatelessWidget {
  final PermisMinier permis;
  final VoidCallback onClose;
  final VoidCallback? onTonnages;
  final VoidCallback? onHistorique;
  final VoidCallback? onSignaler;
  const PermisPanel({super.key, required this.permis, required this.onClose, this.onTonnages, this.onHistorique, this.onSignaler});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: permis.couleur, width: 1.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: permis.couleur.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: permis.couleur),
            ),
            child: Text(permis.statutLabel,
              style: TextStyle(color: permis.couleur,
                fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(permis.nom,
            style: TextStyle(color: SirexeTheme.textPrimary,
              fontWeight: FontWeight.bold, fontSize: 16))),
          IconButton(
            icon: AppIcon.fromIconData(Icons.close, size: 20, color: SirexeTheme.textSecondary),
            onPressed: onClose, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _InfoChip(icon: Icons.business, label: permis.societe),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.diamond_outlined, label: permis.ressource),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.straighten, label: '${permis.superficieHa.toStringAsFixed(0)} ha'),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _InfoChip(icon: Icons.badge_outlined, label: permis.id),
          const SizedBox(width: 8),
          _InfoChip(
            icon: Icons.calendar_today,
            label: permis.dateExpiration != null
              ? 'Exp. ${permis.dateExpiration!.day}/${permis.dateExpiration!.month}/${permis.dateExpiration!.year}'
              : 'Exp. —',
            color: permis.statut == StatutPermis.revoque ? SirexeTheme.danger : null),
        ]),
        if (permis.statut == StatutPermis.illegal) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SirexeTheme.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SirexeTheme.danger.withOpacity(0.5)),
            ),
            child: Row(children: [
              // Utilise le SVG d'alerte
              SizedBox(width: 16, height: 16, child: SvgPicture.asset('assets/images/icon_alert_dark.svg')),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Site hors permis détecté — Alerte envoyée au ministère',
                style: TextStyle(color: SirexeTheme.danger, fontSize: 12))),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          if (onTonnages != null)
            ElevatedButton.icon(
              onPressed: onTonnages,
              icon: AppIcon.fromIconData(Icons.scale, size: 16),
              label: const Text('Tonnages'),
            ),
          const SizedBox(width: 8),
          if (onHistorique != null)
            ElevatedButton.icon(
              onPressed: onHistorique,
              icon: AppIcon.fromIconData(Icons.history, size: 16),
              label: const Text('Historique'),
            ),
          const SizedBox(width: 8),
          if (onSignaler != null)
            ElevatedButton.icon(
              onPressed: onSignaler,
              icon: AppIcon.fromIconData(Icons.report, size: 16),
              label: const Text('Signaler'),
            ),
        ]),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SirexeTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SirexeTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcon.fromIconData(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c, fontSize: 11)),
      ]),
    );
  }
}
