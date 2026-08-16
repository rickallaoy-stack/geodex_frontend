import 'package:flutter/material.dart';
import '../models/permis_minier.dart';

// ─── Palette GEODEX (issue de core/theme.dart) ───────────────────────────────
const _bg = Color(0xFF0E1117);
const _surface = Color(0xFF161B22);
const _surfaceElevated = Color(0xFF1C2230);
const _border = Color(0xFF2A3244);
const _textPrimary = Color(0xFFE6EDF3);
const _textMuted = Color(0xFF7D8590);

const _colorActif = Color(0xFF3FB950);
const _colorIllegale = Color(0xFFFF4444);
const _colorSuspendu = Color(0xFF4D8FD6);
const _colorExpire = Color(0xFF8B949E);
const _colorAlerte = Color(0xFFFF4444);

// Couleurs ressource (dots)
const _colorOr = Color(0xFFD4A843);
const _colorNickel = Color(0xFF7BBFDE);
const _colorManganese = Color(0xFFB87AE0);
const _colorPetrole = Color(0xFF5BBBAD);

/// Sidebar principale de l'interface GEODEX.
///
/// Reçoit :
/// - les états des couches (toggles)
/// - le filtre ressource actif
/// - la liste des permis à afficher
/// - le permis sélectionné
/// - des callbacks pour notifier le parent (MapScreen)
class SidebarPanel extends StatelessWidget {
  const SidebarPanel({
    super.key,
    required this.coucheGeologie,
    required this.couchePermis,
    required this.coucheSitesIllegaux,
    required this.coucheGeofences,
    required this.filtreRessource,
    required this.permis,
    required this.permisSelectionne,
    required this.onToggleCouche,
    required this.onFiltreRessource,
    required this.onSelectPermis,
  });

  // États couches
  final bool coucheGeologie;
  final bool couchePermis;
  final bool coucheSitesIllegaux;
  final bool coucheGeofences;

  // Filtre ressource : null = "Tout"
  final String? filtreRessource;

  // Données
  final List<PermisMinier> permis;
  final PermisMinier? permisSelectionne;

  // Callbacks
  final void Function(String couche, bool value) onToggleCouche;
  final void Function(String? ressource) onFiltreRessource;
  final void Function(PermisMinier permis) onSelectPermis;

  @override
  Widget build(BuildContext context) {
    final permisAffiches = filtreRessource == null
        ? permis
        : permis
            .where((p) =>
                p.ressource.toLowerCase() ==
                filtreRessource!.toLowerCase())
            .toList();

    return Container(
      width: 256,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section COUCHES ──────────────────────────────────────────────
          _SectionHeader(label: 'COUCHES'),
          _CoucheToggle(
            label: 'Géologie BGS',
            dotColor: const Color(0xFFF4C542),
            value: coucheGeologie,
            onChanged: (v) => onToggleCouche('geologie', v),
          ),
          _CoucheToggle(
            label: 'Permis actifs',
            dotColor: _colorActif,
            value: couchePermis,
            onChanged: (v) => onToggleCouche('permis', v),
          ),
          _CoucheToggle(
            label: 'Sites illégaux',
            dotColor: _colorIllegale,
            value: coucheSitesIllegaux,
            onChanged: (v) => onToggleCouche('illegaux', v),
          ),
          _CoucheToggle(
            label: 'Geofences actifs',
            dotColor: const Color(0xFF4D8FD6),
            value: coucheGeofences,
            onChanged: (v) => onToggleCouche('geofences', v),
          ),

          _Divider(),

          // ── Section RESSOURCE ────────────────────────────────────────────
          _SectionHeader(label: 'RESSOURCE'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _FiltreChip(
                  label: 'Tout',
                  color: _textMuted,
                  actif: filtreRessource == null,
                  onTap: () => onFiltreRessource(null),
                ),
                _FiltreChip(
                  label: 'Or',
                  color: _colorOr,
                  actif: filtreRessource == 'Or',
                  onTap: () => onFiltreRessource('Or'),
                ),
                _FiltreChip(
                  label: 'Nickel',
                  color: _colorNickel,
                  actif: filtreRessource == 'Nickel',
                  onTap: () => onFiltreRessource('Nickel'),
                ),
                _FiltreChip(
                  label: 'Manganèse',
                  color: _colorManganese,
                  actif: filtreRessource == 'Manganèse',
                  onTap: () => onFiltreRessource('Manganèse'),
                ),
                _FiltreChip(
                  label: 'Pétrole',
                  color: _colorPetrole,
                  actif: filtreRessource == 'Pétrole',
                  onTap: () => onFiltreRessource('Pétrole'),
                ),
              ],
            ),
          ),

