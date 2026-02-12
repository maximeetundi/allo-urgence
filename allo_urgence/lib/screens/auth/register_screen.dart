import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../patient/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _nomC = TextEditingController();
  final _prenomC = TextEditingController();
  final _telephoneC = TextEditingController();
  final _ramqC = TextEditingController();
  final _dobC = TextEditingController();
  final _contactUrgenceC = TextEditingController();
  final _allergiesC = TextEditingController();
  final _conditionsC = TextEditingController();
  final _medicamentsC = TextEditingController();
  int _step = 0; // 0 = required, 1 = optional

  @override
  void dispose() {
    _emailC.dispose(); _passwordC.dispose(); _nomC.dispose(); _prenomC.dispose();
    _telephoneC.dispose(); _ramqC.dispose(); _dobC.dispose();
    _contactUrgenceC.dispose(); _allergiesC.dispose(); _conditionsC.dispose();
    _medicamentsC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailC.text.trim(),
      password: _passwordC.text,
      nom: _nomC.text.trim(),
      prenom: _prenomC.text.trim(),
      telephone: _telephoneC.text.trim().isNotEmpty ? _telephoneC.text.trim() : null,
      ramqNumber: _ramqC.text.trim().isNotEmpty ? _ramqC.text.trim() : null,
      dateNaissance: _dobC.text.trim().isNotEmpty ? _dobC.text.trim() : null,
      contactUrgence: _contactUrgenceC.text.trim().isNotEmpty ? _contactUrgenceC.text.trim() : null,
      allergies: _allergiesC.text.trim().isNotEmpty ? _allergiesC.text.trim() : null,
      conditionsMedicales: _conditionsC.text.trim().isNotEmpty ? _conditionsC.text.trim() : null,
      medicaments: _medicamentsC.text.trim().isNotEmpty ? _medicamentsC.text.trim() : null,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Erreur'), backgroundColor: AlloUrgenceTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                Row(
                  children: [
                    Expanded(child: _stepDot('Obligatoire', _step >= 0)),
                    Expanded(child: _stepDot('Optionnel', _step >= 1)),
                  ],
                ),
                const SizedBox(height: 24),

                if (_step == 0) ...[
                  _buildField(_prenomC, 'Prénom *', Icons.person, validator: _required),
                  _buildField(_nomC, 'Nom *', Icons.person_outline, validator: _required),
                  _buildField(_emailC, 'Courriel *', Icons.email, type: TextInputType.emailAddress, validator: _required),
                  _buildField(_passwordC, 'Mot de passe *', Icons.lock, obscure: true, validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 caractères'),
                  _buildField(_telephoneC, 'Téléphone', Icons.phone, type: TextInputType.phone),
                  _buildField(_ramqC, 'N° carte RAMQ', Icons.credit_card),
                  _buildField(_dobC, 'Date de naissance (AAAA-MM-JJ)', Icons.calendar_today),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () { if (_formKey.currentState!.validate()) setState(() => _step = 1); },
                    child: const Text('Suivant →'),
                  ),
                ],

                if (_step == 1) ...[
                  const Text('Informations médicales (optionnel)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Ces informations aideront l\'équipe soignante.', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  _buildField(_contactUrgenceC, 'Contact d\'urgence', Icons.phone_callback),
                  _buildField(_allergiesC, 'Allergies connues', Icons.warning_amber, maxLines: 2),
                  _buildField(_conditionsC, 'Conditions médicales', Icons.medical_information, maxLines: 2),
                  _buildField(_medicamentsC, 'Médicaments actuels', Icons.medication, maxLines: 2),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step = 0),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                          child: const Text('← Retour'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: auth.loading ? null : _register,
                          child: auth.loading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Créer mon compte'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {
    TextInputType type = TextInputType.text, bool obscure = false,
    String? Function(String?)? validator, int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 24)),
        validator: validator,
      ),
    );
  }

  Widget _stepDot(String label, bool active) {
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: active ? AlloUrgenceTheme.primaryBlue : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: active ? AlloUrgenceTheme.primaryBlue : Colors.grey)),
      ],
    );
  }

  String? _required(String? v) => v == null || v.isEmpty ? 'Champ obligatoire' : null;
}
