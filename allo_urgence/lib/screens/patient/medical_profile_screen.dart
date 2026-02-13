import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final _contactUrgenceC = TextEditingController();
  final _allergiesC = TextEditingController();
  final _conditionsC = TextEditingController();
  final _medicamentsC = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _contactUrgenceC.text = user.contactUrgence ?? '';
      _allergiesC.text = user.allergies ?? '';
      _conditionsC.text = user.conditionsMedicales ?? '';
      _medicamentsC.text = user.medicaments ?? '';
    }
  }

  @override
  void dispose() {
    _contactUrgenceC.dispose();
    _allergiesC.dispose();
    _conditionsC.dispose();
    _medicamentsC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final success = await context.read<AuthProvider>().updateProfile(
      prenom: user.prenom,
      nom: user.nom,
      telephone: user.telephone,
      contactUrgence: _contactUrgenceC.text,
      allergies: _allergiesC.text,
      conditionsMedicales: _conditionsC.text,
      medicaments: _medicamentsC.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations médicales mises à jour'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AlloUrgenceTheme.darkBackground : AlloUrgenceTheme.background,
      appBar: AppBar(
        title: const Text('Informations Médicales'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title: "Important",
              message: "Ces informations sont cruciales pour les services d'urgence. Veuillez les garder à jour.",
              icon: LineIcons.medicalFile,
              color: AlloUrgenceTheme.primaryLight,
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Urgence'),
            const SizedBox(height: 12),
            _FormGroup(
              children: [
                _FormField(
                  controller: _contactUrgenceC,
                  label: 'Contact d\'urgence',
                  hint: 'Nom et téléphone d\'un proche',
                  icon: LineIcons.phone,
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: 'antécédents'),
            const SizedBox(height: 12),
            _FormGroup(
              children: [
                _FormField(
                  controller: _allergiesC,
                  label: 'Allergies',
                  hint: 'Liste de vos allergies connues',
                  icon: LineIcons.exclamationTriangle,
                  maxLines: 3,
                ),
                const Divider(height: 1, indent: 56),
                _FormField(
                  controller: _conditionsC,
                  label: 'Conditions médicales',
                  hint: 'Diabète, Hypertension, Asthme...',
                  icon: LineIcons.heartbeat,
                  maxLines: 3,
                ),
                const Divider(height: 1, indent: 56),
                _FormField(
                  controller: _medicamentsC,
                  label: 'Médicaments actuels',
                  hint: 'Liste des médicaments que vous prenez',
                  icon: LineIcons.pills,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlloUrgenceTheme.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _InfoCard({required this.title, required this.message, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 13, color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
        ),
      ),
    );
  }
}

class _FormGroup extends StatelessWidget {
  final List<Widget> children;
  const _FormGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AlloUrgenceTheme.cardShadow],
      ),
      child: Column(children: children),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, color: AlloUrgenceTheme.textTertiary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54)),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: 1,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
