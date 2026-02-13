import 'package:flutter/material.dart';
import '../models/triage.dart';
import '../services/triage_service.dart';

class TriageProvider with ChangeNotifier {
  final TriageService _triageService;

  TriageProvider(this._triageService);

  List<TriageQuestion> _questions = [];
  Map<String, dynamic> _answers = {};
  TriageResult? _result;
  bool _isLoading = false;
  String? _error;
  int _currentQuestionIndex = 0;

  // Getters
  List<TriageQuestion> get questions => _questions;
  Map<String, dynamic> get answers => _answers;
  TriageResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;
  double get progress =>
      _questions.isEmpty ? 0 : (_currentQuestionIndex + 1) / _questions.length;

  /// Charger les questions
  Future<void> loadQuestions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _questions = await _triageService.getQuestions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Répondre à une question
  void answerQuestion(String questionId, dynamic answer) {
    _answers[questionId] = answer;
    notifyListeners();
  }

  /// Question suivante
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Question précédente
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Aller à une question spécifique
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Calculer la priorité
  Future<void> calculatePriority() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _triageService.calculatePriority(_answers);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialiser le triage
  void reset() {
    _answers = {};
    _result = null;
    _currentQuestionIndex = 0;
    _error = null;
    notifyListeners();
  }

  /// Vérifier si une question a une réponse
  bool hasAnswer(String questionId) {
    return _answers.containsKey(questionId);
  }

  /// Obtenir la réponse d'une question
  dynamic getAnswer(String questionId) {
    return _answers[questionId];
  }

  /// Vérifier si on peut passer à la question suivante
  bool canProceed() {
    if (_questions.isEmpty) return false;
    final currentQuestion = _questions[_currentQuestionIndex];
    if (!currentQuestion.required) return true;
    return hasAnswer(currentQuestion.id);
  }
}
