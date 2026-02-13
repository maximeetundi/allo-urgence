import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }
      throw ApiException(body['error'] ?? 'Erreur serveur (${response.statusCode})', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Réponse invalide du serveur', response.statusCode);
    }
  }
  
  ApiException _handleError(dynamic e) {
    if (e is ApiException) return e;
    if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
      return ApiException('Impossible de joindre le serveur. Vérifiez votre connexion.', 0);
    }
    if (e.toString().contains('TimeoutException')) {
      return ApiException('Le serveur met trop de temps à répondre.', 0);
    }
    return ApiException('Erreur inattendue: ${e.toString()}', 0);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

// Global singleton
final apiService = ApiService();
