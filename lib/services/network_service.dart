import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api/api_config.dart';

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class NetworkService {
  NetworkService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> isBackendAvailable() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      _debugLog('Backend indisponivel: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> headers = const {},
    Duration? timeout,
  }) async {
    final response = await _client
        .get(ApiConfig.endpoint(path), headers: _headers(headers))
        .timeout(timeout ?? ApiConfig.timeout);

    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload, {
    Map<String, String> headers = const {},
    Duration? timeout,
  }) async {
    final response = await _client
        .post(
          ApiConfig.endpoint(path),
          headers: _headers(headers),
          body: jsonEncode(payload),
        )
        .timeout(timeout ?? ApiConfig.timeout);

    return _decode(response);
  }

  Map<String, String> _headers(Map<String, String> headers) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...headers,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NetworkException('Status ${response.statusCode}.');
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const NetworkException('Resposta nao e um objeto JSON.');
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[NetworkService] $message');
    }
  }
}
