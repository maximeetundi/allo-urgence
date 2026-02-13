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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
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
              Text(
                '${user?.prenom} ${user?.nom ?? ''}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                ),
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
