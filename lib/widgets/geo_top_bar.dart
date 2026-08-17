import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/permis_minier.dart';
import '../core/theme.dart';
import 'app_icon.dart';

/// Topbar principale de GEODEX.
///
/// Calcule automatiquement les compteurs depuis [permis].
/// [filtreActif] : statut actuellement mis en évidence (null = aucun).
/// [onFiltreStatut] : callback quand l'utilisateur clique un chip stat.
/// [onMenu] : callback bouton "···".
class GeoTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GeoTopBar({
    super.key,
    required this.permis,
    this.filtreActif,
    required this.onFiltreStatut,
    this.onMenu,
  });

  final List<PermisMinier> permis;
  final StatutPermis? filtreActif;
  final void Function(StatutPermis? statut) onFiltreStatut;
  final VoidCallback? onMenu;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    // Compteurs
    final nActifs =
        permis.where((p) => p.statut == StatutPermis.valide).length;
    final nSuspendus =
        permis.where((p) => p.statut == StatutPermis.suspendu).length;
    final nExpires =
        permis.where((p) => p.statut == StatutPermis.revoque).length;
    final nAlertes =
        permis.where((p) => p.statut == StatutPermis.illegal).length;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        border: Border(bottom: BorderSide(color: SirexeTheme.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // ── Logo GEODEX ──────────────────────────────────────────────
          _GeoLogo(),
          const SizedBox(width: 16),

          // ── Séparateur vertical ──────────────────────────────────────
          Container(width: 1, height: 24, color: SirexeTheme.border),
          const SizedBox(width: 16),

          // ── Stat chips ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatChip(
                    count: nActifs,
                    label: 'permis\nvalides',
                    dotColor: SirexeTheme.success,
                    actif: filtreActif == StatutPermis.valide,
                    onTap: () => onFiltreStatut(
                      filtreActif == StatutPermis.valide
                          ? null
                          : StatutPermis.valide,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    count: nSuspendus,
                    label: 'suspendus',
                    dotColor: SirexeTheme.accentBlue,
                    actif: filtreActif == StatutPermis.suspendu,
                    onTap: () => onFiltreStatut(
                      filtreActif == StatutPermis.suspendu
                          ? null
                          : StatutPermis.suspendu,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    count: nExpires,
                    label: 'révoqués',
                    dotColor: SirexeTheme.textSecondary,
                    actif: filtreActif == StatutPermis.revoque,
                    onTap: () => onFiltreStatut(
                      filtreActif == StatutPermis.revoque
                          ? null
                          : StatutPermis.revoque,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _AlerteChip(
                    count: nAlertes,
                    actif: filtreActif == StatutPermis.illegal,
                    onTap: () => onFiltreStatut(
                      filtreActif == StatutPermis.illegal
                          ? null
                          : StatutPermis.illegal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu ─────────────────────────────────────────────────────
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onMenu,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SirexeTheme.surfaceElevated,
                border: Border.all(color: SirexeTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcon.fromIconData(
                Icons.more_horiz_rounded,
                color: SirexeTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo GEODEX ─────────────────────────────────────────────────────────────

class _GeoLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo: préfère SVG (assets/images/logo_dark.svg), fallback PNG Gemini
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SvgPicture.asset(
              'assets/images/logo_dark.svg',
              fit: BoxFit.cover,
              placeholderBuilder: (context) => Image.asset(
                'assets/Gemini_Generated_Image_.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEODEX',
              style: TextStyle(
                color: SirexeTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            Text(
              'Cadastre minier · Côte d\'Ivoire',
              style: TextStyle(
                color: SirexeTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Chip stat standard ───────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.count,
    required this.label,
    required this.dotColor,
    required this.actif,
    required this.onTap,
  });

  final int count;
  final String label;
  final Color dotColor;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: actif ? dotColor.withOpacity(0.15) : SirexeTheme.surfaceElevated,
          border: Border.all(
            color: actif ? dotColor.withOpacity(0.5) : SirexeTheme.border,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$count ',
                    style: TextStyle(
                      color: actif ? dotColor : SirexeTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: label.replaceAll('\n', ' '),
                    style: TextStyle(
                      color: SirexeTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chip alerte fraude (variante rouge avec fond fort) ───────────────────────

class _AlerteChip extends StatelessWidget {
  const _AlerteChip({
    required this.count,
    required this.actif,
    required this.onTap,
  });

  final int count;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // Toujours un fond rouge marqué — c'est une alerte
          color: actif
              ? SirexeTheme.danger.withOpacity(0.30)
              : SirexeTheme.danger.withOpacity(0.15),
          border: Border.all(
            color: SirexeTheme.danger.withOpacity(actif ? 0.8 : 0.5),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12, height: 12,
              child: SvgPicture.asset(
                'assets/images/icon_alert_dark.svg',
                width: 12, height: 12, color: SirexeTheme.danger)),
            const SizedBox(width: 5),
            Text(
              '$count alertes',
              style: TextStyle(
                color: SirexeTheme.danger,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'fraude',
              style: TextStyle(color: SirexeTheme.danger, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
