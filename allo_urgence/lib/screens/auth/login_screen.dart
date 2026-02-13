import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'register_screen.dart';
import '../patient/main_navigation_screen.dart';
import '../nurse/dashboard_screen.dart';
import '../doctor/patient_list_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Block admin access on mobile
      if (auth.user!.isAdmin) {
        await auth.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Les administrateurs doivent utiliser le panneau d\'administration web.'),
              backgroundColor: AlloUrgenceTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (!auth.user!.emailVerified) {
        // Redirect to verification screen if email not verified
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          (_) => false,
        );
        return;
      }

      Widget destination;
      if (auth.user!.isNurse) {
        destination = const NurseDashboardScreen();
      } else if (auth.user!.isDoctor) {
        destination = const DoctorPatientListScreen();
      } else {
        destination = const PatientMainScreen();
      }
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(a),
              child: child,
            )),
        ),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.error ?? 'Erreur de connexion')),
            ],
          ),
          backgroundColor: AlloUrgenceTheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)])
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF1F5F9), Color(0xFFE0ECFF)]),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                      // Logo
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : AlloUrgenceTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(child: Text('🏥', style: TextStyle(fontSize: 36))),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Bienvenue',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connectez-vous pour continuer',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : AlloUrgenceTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Glass card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : AlloUrgenceTheme.divider.withValues(alpha: 0.5)),
                          boxShadow: isDark ? [] : [AlloUrgenceTheme.cardShadow],
                        ),
                        child: Column(
                          children: [
                            _GlassInput(
                              controller: _emailController,
                              hint: 'Courriel',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.isEmpty ? 'Courriel requis' : null,
                            ),
                            const SizedBox(height: 16),
                            _GlassInput(
                              controller: _passwordController,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                              validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: isDark ? Colors.white.withValues(alpha: 0.5) : AlloUrgenceTheme.textTertiary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AlloUrgenceTheme.primaryLight,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: auth.loading
                                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Register link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const RegisterScreen(),
                              transitionDuration: const Duration(milliseconds: 400),
                              transitionsBuilder: (_, a, __, child) =>
                                SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)), child: child),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.5) : AlloUrgenceTheme.textSecondary),
                              children: [
                                const TextSpan(text: 'Pas de compte ? '),
                                TextSpan(
                                  text: 'Créer un compte',
                                  style: TextStyle(color: AlloUrgenceTheme.accent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),


                      // Debug Credentials Button
                      // if (kDebugMode)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Comptes de Démo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    // Patient
                                    ListTile(
                                      leading: const Icon(Icons.person_outline),
                                      title: const Text('Patient (Luc Bouchard)'),
                                      subtitle: const Text('patient@test.ca'),
                                      onTap: () {
                                        _emailController.text = 'patient@test.ca';
                                        _passwordController.text = 'patient123';
                                        Navigator.pop(context);
                                      },
                                    ),
                                    // Nurse
                                    ListTile(
                                      leading: const Icon(Icons.medical_services_outlined),
                                      title: const Text('Infirmier (Marie Tremblay)'),
                                      subtitle: const Text('nurse@allourgence.ca'),
                                      onTap: () {
                                        _emailController.text = 'nurse@allourgence.ca';
                                        _passwordController.text = 'nurse123';
                                        Navigator.pop(context);
                                      },
                                    ),
                                    // Doctor
                                    ListTile(
                                      leading: const Icon(Icons.monitor_heart_outlined),
                                      title: const Text('Médecin (Jean Gagnon)'),
                                      subtitle: const Text('doctor@allourgence.ca'),
                                      onTap: () {
                                        _emailController.text = 'doctor@allourgence.ca';
                                        _passwordController.text = 'doctor123';
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Remplir Infos Démo',
                            style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : AlloUrgenceTheme.textTertiary),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Input ─────────────────────────────────────────────────
class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Function(String)? onSubmitted;

  const _GlassInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.35) : AlloUrgenceTheme.textTertiary),
        prefixIcon: Icon(icon, color: isDark ? Colors.white.withValues(alpha: 0.5) : AlloUrgenceTheme.textTertiary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : AlloUrgenceTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AlloUrgenceTheme.error.withValues(alpha: 0.6)),
        ),
        errorStyle: TextStyle(color: isDark ? Colors.orangeAccent : AlloUrgenceTheme.error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}


