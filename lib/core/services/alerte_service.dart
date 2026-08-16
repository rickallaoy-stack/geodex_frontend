import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/alerte_model.dart';

class AlerteService {
  AlerteService({
    String baseUrl = 'http://localhost:3000',
    Duration interval = const Duration(seconds: 15),
  })  : _baseUrl = baseUrl,
        _interval = interval;

  final String _baseUrl;
  final Duration _interval;

  StreamController<List<AlerteModel>>? _controller;
  Timer? _timer;

  Future<List<AlerteModel>> fetchAlertes() async {
    final uri = Uri.parse('$_baseUrl/api/pesees/alertes');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur ${response.statusCode} lors de la récupération des alertes');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception('Backend error : ${body['error']}');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => AlerteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<AlerteModel>> watch() {
    _controller?.close();
    _controller = StreamController<List<AlerteModel>>.broadcast(
      onCancel: _stopPolling,
    );

    _poll();
    _timer = Timer.periodic(_interval, (_) => _poll());

    return _controller!.stream;
  }

  void dispose() {
    _stopPolling();
    _controller?.close();
    _controller = null;
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_controller == null || _controller!.isClosed) return;
    try {
      final alertes = await fetchAlertes();
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(alertes);
      }
    } catch (e) {
      if (!(_controller?.isClosed ?? true)) {
        _controller!.addError(e);
      }
    }
  }
}
