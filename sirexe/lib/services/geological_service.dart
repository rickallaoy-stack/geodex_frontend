import '../core/network/api_client.dart';
import '../models/geojson.dart';

class GeologicalService {
  GeologicalService(this._apiClient);

  final ApiClient _apiClient;

  Future<GeoJsonFeatureCollection> fetchGeologicalZones() async {
    final response = await _apiClient.get('/api/geology');
    if (response is Map<String, dynamic>) {
      return GeoJsonFeatureCollection.fromJson(response);
    }
    throw Exception('Réponse inattendue de l’API géologie');
  }

  Future<GeoJsonFeatureCollection> search({
    required double latitude,
    required double longitude,
    required int radius,
    String? zone,
    String? resourceType,
    String? terrainType,
  }) async {
    final body = {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      if (zone != null) 'zone': zone,
      if (resourceType != null) 'resourceType': resourceType,
      if (terrainType != null) 'terrainType': terrainType,
    };

    final response = await _apiClient.post(
      '/api/geology/search',
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return GeoJsonFeatureCollection.fromJson(response);
    }
    throw Exception('Réponse inattendue du service de recherche géologique');
  }
}
