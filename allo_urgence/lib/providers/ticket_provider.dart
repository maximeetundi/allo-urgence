import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/triage_question.dart';
import '../services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  Ticket? _activeTicket;
  List<Ticket> _history = [];
  List<TriageCategory> _categories = [];
  List<TriageQuestion> _questions = [];
  bool _loading = false;
  String? _error;

  Ticket? get activeTicket => _activeTicket;
  List<Ticket> get history => _history;
  List<TriageCategory> get categories => _categories;
  List<TriageQuestion> get questions => _questions;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadTriageCategories() async {
    _error = null;
    try {
      final data = await apiService.get('/tickets/triage-categories');
      _categories = (data['categories'] as List)
          .map((c) => TriageCategory.fromJson(c))
          .toList();
      _questions = (data['followUpQuestions'] as List)
          .map((q) => TriageQuestion.fromJson(q))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadActiveTicket() async {
    _error = null;
    try {
      final data = await apiService.get('/tickets/patient/active');
      if (data['ticket'] != null) {
        _activeTicket = Ticket.fromJson(data['ticket']);
      } else {
        _activeTicket = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createTicket({
    required String hospitalId,
    required String categoryId,
    Map<String, dynamic>? triageAnswers,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.post('/tickets', {
        'hospital_id': hospitalId,
        'category_id': categoryId,
        'triage_answers': triageAnswers ?? {},
      });
      _activeTicket = Ticket.fromJson(data['ticket']);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshTicket() async {
    if (_activeTicket == null) return;
    _error = null;
    try {
      final data = await apiService.get('/tickets/${_activeTicket!.id}');
      _activeTicket = Ticket.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> checkIn() async {
    if (_activeTicket == null) return;
    try {
      await apiService.patch('/tickets/${_activeTicket!.id}/checkin');
      await refreshTicket();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _error = null;
    try {
      final data = await apiService.get('/tickets/patient/history');
      _history = (data['tickets'] as List)
          .map((t) => Ticket.fromJson(t))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void updateFromSocket(Map<String, dynamic> data) {
    if (_activeTicket != null) {
      // Merge socket data into active ticket
      _activeTicket = Ticket.fromJson({
        ...{
          'id': _activeTicket!.id,
          'patient_id': _activeTicket!.patientId,
          'hospital_id': _activeTicket!.hospitalId,
          'priority_level': _activeTicket!.priorityLevel,
          'validated_priority': _activeTicket!.validatedPriority,
          'status': _activeTicket!.status,
          'queue_position': _activeTicket!.queuePosition,
          'estimated_wait_minutes': _activeTicket!.estimatedWaitMinutes,
          'qr_code': _activeTicket!.qrCode,
          'assigned_room': _activeTicket!.assignedRoom,
          'shared_token': _activeTicket!.sharedToken,
          'created_at': _activeTicket!.createdAt,
        },
        ...data,
      });
      notifyListeners();
    }
  }
}
