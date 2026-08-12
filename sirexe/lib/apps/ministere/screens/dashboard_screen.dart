import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme.dart';
import '../../../models/permis_minier.dart';
import '../../../models/alerte_model.dart';
import '../../../core/services/permis_service.dart';
import '../../../core/services/alerte_service.dart';
import '../../../core/services/geofence_alert.dart';
import '../widgets/stats_topbar.dart';
import '../widgets/sidebar_permis.dart';
import '../widgets/permis_detail_panel.dart';
import 'pesees_screen.dart';
import 'verification_chain_screen.dart';
import 'alertes_screen.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();

  Map<String, dynamic>? _geologyData;
  PermisMinier? _selected;
  List<PermisMinier> _permis = permisDemo;

  bool _showGeology = true;
  bool _showPermis = true;
  bool _showIllegal = true;
  bool _showGeofences = false;

  int _tabIndex = 0;

  final AlerteService _alerteService = AlerteService();
  StreamSubscription<List<AlerteModel>>? _alerteSubscription;

  List<AlerteModel> _alertes = [];
  bool _toastVisible = false;
  AlerteModel? _toastAlerte;
  Timer? _toastTimer;

  final Set<int> _alertesVues = {};

  @override
  void initState() {
    super.initState();
    _loadGeology();
    _loadPermis();
    _startAlertesWatch();
  }

  @override
  void dispose() {
    _alerteSubscription?.cancel();
    _alerteService.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGeology() async {
    final str = await rootBundle.loadString('assets/geology_ci.geojson');
    setState(() => _geologyData = json.decode(str));
  }

  Future<void> _loadPermis() async {
    final permis = await PermisService.fetchPermis();
    if (mounted) setState(() => _permis = permis);
  }

  void _startAlertesWatch() {
    _alerteSubscription = _alerteService.watch().listen(
      (alertes) {
        if (!mounted) return;
        final nouvelles = alertes.where((a) => !_alertesVues.contains(a.id));

        setState(() {
          _alertes = alertes;
        });

        if (nouvelles.isNotEmpty) {
          _afficherToast(nouvelles.first);
        }
      },
      onError: (e) {
        if (!mounted) return;
      },
    );
  }

  void _afficherToast(AlerteModel alerte) {
    _alertesVues.add(alerte.id);
    _toastTimer?.cancel();
    setState(() {
      _toastVisible = true;
      _toastAlerte = alerte;
    });
    _toastTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  void _dismissToast() {
    _toastTimer?.cancel();
    setState(() => _toastVisible = false);
  }

  void _onSelectPermis(PermisMinier p) {
    setState(() => _selected = p);
    _mapController.move(p.centre, 9.0);
  }

  void _centrerSurAlerte(AlerteModel alerte) {
    final point = LatLng(alerte.latitude, alerte.longitude);
    _mapController.move(point, 10.0);
    setState(() => _tabIndex = 0);
  }

  Color _geoColor(String? f) {
    switch (f) {
      case 'Sedimentary: Cretaceous to Quaternary':
        return const Color(0xFFD4A843).withOpacity(0.45);
      case 'Igneous':
        return const Color(0xFFB85C3A).withOpacity(0.45);
      case 'Precambrian Basement':
        return const Color(0xFF7A4F2E).withOpacity(0.45);
      case 'Surface water':
        return const Color(0xFF2E6FA8).withOpacity(0.65);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  List<Polygon> _geologyPolygons() {
    if (_geologyData == null) return [];
    final polygons = <Polygon>[];
    for (final f in _geologyData!['features'] as List) {
      final color = _geoColor(f['properties']['CdIGLG']);
      final geom = f['geometry'];
      void add(List coords) => polygons.add(Polygon(
        points: coords.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList(),
        color: color,
        borderColor: color.withOpacity(0.6),
        borderStrokeWidth: 0.5,
      ));
      if (geom['type'] == 'Polygon') {
        add(geom['coordinates'][0]);
      } else if (geom['type'] == 'MultiPolygon') {
        for (final p in geom['coordinates']) add(p[0]);
      }
    }
    return polygons;
  }

  List<Polygon> _permisPolygons() => _permis
      .where((p) => _showIllegal || p.statut != StatutPermis.illegal)
      .map((p) => Polygon(
            points: p.polygone,
            color: p.couleur.withOpacity(_selected?.id == p.id ? 0.35 : 0.18),
            borderColor: p.couleur,
            borderStrokeWidth: _selected?.id == p.id ? 2.5 : (p.statut == StatutPermis.illegal ? 2.0 : 1.2),
            isFilled: true,
          ))
      .toList();

  List<Marker> _permisMarkers() => _permis
      .where((p) => _showIllegal || p.statut != StatutPermis.illegal)
      .map((p) => Marker(
            point: p.centre,
            width: 170,
            height: 34,
            child: GestureDetector(
              onTap: () => _onSelectPermis(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SirexeTheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.couleur, width: _selected?.id == p.id ? 2 : 1),
                  boxShadow: _selected?.id == p.id
                      ? [BoxShadow(color: p.couleur.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                      : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: p.couleur, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(p.nom, style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 10, fontWeight: p.statut == StatutPermis.illegal ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
          ))
      .toList();

  List<CircleMarker> _geofenceCircles() => _permis
      .where((p) => p.statut == StatutPermis.valide)
      .map((p) => CircleMarker(
            point: p.centre,
            radius: 25000,
            useRadiusInMeter: true,
            color: SirexeTheme.accentBlue.withOpacity(0.06),
            borderColor: SirexeTheme.accentBlue.withOpacity(0.4),
            borderStrokeWidth: 1.5,
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      appBar: StatsTopbar(
        alerteCount: _alertes.length,
        onAlerteTap: () => setState(() => _tabIndex = 2),
      ),
      body: Column(children: [
        Container(
          color: SirexeTheme.surface,
          child: Row(children: [
            _Tab(label: 'Carte', icon: Icons.map_outlined, active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
            _Tab(label: 'Pesées', icon: Icons.scale_outlined, active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
            _Tab(label: 'Alertes', icon: Icons.warning_amber_rounded, active: _tabIndex == 2, badge: _alertes.length, onTap: () => setState(() => _tabIndex = 2)),
            _Tab(label: 'Stats', icon: Icons.bar_chart_rounded, active: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3)),
            _Tab(label: 'Chaîne', icon: Icons.link_rounded, active: _tabIndex == 4, onTap: () => setState(() => _tabIndex = 4)),
            Container(height: 40, width: 0.5, color: SirexeTheme.border),
          ]),
        ),
        Container(height: 0.5, color: SirexeTheme.border),
        Expanded(child: _tabIndex == 0
          ? _buildCarteTab()
          : _tabIndex == 1
            ? const PeseesScreen()
            : _tabIndex == 2
              ? const AlertesScreen()
              : _tabIndex == 3
                ? const StatsScreen()
                : const VerificationChainScreen()),
      ]),
    );
  }

  Widget _buildCarteTab() {
    return Stack(children: [
      Row(children: [
        SidebarPermis(
          selected: _selected,
          onSelect: _onSelectPermis,
          showGeology: _showGeology,
          showPermis: _showPermis,
          showIllegal: _showIllegal,
          showGeofences: _showGeofences,
          onToggleGeology: (v) => setState(() => _showGeology = v),
          onTogglePermis: (v) => setState(() => _showPermis = v),
          onToggleIllegal: (v) => setState(() => _showIllegal = v),
          onToggleGeofences: (v) => setState(() => _showGeofences = v),
        ),
        Container(width: 0.5, color: SirexeTheme.border),
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(7.5, -5.5),
                initialZoom: 6.2,
                minZoom: 3,
                maxZoom: 16,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key={key}',
                  additionalOptions: const {'key': '6tZxrsJMAnTertUR2ILg'},
                  userAgentPackageName: 'ci.geodex.app',
                ),
                if (_showGeology && _geologyData != null) PolygonLayer(polygons: _geologyPolygons()),
                if (_showPermis) ...[PolygonLayer(polygons: _permisPolygons()), MarkerLayer(markers: _permisMarkers())],
                if (_showGeofences) CircleLayer(circles: _geofenceCircles()),
              ],
            ),
            Positioned(left: 14, bottom: 16, child: _GeoLegend(visible: _showGeology)),
          ]),
        ),
        if (_selected != null) ...[
          Container(width: 0.5, color: SirexeTheme.border),
          SizedBox(width: 270, child: PermisDetailPanel(permis: _selected!, onClose: () => setState(() => _selected = null))),
        ],
      ]),
      ValueListenableBuilder<GeofenceAlert?>(
        valueListenable: geofenceAlert,
        builder: (context, cas, _) {
          if (cas == null) return const SizedBox.shrink();
          return Positioned(top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cas.severity == 'danger'
                    ? SirexeTheme.danger.withOpacity(0.12)
                    : SirexeTheme.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cas.severity == 'danger'
                      ? SirexeTheme.danger.withOpacity(0.45)
                      : SirexeTheme.warning.withOpacity(0.45),
                ),
              ),
              child: Row(children: [
                Icon(
                  cas.severity == 'danger'
                      ? Icons.warning_amber_rounded
                      : Icons.info_outlined,
                  color: cas.severity == 'danger'
                      ? SirexeTheme.danger
                      : SirexeTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cas.message,
                    style: TextStyle(
                      color: SirexeTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
      if (_toastVisible && _toastAlerte != null)
        Positioned(top: 16, right: 16, child: _AlerteToast(alerte: _toastAlerte!, onTap: () { _centrerSurAlerte(_toastAlerte!); _dismissToast(); }, onDismiss: _dismissToast)),
    ]);
  }
}

class _AlerteToast extends StatefulWidget {
  const _AlerteToast({required this.alerte, required this.onTap, required this.onDismiss});
  final AlerteModel alerte;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  @override
  State<_AlerteToast> createState() => _AlerteToastState();
}

class _AlerteToastState extends State<_AlerteToast> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SirexeTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SirexeTheme.danger, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: SirexeTheme.danger.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SirexeTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: SirexeTheme.danger, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALERTE FRAUDE',
                        style: TextStyle(
                            color: SirexeTheme.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(widget.alerte.libelleType,
                        style: const TextStyle(
                            color: SirexeTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(
                      '${widget.alerte.tempsRelatif} · ${(widget.alerte.poidsMesureKg / 1000).toStringAsFixed(2)} t',
                      style: const TextStyle(
                          color: SirexeTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: SirexeTheme.textSecondary, size: 16),
                onPressed: widget.onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GeoLegend extends StatelessWidget {
  final bool visible;
  const _GeoLegend({required this.visible});
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    const items = [('Sédimentaire', Color(0xFFD4A843)), ('Magmatique', Color(0xFFB85C3A)), ('Socle précamb.', Color(0xFF7A4F2E)), ('Eaux surface', Color(0xFF2E6FA8))];
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: SirexeTheme.surface.withOpacity(0.93), borderRadius: BorderRadius.circular(8), border: Border.all(color: SirexeTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('BGS · CC BY-SA', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 9)),
      const SizedBox(height: 5),
      ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$2.withOpacity(0.6), border: Border.all(color: e.$2), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text(e.$1, style: const TextStyle(color: SirexeTheme.textPrimary, fontSize: 10))]))),
    ]));
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int badge;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.active, required this.onTap, this.badge = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? SirexeTheme.accentBlue : Colors.transparent, width: 2))), child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 15, color: active ? SirexeTheme.accentBlue : SirexeTheme.textSecondary),
    const SizedBox(width: 7),
    Text(label, style: TextStyle(color: active ? SirexeTheme.accentBlue : SirexeTheme.textSecondary, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    if (badge > 0) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: SirexeTheme.danger, borderRadius: BorderRadius.circular(10)), child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))],
  ])));
}
