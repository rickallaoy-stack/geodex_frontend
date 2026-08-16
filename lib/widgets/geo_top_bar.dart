import 'package:flutter/material.dart';
import '../models/permis_minier.dart';

// ─── Palette GEODEX ───────────────────────────────────────────────────────────
const _bg = Color(0xFF0E1117);
const _surface = Color(0xFF161B22);
const _border = Color(0xFF2A3244);
const _textPrimary = Color(0xFFE6EDF3);
const _textMuted = Color(0xFF7D8590);

const _colorActif = Color(0xFF3FB950);
const _colorSuspendu = Color(0xFF4D8FD6);
const _colorExpire = Color(0xFF8B949E);
const _colorAlerte = Color(0xFFFF4444);

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
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // ── Logo GEODEX ──────────────────────────────────────────────
          _GeoLogo(),
          const SizedBox(width: 16),

          // ── Séparateur vertical ──────────────────────────────────────
          Container(width: 1, height: 24, color: _border),
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
                    dotColor: _colorActif,
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
                    dotColor: _colorSuspendu,
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
                    dotColor: _colorExpire,
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
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: _textMuted,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo GEODEX ─────────────────────────────────────────────────────────────

class _GeoLogo extends StatefulWidget {
  @override
  State<_GeoLogo> createState() => _GeoLogoState();
}

class _GeoLogoState extends State<_GeoLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Point pulsant
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4D8FD6).withOpacity(_pulse.value),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4D8FD6)
                      .withOpacity(_pulse.value * 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'GEODEX',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Cadastre minier · Côte d\'Ivoire',
              style: TextStyle(
                color: _textMuted,
                fontSize: 9,
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
          color: actif ? dotColor.withOpacity(0.15) : _surface,
          border: Border.all(
            color: actif ? dotColor.withOpacity(0.5) : _border,
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
                      color: actif ? dotColor : _textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: label.replaceAll('\n', ' '),
                    style: const TextStyle(
                      color: _textMuted,
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
              ? _colorAlerte.withOpacity(0.30)
              : _colorAlerte.withOpacity(0.15),
          border: Border.all(
            color: _colorAlerte.withOpacity(actif ? 0.8 : 0.5),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_rounded,
              color: _colorAlerte,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              '$count alertes',
              style: const TextStyle(
                color: _colorAlerte,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              'fraude',
              style: TextStyle(color: _colorAlerte, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
