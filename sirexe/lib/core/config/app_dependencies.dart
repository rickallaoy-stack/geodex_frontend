import '../network/api_client.dart';
import '../../services/geological_service.dart';

class AppDependencies {
  AppDependencies._();

  static late final ApiClient apiClient;
  static late final GeologicalService geologicalService;

  static void init() {
    apiClient = ApiClient();
    geologicalService = GeologicalService(apiClient);
  }
}
