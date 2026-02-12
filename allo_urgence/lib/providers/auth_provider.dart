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
