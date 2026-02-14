import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [AlloUrgenceTheme.cardShadow],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: AlloUrgenceTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.user?.prenom.isNotEmpty == true ? auth.user!.prenom[0] : '?',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${auth.user?.prenom} ${auth.user?.nom}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                          ),
                        ),
                        Text(
                          auth.user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: AlloUrgenceTheme.primaryLight),
                    onPressed: () {}, // TODO: Edit profile
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Groups
            _SettingsGroup(
              title: 'Général',
              children: [
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Langue',
                  value: 'Français (CA)',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Thème',
                  value: 'Système',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SettingsGroup(
              title: 'Notifications',
              children: [
                _SwitchTile(
                  title: 'Nouvelles demandes',
                  subtitle: 'Être notifié lors\'un nouveau patient arrive',
                  value: true,
                  onChanged: (v) {},
                ),
                _SwitchTile(
                  title: 'Alertes critiques',
                  subtitle: 'Notifications prioritaires pour P1/P2',
                  value: true,
                  onChanged: (v) {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SettingsGroup(
              title: 'Sécurité',
              children: [
                _SettingsTile(
                  icon: Icons.lock_rounded,
                  title: 'Changer le mot de passe',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.security_rounded,
                  title: 'Double authentification',
                  value: 'Désactivé',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 40),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AlloUrgenceTheme.cardShadow],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AlloUrgenceTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AlloUrgenceTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AlloUrgenceTheme.primaryLight,
          ),
        ],
      ),
    );
  }
}
