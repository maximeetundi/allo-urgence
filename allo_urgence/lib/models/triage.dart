class TriageQuestion {
  final String id;
  final String question;
  final String type;
  final bool required;
  final List<TriageOption>? options;
  final int? min;
  final int? max;

  TriageQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.required,
    this.options,
    this.min,
    this.max,
  });

  factory TriageQuestion.fromJson(Map<String, dynamic> json) {
    return TriageQuestion(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      required: json['required'],
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => TriageOption.fromJson(o))
              .toList()
          : null,
      min: json['min'],
      max: json['max'],
    );
  }
}

class TriageOption {
  final String id;
  final String label;
  final String? icon;
  final String? color;
  final int? priorityWeight;

  TriageOption({
    required this.id,
    required this.label,
    this.icon,
    this.color,
    this.priorityWeight,
  });

  factory TriageOption.fromJson(Map<String, dynamic> json) {
    return TriageOption(
      id: json['id'],
      label: json['label'],
      icon: json['icon'],
      color: json['color'],
      priorityWeight: json['priority_weight'],
    );
  }
}

class TriageResult {
  final int priority;
  final String label;
  final String color;
  final int confidence;
  final String disclaimer;
  final TriageRecommendation recommendations;

  TriageResult({
    required this.priority,
    required this.label,
    required this.color,
    required this.confidence,
    required this.disclaimer,
    required this.recommendations,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      priority: json['priority'],
      label: json['label'],
      color: json['color'],
      confidence: json['confidence'],
      disclaimer: json['disclaimer'],
      recommendations: TriageRecommendation.fromJson(json['recommendations']),
    );
  }
}

class TriageRecommendation {
  final String message;
  final String urgency;
  final String icon;

  TriageRecommendation({
    required this.message,
    required this.urgency,
    required this.icon,
  });

  factory TriageRecommendation.fromJson(Map<String, dynamic> json) {
    return TriageRecommendation(
      message: json['message'],
      urgency: json['urgency'],
      icon: json['icon'],
    );
  }
}
