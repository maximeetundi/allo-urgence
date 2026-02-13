class MedicalNote {
  final String id;
  final String ticketId;
  final String doctorId;
  final String content;
  final String noteType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalNote({
    required this.id,
    required this.ticketId,
    required this.doctorId,
    required this.content,
    required this.noteType,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalNote.fromJson(Map<String, dynamic> json) {
    return MedicalNote(
      id: json['id'],
      ticketId: json['ticket_id'],
      doctorId: json['doctor_id'],
      content: json['content'],
      noteType: json['note_type'] ?? 'general',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'doctor_id': doctorId,
      'content': content,
      'note_type': noteType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class NoteTemplate {
  final String id;
  final String name;
  final String content;

  NoteTemplate({
    required this.id,
    required this.name,
    required this.content,
  });

  factory NoteTemplate.fromJson(Map<String, dynamic> json) {
    return NoteTemplate(
      id: json['id'],
      name: json['name'],
      content: json['content'],
    );
  }
}
