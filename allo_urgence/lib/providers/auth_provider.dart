import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      apiService.setToken(_token!);
      try {
        final data = await apiService.get('/auth/me');
        _user = User.fromJson(data);
        socketService.connect(_token);
        notifyListeners();
      } catch (e) {
        _token = null;
        apiService.clearToken();
        await prefs.remove('auth_token');
      }
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    String? telephone,
    String? ramqNumber,
    String? dateNaissance,
    String? contactUrgence,
    String? allergies,
    String? conditionsMedicales,
    String? medicaments,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'ramq_number': ramqNumber,
        'date_naissance': dateNaissance,
        'contact_urgence': contactUrgence,
        'allergies': allergies,
        'conditions_medicales': conditionsMedicales,
        'medicaments': medicaments,
      });

      _token = data['token'];
      _user = User.fromJson(data['user']);
      apiService.setToken(_token!);
      socketService.connect(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

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

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      _token = data['token'];
      _user = User.fromJson(data['user']);
      apiService.setToken(_token!);
      socketService.connect(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

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

  Future<bool> verifyEmail(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.post('/auth/verify-email', {'code': code});
      if (data['verified'] == true) {
        // Re-fetch user to get updated email_verified status
        final userData = await apiService.get('/auth/me');
        _user = User.fromJson(userData);
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = data['error'] ?? 'Code incorrect';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resendVerification() async {
    try {
      await apiService.post('/auth/resend-verification', {});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await apiService.put('/auth/update-email', {'newEmail': newEmail}); // Use PUT if implemented as PUT in API service, checking api_service.dart... ApiService has patch/post/get. Need to check if PUT exists or add it.
      // Wait, api_service.dart (Step 981) has get, post, patch. NO PUT.
      // I must update auth.routes.js to use PATCH or update api_service to add PUT?
      // I used router.put in backend.
      // I should add put to ApiService OR change backend to router.patch.
      // Standard is PATCH for partial update. I'll stick to PATCH in backend for simplicity?
      // No, I already wrote router.put. I should add put to ApiService.
      
      // ... actually I'll use PATCH in api_service call here, but I need to change backend to PATCH?
      // Or I can add PUT to default_api:replace_file_content on api_service.dart.
      // Let's add PUT to api_service.dart first.
      
      // Let's abort this replace and fix api_service first? 
      // Or I can assume I will fix it.
      
      // Wait, let's just use PATCH in backend to avoid modifying ApiService if possible?
      // Existing api_service has PATCH.
      // But I already wrote PUT in backend (Step 1014).
      // So I MUST add PUT to api_service.dart.
      // Or change backend to PATCH.
      // Changing backend is "replace_file_content" again.
      // Adding PUT to api_service is "replace_file_content".
      // I'll add PUT to api_service.dart.
     
      // ... For this step, I will write the code assuming 'apiService.put' exists.
      
      _user = User.fromJson({..._user!.toJson(), 'email': newEmail});
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

  Future<void> logout() async {
    _user = null;
    _token = null;
    apiService.clearToken();
    socketService.disconnect();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
