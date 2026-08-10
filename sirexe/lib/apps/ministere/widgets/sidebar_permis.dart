import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/permis_minier.dart';

class SidebarPermis extends StatefulWidget {
  final PermisMinier? selected;
  final ValueChanged<PermisMinier> onSelect;
  final bool showGeology, showPermis, showIllegal, showGeofences;
  final ValueChanged<bool> onToggleGeology, onTogglePermis,
    onToggleIllegal, onToggleGeofences;
  final VoidCallback onSimulerAlerte;

  const SidebarPermis({super.key,
    this.selected,
    required this.onSelect,
    required this.showGeology, required this.showPermis,
    required this.showIllegal, required this.showGeofences,
    required this.onToggleGeology, required this.onTogglePermis,
    required this.onToggleIllegal, required this.onToggleGeofences,
    required this.onSimulerAlerte,
  });

  @override
  State<SidebarPermis> createState() => _SidebarPermisState();
}

class _SidebarPermisState extends State<SidebarPermis> {
  StatutPermis? _filter;

  List<PermisMinier> get _filtered => _filter == null
    ? permisDemo
    : permisDemo.where((p) => p.statut == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: SirexeTheme.surface,
      child: Column(children: [
        // Couches
        _Section(title: 'COUCHES', child: Column(children: [
          _LayerRow(label: 'Géologie BGS',  color: const Color(0xFFD4A843),
            value: widget.showGeology,  onChanged: widget.onToggleGeology),
          _LayerRow(label: 'Permis actifs', color: SirexeTheme.accent,
            value: widget.showPermis,   onChanged: widget.onTogglePermis),
          _LayerRow(label: 'Sites illégaux',color: SirexeTheme.danger,
            value: widget.showIllegal,  onChanged: widget.onToggleIllegal),
          _LayerRow(label: 'Geofences',     color: SirexeTheme.accentBlue,
            value: widget.showGeofences,onChanged: widget.onToggleGeofences),
        ])),

        // Filtres
        _Section(title: 'FILTRE', child: Wrap(spacing: 4, runSpacing: 4,
          children: [
            _Chip(label: 'Tout', active: _filter == null,
              onTap: () => setState(() => _filter = null)),
            _Chip(label: 'Actifs', active: _filter == StatutPermis.actif,
              onTap: () => setState(() => _filter = StatutPermis.actif)),
            _Chip(label: 'Illégaux', active: _filter == StatutPermis.illegal,
              color: SirexeTheme.danger,
              onTap: () => setState(() => _filter = StatutPermis.illegal)),
            _Chip(label: 'Suspendus',
              active: _filter == StatutPermis.suspendu,
              color: SirexeTheme.warning,
              onTap: () => setState(() => _filter = StatutPermis.suspendu)),
          ],
        )),

        // Bouton démo alerte
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GestureDetector(
            onTap: widget.onSimulerAlerte,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: SirexeTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: SirexeTheme.danger.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline,
                    color: SirexeTheme.danger, size: 14),
                  SizedBox(width: 6),
                  Text('Simuler alerte fraude',
                    style: TextStyle(color: SirexeTheme.danger,
                      fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),

        // Header liste
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            const Text('PERMIS', style: TextStyle(
              color: SirexeTheme.textSecondary, fontSize: 10,
              fontWeight: FontWeight.w500, letterSpacing: 1)),
            const Spacer(),
            Text('${_filtered.length}', style: const TextStyle(
              color: SirexeTheme.textSecondary, fontSize: 11)),
          ]),
        ),

        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final p = _filtered[i];
              final sel = widget.selected?.id == p.id;
              final ill = p.statut == StatutPermis.illegal;
              return GestureDetector(
                onTap: () => widget.onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sel
                      ? SirexeTheme.accentBlue.withOpacity(0.1)
                      : ill
                        ? SirexeTheme.danger.withOpacity(0.05)
                        : SirexeTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel ? SirexeTheme.accentBlue
                        : ill ? SirexeTheme.danger.withOpacity(0.4)
                        : SirexeTheme.border,
                      width: sel ? 1.5 : 0.5),
                  ),
                  child: Row(children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: p.couleur, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nom, style: const TextStyle(
                          color: SirexeTheme.textPrimary,
                          fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${p.ressource} · '
                          '${p.superficieHa.toStringAsFixed(0)} ha',
                          style: const TextStyle(
                            color: SirexeTheme.textSecondary,
                            fontSize: 10)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.couleur.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4)),
                      child: Text(p.statutLabel, style: TextStyle(
                        color: p.couleur, fontSize: 9,
                        fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(
        color: SirexeTheme.border, width: 0.5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 10,
        fontWeight: FontWeight.w500, letterSpacing: 1)),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _LayerRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _LayerRow({required this.label, required this.color,
    required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(width: 10, height: 10,
          decoration: BoxDecoration(
            color: value ? color.withOpacity(0.7) : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(
          color: value
            ? SirexeTheme.textPrimary : SirexeTheme.textSecondary,
          fontSize: 12))),
        Container(
          width: 28, height: 16,
          decoration: BoxDecoration(
            color: value ? color : SirexeTheme.border,
            borderRadius: BorderRadius.circular(8)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value
              ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 12, height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      ]),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  const _Chip({required this.label, required this.active,
    required this.onTap, this.color = SirexeTheme.accentBlue});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : SirexeTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: active ? color.withOpacity(0.5) : SirexeTheme.border)),
      child: Text(label, style: TextStyle(
        color: active ? color : SirexeTheme.textSecondary,
        fontSize: 11)),
    ),
  );
}
