import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'auth/login_screen.dart';
import 'patient/home_screen.dart';
import 'patient/main_navigation_screen.dart';
import 'nurse/dashboard_screen.dart';
import 'doctor/patient_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _slideUp;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.init();

    if (!mounted) return;

    Widget destination;
    if (!auth.isAuthenticated) {
      destination = const LoginScreen();
    } else if (auth.user!.isNurse) {
      destination = const NurseDashboardScreen();
    } else if (auth.user!.isDoctor) {
      destination = const DoctorPatientListScreen();
    } else {
      destination = const PatientMainScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A5F),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating orbs background
            ..._buildOrbs(),
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_logoController, _pulseController]),
                builder: (_, __) => Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Transform.scale(
                          scale: _scale.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🏥', style: TextStyle(fontSize: 48)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Allo Urgence',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestion intelligente des urgences',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 56),
                        // Loading indicator
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: Colors.white.withValues(alpha: 0.8),
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrbs() {
    return [
      Positioned(
        top: -60,
        right: -40,
        child: _GlowOrb(
          size: 200,
          color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
        ),
      ),
      Positioned(
        bottom: -80,
        left: -60,
        child: _GlowOrb(
          size: 250,
          color: AlloUrgenceTheme.accent.withValues(alpha: 0.08),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: -30,
        child: _GlowOrb(
          size: 120,
          color: AlloUrgenceTheme.primaryGradientStart.withValues(alpha: 0.07),
        ),
      ),
    ];
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
