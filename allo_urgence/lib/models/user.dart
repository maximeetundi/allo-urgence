class User {
  final String id;
  final String role;
  final String email;
  final String nom;
  final String prenom;
  final String? dataNaissance;
  final String? ramqNumber;
  final String? telephone;
  final String? contactUrgence;
  final String? allergies;
  final String? conditionsMedicales;
  final String? medicaments;
  final bool emailVerified;

  User({
    required this.id,
    required this.role,
    required this.email,
    required this.nom,
    required this.prenom,
    this.dataNaissance,
    this.ramqNumber,
    this.telephone,
    this.contactUrgence,
    this.allergies,
    this.conditionsMedicales,
    this.medicaments,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      role: json['role'] ?? 'patient',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dataNaissance: json['date_naissance'],
      ramqNumber: json['ramq_number'],
      telephone: json['telephone'],
      contactUrgence: json['contact_urgence'],
      allergies: json['allergies'],
      conditionsMedicales: json['conditions_medicales'],
      medicaments: json['medicaments'],
      emailVerified: json['email_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'date_naissance': dataNaissance,
      'ramq_number': ramqNumber,
      'telephone': telephone,
      'contact_urgence': contactUrgence,
      'allergies': allergies,
      'conditions_medicales': conditionsMedicales,
      'medicaments': medicaments,
      'email_verified': emailVerified,
    };
  }

  String get fullName => '$prenom $nom';
  bool get isPatient => role == 'patient';
  bool get isNurse => role == 'nurse';
  bool get isDoctor => role == 'doctor';
}
