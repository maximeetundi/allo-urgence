import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const PatientHomeScreen(),
    const PatientHistoryScreen(),
    const PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _PatientDrawer(
        auth: auth,
        onTabSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
        selectedIndex: _selectedIndex,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: AlloUrgenceTheme.primaryLight,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AlloUrgenceTheme.primaryLight.withOpacity(0.1),
              color: isDark ? Colors.grey[400] : Colors.black,
              tabs: const [
                GButton(
                  icon: LineIcons.home,
                  text: 'Accueil',
                ),
                GButton(
                  icon: LineIcons.history,
                  text: 'Historique',
                ),
                GButton(
                  icon: LineIcons.user,
                  text: 'Profil',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Patient Drawer ──────────────────────────────────────────────
class _PatientDrawer extends StatelessWidget {
  final AuthProvider auth;
  final Function(int) onTabSelected;
  final int selectedIndex;

  const _PatientDrawer({required this.auth, required this.onTabSelected, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AlloUrgenceTheme.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AlloUrgenceTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AlloUrgenceTheme.coloredShadow(AlloUrgenceTheme.primaryLight)],
              ),
              child: Center(
                child: Text(
                  auth.user?.prenom.isNotEmpty == true ? auth.user!.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${auth.user?.prenom ?? ''} ${auth.user?.nom ?? ''}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
            ),
            Text(
              auth.user?.email ?? '',
              style: TextStyle(fontSize: 13, color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Divider(color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
            const SizedBox(height: 8),

            // Menu items
            _PatientDrawerItem(icon: LineIcons.home, label: 'Accueil', selected: selectedIndex == 0,
              onTap: () => onTabSelected(0)),
            _PatientDrawerItem(icon: LineIcons.history, label: 'Historique', selected: selectedIndex == 1,
              onTap: () => onTabSelected(1)),
            _PatientDrawerItem(icon: Icons.local_hospital_rounded, label: 'Hôpital',
              onTap: () => Navigator.pop(context)),
            _PatientDrawerItem(icon: LineIcons.bell, label: 'Notifications',
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              }),
            _PatientDrawerItem(icon: LineIcons.user, label: 'Profil', selected: selectedIndex == 2,
              onTap: () => onTabSelected(2)),
            _PatientDrawerItem(icon: Icons.settings_rounded, label: 'Paramètres',
              onTap: () => Navigator.pop(context)),

            const Spacer(),
            Divider(color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
            _PatientDrawerItem(icon: Icons.logout_rounded, label: 'Se déconnecter', isDestructive: true,
              onTap: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PatientDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDestructive;
  final VoidCallback onTap;
  const _PatientDrawerItem({required this.icon, required this.label, this.selected = false, this.isDestructive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDestructive ? AlloUrgenceTheme.error : AlloUrgenceTheme.primaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isDestructive ? AlloUrgenceTheme.error : (selected ? activeColor : (isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary))),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(
                fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: isDestructive ? AlloUrgenceTheme.error : (isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
