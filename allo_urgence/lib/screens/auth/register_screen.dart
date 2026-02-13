import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _prenomC = TextEditingController();
  final _nomC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();
  final _telephoneC = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in [_prenomC, _nomC, _emailC, _passwordC, _confirmPasswordC, _telephoneC]) {
      c.dispose();
    }
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
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Erreur'), backgroundColor: AlloUrgenceTheme.error),
      );
    }
  }

  String? _req(String? v) => v == null || v.isEmpty ? 'Champ obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AlloUrgenceTheme.darkGradient : AlloUrgenceTheme.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle
                          Text(
                            'Quelques informations pour commencer',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white.withValues(alpha: 0.45) : AlloUrgenceTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name fields side by side
                          Row(
                            children: [
                              Expanded(child: _field(_prenomC, 'Prénom', Icons.person_outline_rounded, validator: _req)),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_nomC, 'Nom', Icons.person_outline_rounded, validator: _req)),
                            ],
                          ),

                          _field(_emailC, 'Courriel', Icons.mail_outline_rounded,
                              type: TextInputType.emailAddress, 
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Champ obligatoire';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email invalide';
                                return null;
                              }),

                          _field(_telephoneC, 'Téléphone (optionnel)', Icons.phone_outlined,
                              type: TextInputType.phone,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  // Basic global phone regex (mostly digits)
                                  if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(v)) return 'Numéro invalide';
                                }
                                return null;
                              }),

                          _field(
                            _passwordC, 'Mot de passe', Icons.lock_outline_rounded,
                            obscure: _obscurePassword,
                            validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 caractères',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: isDark ? Colors.white.withValues(alpha: 0.4) : AlloUrgenceTheme.textTertiary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),

                          _field(
                            _confirmPasswordC, 'Confirmer le mot de passe', Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            validator: (v) => v == _passwordC.text ? null : 'Les mots de passe ne correspondent pas',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: isDark ? Colors.white.withValues(alpha: 0.4) : AlloUrgenceTheme.textTertiary,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Info note
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AlloUrgenceTheme.primaryLight.withValues(alpha: 0.08)
                                  : AlloUrgenceTheme.primaryLight.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? AlloUrgenceTheme.primaryLight.withValues(alpha: 0.15)
                                    : AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18,
                                    color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.7)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Vos informations médicales pourront être ajoutées plus tard dans votre profil.',
                                    style: TextStyle(
                                      fontSize: 12, height: 1.4,
                                      color: isDark ? Colors.white.withValues(alpha: 0.5) : AlloUrgenceTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AlloUrgenceTheme.primaryLight,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: auth.loading
                                ? const SizedBox(height: 22, width: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Terms
                          Center(
                            child: Text(
                              'En créant un compte, vous acceptez nos\nconditions d\'utilisation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white.withValues(alpha: 0.25) : AlloUrgenceTheme.textTertiary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c, String hint, IconData icon, {
    TextInputType type = TextInputType.text, bool obscure = false,
    String? Function(String?)? validator, Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        style: TextStyle(
          color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
          fontSize: 15,
        ),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.3) : AlloUrgenceTheme.textTertiary,
          ),
          prefixIcon: Icon(icon,
            color: isDark ? Colors.white.withValues(alpha: 0.4) : AlloUrgenceTheme.textTertiary,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : AlloUrgenceTheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AlloUrgenceTheme.primaryLight.withValues(alpha: isDark ? 0.6 : 1.0),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AlloUrgenceTheme.error.withValues(alpha: 0.6)),
          ),
          errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
