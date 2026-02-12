class TriageCategory {
  final String id;
  final String label;
  final String icon;
  final String color;
  final int priority;
  final String description;

  TriageCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.priority,
    required this.description,
  });

  factory TriageCategory.fromJson(Map<String, dynamic> json) {
    return TriageCategory(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      priority: json['priority'] ?? 5,
      description: json['description'] ?? '',
    );
  }
}

class TriageQuestion {
  final String id;
  final String question;
  final String type;
  final int? min;
  final int? max;
  final List<TriageOption>? options;
  final bool? affectsPriority;

  TriageQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.min,
    this.max,
    this.options,
    this.affectsPriority,
  });

  factory TriageQuestion.fromJson(Map<String, dynamic> json) {
    return TriageQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      type: json['type'] ?? 'boolean',
      min: json['min'],
      max: json['max'],
      options: json['options'] != null
          ? (json['options'] as List).map((o) => TriageOption.fromJson(o)).toList()
          : null,
      affectsPriority: json['affects_priority'],
    );
  }
}

class TriageOption {
  final String label;
  final String value;

  TriageOption({required this.label, required this.value});

  factory TriageOption.fromJson(Map<String, dynamic> json) {
    return TriageOption(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }
}
