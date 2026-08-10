import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? authToken;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse(ApiConfig.baseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final pathSegments = <String>[...base.pathSegments.where((p) => p.isNotEmpty), normalizedPath];
    return base.replace(
      path: pathSegments.join('/'),
      queryParameters: queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }

  Map<String, String> _buildHeaders([Map<String, String>? headers]) {
    final result = <String, String>{
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
      ...?headers,
    };
    return result;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client
        .get(uri, headers: _buildHeaders(headers))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    return _decodeResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client
        .post(
          uri,
          headers: _buildHeaders({
            'Content-Type': 'application/json',
            ...?headers,
          }),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    return _decodeResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client
        .put(
          uri,
          headers: _buildHeaders({
            'Content-Type': 'application/json',
            ...?headers,
          }),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    return _decodeResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client
        .delete(
          uri,
          headers: _buildHeaders({
            'Content-Type': 'application/json',
            ...?headers,
          }),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    String message = 'Erreur inconnue';
    dynamic details;
    try {
      final dynamic decoded = body.isNotEmpty ? jsonDecode(body) : null;
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString() ?? message;
        details = decoded;
      } else if (decoded is String) {
        message = decoded;
      }
    } catch (_) {
      message = body;
    }

    throw ApiException(
      message: message.isNotEmpty ? message : 'Erreur HTTP $statusCode',
      statusCode: statusCode,
      details: details,
    );
  }
}
