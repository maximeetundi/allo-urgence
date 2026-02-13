import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/nurse_service.dart';

class NurseProvider with ChangeNotifier {
  final NurseService _nurseService;

  NurseProvider(this._nurseService);

  List<Ticket> _patients = [];
  Map<String, dynamic>? _stats;
  List<Ticket> _alerts = [];
  List<String> _availableRooms = [];
  bool _isLoading = false;
  String? _error;

  List<Ticket> get patients => _patients;
  Map<String, dynamic>? get stats => _stats;
  List<Ticket> get alerts => _alerts;
  List<String> get availableRooms => _availableRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load patients list
  Future<void> loadPatients({
    required String hospitalId,
    String? status,
    int? priority,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _nurseService.getPatients(
        hospitalId: hospitalId,
        status: status,
        priority: priority,
      );

      _patients = (result['patients'] as List)
          .map((p) => Ticket.fromJson(p))
          .toList();
      _stats = result['stats'];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate triage
  Future<bool> validateTriage({
    required String ticketId,
    required int validatedPriority,
    String? assignedRoom,
    String? justification,
  }) async {
    try {
      final updatedTicket = await _nurseService.validateTriage(
        ticketId: ticketId,
        validatedPriority: validatedPriority,
        assignedRoom: assignedRoom,
        justification: justification,
      );

      // Update local list
      final index = _patients.indexWhere((p) => p.id == ticketId);
      if (index != -1) {
        _patients[index] = updatedTicket;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load available rooms
  Future<void> loadAvailableRooms(String hospitalId) async {
    try {
      final result = await _nurseService.getAvailableRooms(hospitalId);
      _availableRooms = List<String>.from(result['available']);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load critical alerts
  Future<void> loadAlerts(String hospitalId) async {
    try {
      final result = await _nurseService.getAlerts(hospitalId);
      _alerts = (result['alerts'] as List)
          .map((a) => Ticket.fromJson(a))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String ticketId) async {
    try {
      await _nurseService.acknowledgeAlert(ticketId);
      _alerts.removeWhere((a) => a.id == ticketId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
