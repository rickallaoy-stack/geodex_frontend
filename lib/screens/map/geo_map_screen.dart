import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/app_dependencies.dart';
import '../../core/network/api_exception.dart';
import '../../models/geojson.dart';

enum GeoMapStatus { loading, success, empty, error }

class GeoMapScreen extends StatefulWidget {
  const GeoMapScreen({super.key});

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  GeoMapStatus _status = GeoMapStatus.loading;
  String? _errorMessage;
  GeoJsonFeatureCollection? _collection;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadGeology();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadGeology() async {
    setState(() {
      _status = GeoMapStatus.loading;
      _errorMessage = null;
    });

    try {
      final result = await AppDependencies.geologicalService.fetchGeologicalZones();
      setState(() {
        _collection = result;
        _status = result.features.isEmpty ? GeoMapStatus.empty : GeoMapStatus.success;
      });
    } on ApiException catch (exception) {
      setState(() {
        _status = GeoMapStatus.error;
        _errorMessage = exception.message;
      });
    } catch (exception) {
      setState(() {
        _status = GeoMapStatus.error;
        _errorMessage = exception.toString();
      });
    }
  }

  List<Polygon> _buildPolygons() {
    if (_collection == null) return [];

    return _collection!.features
        .where((feature) => feature.geometry.isPolygon || feature.geometry.isMultiPolygon)
        .map((feature) {
          final points = feature.geometry.toLatLngList();
          return Polygon(
            points: points,
            color: Colors.blue.withOpacity(0.25),
            borderColor: Colors.blueAccent,
            borderStrokeWidth: 1.2,
          );
        })
        .toList();
  }

  List<Marker> _buildMarkers() {
    if (_collection == null) return [];

    return _collection!.features
        .where((feature) => feature.geometry.isPoint)
        .map((feature) {
          final point = feature.geometry.toLatLngList().first;
          return Marker(
            point: point,
            width: 36,
            height: 36,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 28,
            ),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte GeoDex — couche géologique')),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _loadGeology,
              icon: const Icon(Icons.refresh),
              label: const Text('Recharger la couche géologique'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case GeoMapStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case GeoMapStatus.empty:
        return const Center(child: Text('Aucune entité géologique trouvée.'));
      case GeoMapStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Erreur inconnue',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadGeology,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        );
      case GeoMapStatus.success:
        final map = FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(7.8, -5.3),
            initialZoom: 6,
            minZoom: 3,
            maxZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key={key}',
              additionalOptions: const {'key': '6tZxrsJMAnTertUR2ILg'},
              userAgentPackageName: 'ci.geodex.app',
            ),
            PolygonLayer(polygons: _buildPolygons()),
            MarkerLayer(markers: _buildMarkers()),
          ],
        );
        return Stack(
          children: [
            map,
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onTap: () {
                      final current = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, current + 1);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onTap: () {
                      final current = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, current - 1);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}
