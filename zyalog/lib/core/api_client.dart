// lib/core/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'storage.dart';

/// Custom exception untuk error API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// HTTP client terpusat.
/// - Auto-attach Bearer token
/// - Auto-refresh jika server kembalikan 401
/// - Melempar [ApiException] jika refresh gagal
class ApiClient {
  ApiClient._();

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AppStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Generic request + auto-refresh ──────────────────────────────────────

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final uri = Uri.parse('$kApiBase$path');
    final headers = await _authHeaders();

    http.Response res;

    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null);
        break;
      case 'PUT':
        res = await http.put(uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
        break;
      default:
        throw ApiException('Method tidak dikenal: $method');
    }

    // Auto-refresh jika 401
    if (res.statusCode == 401 && retry) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _request(method, path, body: body, retry: false);
      }
      throw const ApiException('Sesi login kedaluwarsa, silakan login ulang.',
          statusCode: 401);
    }

    return res;
  }

  static Future<bool> _tryRefresh() async {
    final refreshToken = await AppStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('$kApiBase/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await AppStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Public helpers ───────────────────────────────────────────────────────

  static Future<dynamic> get(String path) async {
    final res = await _request('GET', path);
    _assertOk(res);
    return jsonDecode(res.body);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _request('POST', path, body: body);
    _assertOk(res);
    return jsonDecode(res.body);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await _request('PUT', path, body: body);
    _assertOk(res);
    return jsonDecode(res.body);
  }

  static Future<void> delete(String path) async {
    final res = await _request('DELETE', path);
    _assertOk(res);
  }

  /// POST tanpa auth (untuk login/register)
  static Future<dynamic> postPublic(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$kApiBase$path');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _assertOk(res);
    return jsonDecode(res.body);
  }

  static void _assertOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String message = 'Terjadi kesalahan';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      message = (data['message'] as String?) ?? message;
    } catch (_) {}
    throw ApiException(message, statusCode: res.statusCode);
  }
}
