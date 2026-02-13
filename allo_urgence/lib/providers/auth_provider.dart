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
        'client': 'mobile',
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

  Future<bool> updateProfile({
    String? nom,
    String? prenom,
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
      final data = await apiService.put('/auth/me', {
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (telephone != null) 'telephone': telephone,
        if (ramqNumber != null) 'ramq_number': ramqNumber,
        if (dateNaissance != null) 'date_naissance': dateNaissance,
        if (contactUrgence != null) 'contact_urgence': contactUrgence,
        if (allergies != null) 'allergies': allergies,
        if (conditionsMedicales != null) 'conditions_medicales': conditionsMedicales,
        if (medicaments != null) 'medicaments': medicaments,
      });

      // Update local user object
      // data['user'] contains the updated user object from backend
      if (data['user'] != null) {
         _user = User.fromJson(data['user']);
      }
      
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

  Future<bool> updateEmail(String newEmail) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await apiService.put('/auth/update-email', {'newEmail': newEmail});
      
      // Update local user object manually as email update might trigger verification process
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
