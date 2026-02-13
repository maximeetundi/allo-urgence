import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import 'home_screen.dart';
import 'history_screen.dart'; // Will create next
import 'profile_screen.dart'; // Will create next

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PatientHomeScreen(),
    const PatientHistoryScreen(),
    const PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