          _Divider(),

          // ── Section PERMIS ───────────────────────────────────────────────
          _SectionHeader(label: 'PERMIS'),

          Expanded(
            child: permisAffiches.isEmpty
                ? Center(
                    child: Text(
                      'Aucun permis pour ce filtre',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: permisAffiches.length,
                    itemBuilder: (context, index) {
                      final p = permisAffiches[index];
                      final selected = permisSelectionne?.id == p.id;
                      return _PermisCard(
                        permis: p,
                        selected: selected,
                        onTap: () => onSelectPermis(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Sous-widgets internes ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: _border,
    );
  }
}

class _CoucheToggle extends StatelessWidget {
  const _CoucheToggle({
    required this.label,
    required this.dotColor,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Color dotColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: value ? dotColor : _textMuted.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? _textPrimary : _textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: dotColor,
            activeTrackColor: dotColor.withOpacity(0.3),
            inactiveThumbColor: _textMuted,
            inactiveTrackColor: _border,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _FiltreChip extends StatelessWidget {
  const _FiltreChip({
    required this.label,
    required this.color,
    required this.actif,
    required this.onTap,
  });

  final String label;
  final Color color;
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
          color: actif ? color.withOpacity(0.18) : _surfaceElevated,
          border: Border.all(
            color: actif ? color : _border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: actif ? color : _textMuted,
            fontSize: 12,
            fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _PermisCard extends StatelessWidget {
  const _PermisCard({
    required this.permis,
    required this.selected,
    required this.onTap,
  });

  final PermisMinier permis;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statut = permis.statut;
    final badgeColor = _badgeColor(statut);
    final badgeLabel = _badgeLabel(statut);
    final isIllegale = statut == StatutPermis.illegal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.fromLTRB(8, 3, 8, 3),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: selected ? _surfaceElevated : _surface,
          border: Border.all(
            color: selected
                ? badgeColor.withOpacity(0.6)
                : isIllegale
                    ? _colorIllegale.withOpacity(0.4)
                    : _border,
            width: isIllegale || selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge + nom
            Row(
              children: [
                _Badge(label: badgeLabel, color: badgeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    permis.nom,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Société · Ressource · Superficie
            Row(
              children: [
                Text(
                  '${permis.societe} · ${permis.ressource}',
                  style:
                      const TextStyle(color: _textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                 Text(
                  '${_formatSuperficie(permis.superficieHa)} ha',
                  style:
                      const TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),

            // Alerte illégale
            if (isIllegale) ...[
              const SizedBox(height: 5),
              Row(
                children: const [
                  Icon(Icons.warning_rounded,
                      color: _colorAlerte, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Hors permis · Alerte active',
                    style: TextStyle(
                        color: _colorAlerte,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _badgeColor(StatutPermis s) {
    switch (s) {
      case StatutPermis.valide:
        return _colorActif;
      case StatutPermis.illegal:
        return _colorIllegale;
      case StatutPermis.suspendu:
        return _colorSuspendu;
      case StatutPermis.revoque:
        return _colorExpire;
      case StatutPermis.enAttente:
        return _colorExpire;
    }
  }

  String _badgeLabel(StatutPermis s) {
    switch (s) {
      case StatutPermis.valide:
        return 'Valide';
      case StatutPermis.illegal:
        return 'Illégal';
      case StatutPermis.suspendu:
        return 'Suspendu';
      case StatutPermis.revoque:
        return 'Révoqué';
      case StatutPermis.enAttente:
        return 'En attente';
    }
  }

  String _formatSuperficie(double ha) {
    if (ha >= 1000) {
      return '${(ha / 1000).toStringAsFixed(0)} k';
    }
    return ha.toStringAsFixed(0);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}