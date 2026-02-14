import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';
import '../models/medical_note.dart';

class DoctorService {
  final String baseUrl;
  final String token;

  DoctorService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Get patients list for doctor
  Future<List<Ticket>> getPatients({
    required String hospitalId,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'hospital_id': hospitalId,
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$baseUrl/doctor/patients')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['patients'] as List)
          .map((p) => Ticket.fromJson(p))
          .toList();
    } else {
      String errorMessage = 'Erreur ${response.statusCode}';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody is Map && errorBody.containsKey('error')) {
          errorMessage = errorBody['error'];
        }
      } catch (_) {
        errorMessage += ': ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }

  /// Get patient details
  Future<Map<String, dynamic>> getPatientDetails(String ticketId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/doctor/patient/$ticketId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load patient details');
    }
  }

  /// Update patient status
  Future<Ticket> updatePatientStatus(String ticketId, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor/patient/$ticketId/status'),
      headers: _headers,
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Ticket.fromJson(data['ticket']);
    } else {
      throw Exception('Failed to update status');
    }
  }

  /// Add medical note
  Future<MedicalNote> addNote({
    required String ticketId,
    required String content,
    String? type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor/patient/$ticketId/notes'),
      headers: _headers,
      body: json.encode({
        'content': content,
        'type': type ?? 'general',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MedicalNote.fromJson(data['note']);
    } else {
      throw Exception('Failed to add note');
    }
  }

  /// Get note templates
  Future<List<NoteTemplate>> getTemplates() async {
    final response = await http.get(
      Uri.parse('$baseUrl/doctor/templates'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['templates'] as List)
          .map((t) => NoteTemplate.fromJson(t))
          .toList();
    } else {
      throw Exception('Failed to load templates');
    }
  }
}
