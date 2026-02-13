import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/triage.dart';

class TriageService {
  final String baseUrl;

  TriageService({required this.baseUrl});

  /// Récupérer les questions de pré-triage
  Future<List<TriageQuestion>> getQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/triage/questions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questions = (data['questions'] as List)
            .map((q) => TriageQuestion.fromJson(q))
            .toList();
        return questions;
      } else {
        throw Exception('Erreur lors de la récupération des questions');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Calculer la priorité basée sur les réponses
  Future<TriageResult> calculatePriority(
      Map<String, dynamic> answers) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/triage/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(answers),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TriageResult.fromJson(data);
      } else {
        throw Exception('Erreur lors du calcul de la priorité');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}
