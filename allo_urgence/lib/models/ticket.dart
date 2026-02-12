class Ticket {
  final String id;
  final String patientId;
  final String hospitalId;
  final int priorityLevel;
  final int? validatedPriority;
  final String status;
  final int? queuePosition;
  final int? estimatedWaitMinutes;
  final String? qrCode;
  final String? assignedRoom;
  final String? sharedToken;
  final String? preTriageCategory;
  final String? patientNom;
  final String? patientPrenom;
  final String? patientTelephone;
  final String? allergies;
  final String? conditionsMedicales;
  final String? dateNaissance;
  final String createdAt;

  Ticket({
    required this.id,
    required this.patientId,
    required this.hospitalId,
    required this.priorityLevel,
    this.validatedPriority,
    required this.status,
    this.queuePosition,
    this.estimatedWaitMinutes,
    this.qrCode,
    this.assignedRoom,
    this.sharedToken,
    this.preTriageCategory,
    this.patientNom,
    this.patientPrenom,
    this.patientTelephone,
    this.allergies,
    this.conditionsMedicales,
    this.dateNaissance,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      hospitalId: json['hospital_id'] ?? '',
      priorityLevel: json['priority_level'] ?? 5,
      validatedPriority: json['validated_priority'],
      status: json['status'] ?? 'waiting',
      queuePosition: json['queue_position'],
      estimatedWaitMinutes: json['estimated_wait_minutes'],
      qrCode: json['qr_code'],
      assignedRoom: json['assigned_room'],
      sharedToken: json['shared_token'],
      preTriageCategory: json['pre_triage_category'],
      patientNom: json['patient_nom'],
      patientPrenom: json['patient_prenom'],
      patientTelephone: json['patient_telephone'],
      allergies: json['allergies'],
      conditionsMedicales: json['conditions_medicales'],
      dateNaissance: json['date_naissance'],
      createdAt: json['created_at'] ?? '',
    );
  }

  int get effectivePriority => validatedPriority ?? priorityLevel;
  String get patientFullName => '${patientPrenom ?? ''} ${patientNom ?? ''}'.trim();

  String get statusLabel {
    switch (status) {
      case 'waiting': return 'En attente';
      case 'checked_in': return 'Arrivé';
      case 'triage': return 'Trié';
      case 'in_progress': return 'En cours';
      case 'treated': return 'Traité';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  }
}
