import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../models/permis_minier.dart';
import '../widgets/permis_panel.dart';
import '../widgets/geo_top_bar.dart';
import 'sidebar_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _geologyData;
  PermisMinier? _permisSelectionne;
  bool _coucheGeologie = true;
  bool _couchePermis = true;
  bool _coucheSitesIllegaux = true;
  bool _coucheGeofences = false;
  String? _filtreRessource;
  StatutPermis? _filtreStatut;

  @override
  void initState() {
    super.initState();
    _loadGeology();
  }

  Future<void> _loadGeology() async {
    final str = await rootBundle.loadString('assets/geology_ci.geojson');
    setState(() => _geologyData = json.decode(str));
  }

  void _onToggleCouche(String couche, bool value) {
    setState(() {
      switch (couche) {
        case 'geologie':
          _coucheGeologie = value;
          break;
        case 'permis':
          _couchePermis = value;
          break;
        case 'illegaux':
          _coucheSitesIllegaux = value;
          break;
        case 'geofences':
          _coucheGeofences = value;
          break;
      }
    });
  }

  void _onFiltreRessource(String? ressource) {
    setState(() => _filtreRessource = ressource);
  }

  void _onSelectPermis(PermisMinier p) {
    setState(() => _permisSelectionne = p);
    _mapController.move(p.centre, 9.0);
  }

  void _onFiltreStatut(StatutPermis? statut) {
    setState(() {
      _filtreStatut = statut;
      if (statut != null) _permisSelectionne = null;
    });
  }

  void _onMenu() {
    // TODO: showModalBottomSheet avec options (export, paramètres, sync…)
  }

  void _onTonnages() {
    // TODO: brancher TerrainServices.pesee.totalTonnes
  }

  void _onHistorique() {
    // TODO: afficher l'historique des pesées / classifications
  }

  void _onSignaler() {
    // TODO: envoyer une alerte au ministère
  }

  Color _geologyColor(String? formation) {
    switch (formation) {
      case 'Sedimentary: Cretaceous to Quaternary': return const Color(0xFFD4A843).withOpacity(0.55);
      case 'Igneous':            return const Color(0xFFB85C3A).withOpacity(0.55);
      case 'Precambrian Basement': return const Color(0xFF7A4F2E).withOpacity(0.55);
      case 'Surface water':      return const Color(0xFF2E6FA8).withOpacity(0.70);
      default:                   return Colors.grey.withOpacity(0.3);
    }
  }

  List<Polygon> _buildGeologyPolygons() {
    if (_geologyData == null) return [];
    final features = _geologyData!['features'] as List;
    final polygons = <Polygon>[];

    for (final feature in features) {
      final props = feature['properties'];
      final geom = feature['geometry'];
      final color = _geologyColor(props['CdIGLG']);

      void addPolygon(List coords) {
        final points = coords.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        polygons.add(Polygon(
          points: points,
          color: color,
          borderColor: color.withOpacity(0.8),
          borderStrokeWidth: 0.5,
        ));
      }

      if (geom['type'] == 'Polygon') {
        addPolygon(geom['coordinates'][0]);
      } else if (geom['type'] == 'MultiPolygon') {
        for (final poly in geom['coordinates']) addPolygon(poly[0]);
      }
    }
    return polygons;
  }

  List<Polygon> _buildPermisPolygons() {
    final permisFiltres = _filtreRessource == null
        ? permisDemo
        : permisDemo.where((p) => p.ressource.toLowerCase() == _filtreRessource!.toLowerCase()).toList();
    return permisFiltres
      .where((p) => _coucheSitesIllegaux || p.statut != StatutPermis.illegal)
      .where((p) => _filtreStatut == null || p.statut == _filtreStatut)
      .map((p) => Polygon(
        points: p.polygone,
        color: p.couleur.withOpacity(0.25),
        borderColor: p.couleur,
        borderStrokeWidth: p.statut == StatutPermis.illegal ? 2.5 : 1.5,
        isFilled: true,
      )).toList();
  }

  List<Marker> _buildPermisMarkers() {
    final permisFiltres = _filtreRessource == null
        ? permisDemo
        : permisDemo.where((p) => p.ressource.toLowerCase() == _filtreRessource!.toLowerCase()).toList();
    return permisFiltres
      .where((p) => _coucheSitesIllegaux || p.statut != StatutPermis.illegal)
      .where((p) => _filtreStatut == null || p.statut == _filtreStatut)
      .map((p) => Marker(
        point: p.centre,
        width: 160,
        height: 36,
        child: GestureDetector(
          onTap: () => setState(() => _permisSelectionne = p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SirexeTheme.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.couleur, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: p.couleur, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(child: Text(p.nom,
                  style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 10,
                    fontWeight: p.statut == StatutPermis.illegal ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final permisFiltresTopbar = _filtreStatut == null
        ? permisDemo
        : permisDemo.where((p) => p.statut == _filtreStatut).toList();

    return Scaffold(
      backgroundColor: SirexeTheme.background,
      appBar: GeoTopBar(
        permis: permisDemo,
        filtreActif: _filtreStatut,
        onFiltreStatut: _onFiltreStatut,
        onMenu: _onMenu,
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SidebarPanel(
                  coucheGeologie: _coucheGeologie,
                  couchePermis: _couchePermis,
                  coucheSitesIllegaux: _coucheSitesIllegaux,
                  coucheGeofences: _coucheGeofences,
                  filtreRessource: _filtreRessource,
                  permis: permisFiltresTopbar,
                  permisSelectionne: _permisSelectionne,
                  onToggleCouche: _onToggleCouche,
                  onFiltreRessource: _onFiltreRessource,
                  onSelectPermis: _onSelectPermis,
                ),
                Container(width: 0.5, color: SirexeTheme.border),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(7.5, -5.5),
                          initialZoom: 6.2,
                          minZoom: 3,
                          maxZoom: 16,
                          onTap: (_, __) => setState(() => _permisSelectionne = null),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key={key}',
                            additionalOptions: const {'key': '6tZxrsJMAnTertUR2ILg'},
                            userAgentPackageName: 'ci.geodex.app',
                          ),
                          if (_coucheGeologie && _geologyData != null)
                            PolygonLayer(polygons: _buildGeologyPolygons()),
                          if (_couchePermis) ...[
                            PolygonLayer(polygons: _buildPermisPolygons()),
                            MarkerLayer(markers: _buildPermisMarkers()),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_permisSelectionne != null)
            PermisPanel(
              permis: _permisSelectionne!,
              onClose: () => setState(() => _permisSelectionne = null),
              onTonnages: _onTonnages,
              onHistorique: _onHistorique,
              onSignaler: _onSignaler,
            ),
        ],
      ),
    );
  }
}
