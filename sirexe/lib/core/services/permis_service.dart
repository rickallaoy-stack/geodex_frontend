import '../network/api_client.dart';
import '../../models/permis_minier.dart';

class PermisService {
  static Future<List<PermisMinier>> fetchPermis() async {
    try {
      final client = ApiClient();
      final data = await client.get('/api/pesees/concessions');
      final features = data['features'] as List;
      return features
        .map((f) => PermisMinier.fromGeoJson(f as Map<String, dynamic>))
        .toList();
    } catch (e) {
      print('Backend indisponible, mode démo: $e');
      return permisDemo;
    }
  }
}
