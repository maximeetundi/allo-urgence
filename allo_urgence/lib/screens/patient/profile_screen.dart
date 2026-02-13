import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Header with Menu
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            // ... rest of content ...
            // Wait, I need to include the rest of the children.
            // I'll be careful with line matching.
            const SizedBox(height: 10),
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AlloUrgenceTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AlloUrgenceTheme.coloredShadow(AlloUrgenceTheme.primaryLight)],
              ),
              child: Center(
                child: Text(
                  user?.prenom.isNotEmpty == true ? user!.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${user?.prenom} ${user?.nom ?? ''}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(LineIcons.edit, size: 20, color: AlloUrgenceTheme.primaryLight),
                  onPressed: () => _showEditProfileModal(context, user),
                ),
              ],
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 40),

            // Settings Section
            _SectionHeader(title: 'Paramètres'),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: LineIcons.moon,
              title: 'Mode sombre',
              trailing: const _ThemeSwitch(),
            ),
            
            const SizedBox(height: 32),
            
            // Account Section
            _SectionHeader(title: 'Compte'),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: LineIcons.alternateSignOut,
              title: 'Se déconnecter',
              textColor: AlloUrgenceTheme.error,
              iconColor: AlloUrgenceTheme.error,
              onTap: () async {
                 await auth.logout();
                 if (!context.mounted) return;
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (_) => const LoginScreen()),
                   (_) => false,
                 );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: AlloUrgenceTheme.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showEditProfileModal(BuildContext context, dynamic user) {
    if (user == null) return;
    
    final prenomController = TextEditingController(text: user.prenom);
    final nomController = TextEditingController(text: user.nom);
    final telephoneController = TextEditingController(text: user.telephone);
    final contactUrgenceController = TextEditingController(text: user.contactUrgence);
    final allergiesController = TextEditingController(text: user.allergies);
    final conditionsController = TextEditingController(text: user.conditionsMedicales);
    final medicamentsController = TextEditingController(text: user.medicaments);
    
    // Simple state for loading inside the modal
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Modifier le profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _EditField(label: 'Prénom', controller: prenomController),
                      _EditField(label: 'Nom', controller: nomController),
                      _EditField(label: 'Téléphone', controller: telephoneController, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      Text('Informations Médicales (Optionnel)', style: TextStyle(fontWeight: FontWeight.bold, color: AlloUrgenceTheme.primaryLight, fontSize: 13)),
                      const SizedBox(height: 8),
                      _EditField(label: 'Contact d\'urgence', controller: contactUrgenceController),
                      _EditField(label: 'Allergies', controller: allergiesController),
                      _EditField(label: 'Conditions médicales', controller: conditionsController),
                      _EditField(label: 'Médicaments', controller: medicamentsController),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    setState(() => saving = true);
                    final success = await context.read<AuthProvider>().updateProfile(
                      prenom: prenomController.text,
                      nom: nomController.text,
                      telephone: telephoneController.text,
                      contactUrgence: contactUrgenceController.text,
                      allergies: allergiesController.text,
                      conditionsMedicales: conditionsController.text,
                      medicaments: medicamentsController.text,
                    );
                    if (context.mounted) {
                      setState(() => saving = false);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil mis à jour'), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Erreur'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlloUrgenceTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: saving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _EditField({required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return Align(
      alignment: Alignment.centerLeft,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AlloUrgenceTheme.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AlloUrgenceTheme.primaryLight).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (iconColor ?? AlloUrgenceTheme.primaryLight).withOpacity(0.2)),
              ),
              child: Icon(icon, color: iconColor ?? AlloUrgenceTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? (isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                ),
              ),
            ),
            if (trailing != null) trailing! else if (onTap != null) Icon(Icons.chevron_right, color: AlloUrgenceTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Switch.adaptive(
      value: themeProvider.isDarkMode,
      activeColor: AlloUrgenceTheme.primaryLight,
      onChanged: (_) => themeProvider.toggleTheme(),
    );
  }
}
