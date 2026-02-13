import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';

class NurseService {
  final String baseUrl;
  final String token;

  NurseService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Get patients list for nurse
  Future<Map<String, dynamic>> getPatients({
    required String hospitalId,
    String? status,
    int? priority,
  }) async {
    final queryParams = <String, String>{
      'hospital_id': hospitalId,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority.toString(),
    };

    final uri = Uri.parse('$baseUrl/nurse/patients')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load patients');
    }
  }

  /// Validate triage
  Future<Ticket> validateTriage({
    required String ticketId,
    required int validatedPriority,
    String? assignedRoom,
    String? justification,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nurse/triage/validate'),
      headers: _headers,
      body: json.encode({
        'ticket_id': ticketId,
        'validated_priority': validatedPriority,
        'assigned_room': assignedRoom,
        'justification': justification,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Ticket.fromJson(data['ticket']);
    } else {
      throw Exception('Failed to validate triage');
    }
  }

  /// Get available rooms
  Future<Map<String, dynamic>> getAvailableRooms(String hospitalId) async {
    final uri = Uri.parse('$baseUrl/nurse/rooms/available')
        .replace(queryParameters: {'hospital_id': hospitalId});

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  /// Get critical alerts
  Future<Map<String, dynamic>> getAlerts(String hospitalId) async {
    final uri = Uri.parse('$baseUrl/nurse/alerts')
        .replace(queryParameters: {'hospital_id': hospitalId});

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load alerts');
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String ticketId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nurse/alert/acknowledge'),
      headers: _headers,
      body: json.encode({'ticket_id': ticketId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to acknowledge alert');
    }
  }
}
