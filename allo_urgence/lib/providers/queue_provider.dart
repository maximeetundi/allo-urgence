import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class QueueProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  Map<String, dynamic> _summary = {};
  bool _loading = false;

  List<Ticket> get tickets => _tickets;
  Map<String, dynamic> get summary => _summary;
  bool get loading => _loading;

  Future<void> loadQueue(String hospitalId) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await apiService.get('/tickets/queue/$hospitalId');
      _tickets = (data['tickets'] as List)
          .map((t) => Ticket.fromJson(t))
          .toList();
      _summary = data['summary'] ?? {};
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> triageTicket(String ticketId, int priority, String? notes) async {
    try {
      await apiService.patch('/tickets/$ticketId/triage', {
        'validated_priority': priority,
        'notes': notes,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignRoom(String ticketId, String room) async {
    try {
      await apiService.patch('/tickets/$ticketId/assign-room', {
        'room': room,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> treatPatient(String ticketId, {String? notes, String? diagnosis}) async {
    try {
      await apiService.patch('/tickets/$ticketId/treat', {
        'notes': notes,
        'diagnosis': diagnosis,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addDoctorNote(String ticketId, String notes, String? diagnosis) async {
    try {
      await apiService.post('/tickets/$ticketId/doctor-note', {
        'notes': notes,
        'diagnosis': diagnosis,
      });
    } catch (e) {
      rethrow;
    }
  }

  void updateFromSocket(dynamic data) {
    _summary = data is Map<String, dynamic> ? data : {};
    notifyListeners();
  }
}
