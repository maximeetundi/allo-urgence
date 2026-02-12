class AppConstants {
  static const String apiBaseUrl = 'https://api.allo-urgence.tech-afm.com/api'; // Production
  static const String wsBaseUrl = 'https://api.allo-urgence.tech-afm.com';
  
  // For local development, use:
  // static const String apiBaseUrl = 'http://10.0.2.2:3355/api'; // Android emulator
  // static const String wsBaseUrl = 'http://10.0.2.2:3355';
  
  // For iOS simulator, use:
  // static const String apiBaseUrl = 'http://localhost:3355/api';
  // static const String wsBaseUrl = 'http://localhost:3355';

  static const String appName = 'Allo Urgence';
  static const String version = '1.0.0';
  
  static const int maxTriageQuestions = 7;
  static const int targetTriageSeconds = 30;
}
