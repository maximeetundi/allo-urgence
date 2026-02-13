import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/medical_note.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService;

  DoctorProvider(this._doctorService);

  List<Ticket> _patients = [];
  Ticket? _selectedPatient;
  Map<String, dynamic>? _patientDetails;
  List<NoteTemplate> _templates = [];
  bool _isLoading = false;
  String? _error;

  List<Ticket> get patients => _patients;
  Ticket? get selectedPatient => _selectedPatient;
  Map<String, dynamic>? get patientDetails => _patientDetails;
  List<NoteTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load patients list
  Future<void> loadPatients({
    required String hospitalId,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _doctorService.getPatients(
        hospitalId: hospitalId,
        status: status,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load patient details
  Future<void> loadPatientDetails(String ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patientDetails = await _doctorService.getPatientDetails(ticketId);
      _selectedPatient = Ticket.fromJson(_patientDetails!['patient']);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update patient status
  Future<bool> updatePatientStatus(String ticketId, String status) async {
    try {
      final updatedTicket = await _doctorService.updatePatientStatus(
        ticketId,
        status,
      );

      // Update local list
      final index = _patients.indexWhere((p) => p.id == ticketId);
      if (index != -1) {
        _patients[index] = updatedTicket;
      }

      // Update selected patient
      if (_selectedPatient?.id == ticketId) {
        _selectedPatient = updatedTicket;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add medical note
  Future<bool> addNote({
    required String ticketId,
    required String content,
    String? type,
  }) async {
    try {
      await _doctorService.addNote(
        ticketId: ticketId,
        content: content,
        type: type,
      );

      // Reload patient details to get updated notes
      await loadPatientDetails(ticketId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load note templates
  Future<void> loadTemplates() async {
    try {
      _templates = await _doctorService.getTemplates();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectPatient(Ticket patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
