import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../patient/home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _success;
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
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _error = 'Veuillez entrer le code à 6 chiffres');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.verifyEmail(_code);
      if (!mounted) return;

      if (result) {
        setState(() => _success = 'Courriel vérifié !');
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
          (_) => false,
        );
      } else {
        setState(() => _error = auth.error ?? 'Code de vérification incorrect');
      }
    } catch (e) {
      setState(() => _error = 'Erreur de vérification');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; _success = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.resendVerification();
      if (mounted) setState(() => _success = 'Nouveau code envoyé !');
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur lors du renvoi');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _skipVerification() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AlloUrgenceTheme.darkGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AlloUrgenceTheme.primaryLight, const Color(0xFF6366F1)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Vérifiez votre courriel',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code à 6 chiffres a été envoyé à votre adresse email',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5), height: 1.4),
                  ),
                  const SizedBox(height: 36),

                  // Code input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) => Container(
                      width: 46, height: 56,
                      margin: EdgeInsets.only(right: i < 5 ? 8 : 0, left: i == 3 ? 8 : 0),
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.7), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (val.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_code.length == 6) _verify();
                        },
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),

                  // Error / success
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AlloUrgenceTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AlloUrgenceTheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: AlloUrgenceTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: AlloUrgenceTheme.error, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_success != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AlloUrgenceTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AlloUrgenceTheme.success.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.check_circle_outline, color: AlloUrgenceTheme.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_success!, style: TextStyle(color: AlloUrgenceTheme.success, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 4),

                  // Verify button
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AlloUrgenceTheme.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Vérifier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.check_rounded, size: 20),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resend
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: _resending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                      : Text(
                          'Renvoyer le code',
                          style: TextStyle(color: AlloUrgenceTheme.primaryLight, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                  ),

                  const Spacer(),

                  // Skip
                  TextButton(
                    onPressed: _skipVerification,
                    child: Text(
                      'Passer pour le moment',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
