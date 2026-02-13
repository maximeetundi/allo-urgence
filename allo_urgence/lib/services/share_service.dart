import 'dart:convert';
import 'package:http/http.dart' as http;

class ShareService {
  final String baseUrl;
  final String token;

  ShareService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Create shareable link for ticket
  Future<Map<String, dynamic>> createShareLink(String ticketId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/share/create'),
      headers: _headers,
      body: json.encode({'ticket_id': ticketId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create share link');
    }
  }

  /// Get ticket status via share token (public, no auth)
  static Future<Map<String, dynamic>> getSharedTicket(
    String baseUrl,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/share/$token'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get shared ticket');
    }
  }

  /// Revoke share link
  Future<void> revokeShareLink(String ticketId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/share/revoke'),
      headers: _headers,
      body: json.encode({'ticket_id': ticketId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke share link');
    }
  }
}
