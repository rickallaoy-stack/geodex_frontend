import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/permis_minier.dart';
import '../core/theme.dart';

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
      color: SirexeTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section COUCHES ──────────────────────────────────────────────
          _SectionHeader(label: 'COUCHES'),
          _CoucheToggle(
            label: 'Géologie BGS',
            dotColor: SirexeTheme.resourceGold,
            value: coucheGeologie,
            onChanged: (v) => onToggleCouche('geologie', v),
            iconAsset: 'assets/images/icon_layer_dark.svg',
          ),
            _CoucheToggle(
            label: 'Permis actifs',
            dotColor: SirexeTheme.success,
            value: couchePermis,
            onChanged: (v) => onToggleCouche('permis', v),
            iconAsset: 'assets/images/icon_pin_dark.svg',
          ),
            _CoucheToggle(
            label: 'Sites illégaux',
            dotColor: SirexeTheme.danger,
            value: coucheSitesIllegaux,
            onChanged: (v) => onToggleCouche('illegaux', v),
            iconAsset: 'assets/images/icon_alert_dark.svg',
          ),
            _CoucheToggle(
            label: 'Geofences actifs',
            dotColor: SirexeTheme.accentBlue,
            value: coucheGeofences,
            onChanged: (v) => onToggleCouche('geofences', v),
            iconAsset: 'assets/images/icon_layer_dark.svg',
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
                  color: SirexeTheme.textSecondary,
                  actif: filtreRessource == null,
                  onTap: () => onFiltreRessource(null),
                ),
                _FiltreChip(
                  label: 'Or',
                  color: SirexeTheme.resourceGold,
                  actif: filtreRessource == 'Or',
                  onTap: () => onFiltreRessource('Or'),
                ),
                _FiltreChip(
                  label: 'Nickel',
                  color: SirexeTheme.resourceNickel,
                  actif: filtreRessource == 'Nickel',
                  onTap: () => onFiltreRessource('Nickel'),
                ),
                _FiltreChip(
                  label: 'Manganèse',
                  color: SirexeTheme.resourceManganese,
                  actif: filtreRessource == 'Manganèse',
                  onTap: () => onFiltreRessource('Manganèse'),
                ),
                _FiltreChip(
                  label: 'Pétrole',
                  color: SirexeTheme.resourceOil,
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
                      style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12),
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
        style: TextStyle(
          color: SirexeTheme.textSecondary,
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
      color: SirexeTheme.border,
    );
  }
}

class _CoucheToggle extends StatelessWidget {
  const _CoucheToggle({
    required this.label,
    required this.dotColor,
    required this.value,
    required this.onChanged,
    this.iconAsset,
  });

  final String label;
  final Color dotColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(iconAsset!, width: 18, height: 18),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: value ? dotColor : SirexeTheme.textSecondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? SirexeTheme.textPrimary : SirexeTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: dotColor,
            activeTrackColor: dotColor.withOpacity(0.3),
            inactiveThumbColor: SirexeTheme.textSecondary,
            inactiveTrackColor: SirexeTheme.border,
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
          color: actif ? color.withOpacity(0.18) : SirexeTheme.surfaceElevated,
          border: Border.all(
            color: actif ? color : SirexeTheme.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: actif ? color : SirexeTheme.textSecondary,
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
          color: selected ? SirexeTheme.surfaceElevated : SirexeTheme.surface,
          border: Border.all(
            color: selected
                ? badgeColor.withOpacity(0.6)
                : isIllegale
                    ? SirexeTheme.danger.withOpacity(0.4)
                    : SirexeTheme.border,
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
                    style: TextStyle(
                      color: SirexeTheme.textPrimary,
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
                      TextStyle(color: SirexeTheme.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                 Text(
                  '${_formatSuperficie(permis.superficieHa)} ha',
                  style:
                      TextStyle(color: SirexeTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),

            // Alerte illégale
            if (isIllegale) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                      SizedBox(width: 12, height: 12, child: SvgPicture.asset('assets/images/icon_alert_dark.svg')),
                  const SizedBox(width: 4),
                  Text(
                    'Hors permis · Alerte active',
                    style: TextStyle(
                        color: SirexeTheme.danger,
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
        return SirexeTheme.success;
      case StatutPermis.illegal:
        return SirexeTheme.danger;
      case StatutPermis.suspendu:
        return SirexeTheme.accentBlue;
      case StatutPermis.revoque:
        return SirexeTheme.textSecondary;
      case StatutPermis.enAttente:
        return SirexeTheme.textSecondary;
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