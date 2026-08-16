import '../../../core/network/api_client.dart';

class VerificationService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> verifierChaine() async {
    try {
      final data = await _client.get('/api/pesees/verify-chain');
      return Map<String, dynamic>.from(data);
    } catch (e) {
      rethrow;
    }
  }
}
