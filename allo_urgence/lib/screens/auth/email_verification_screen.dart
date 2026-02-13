import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../patient/home_screen.dart';
import 'login_screen.dart';

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

  void _showEditEmailDialog() {
    final emailC = TextEditingController(text: context.read<AuthProvider>().user?.email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier l\'adresse courriel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre nouvelle adresse pour recevoir un nouveau code.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Nouvel email', prefixIcon: Icon(Icons.email_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (emailC.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<AuthProvider>().updateEmail(emailC.text.trim());
              if (mounted) {
                if (success) {
                  setState(() => _success = 'Email mis à jour !');
                  _controllers.forEach((c) => c.clear());
                } else {
                  setState(() => _error = context.read<AuthProvider>().error);
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Log out if they want to go back, so they can't access authenticated areas
            // Or just pop if it was pushed on top of login? 
            // If they are logged in but unverified, we want to force them here or logout.
            // Let's offer Logout instead of Skip.
             context.read<AuthProvider>().logout();
             Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), // Need to import LoginScreen if not imported? LoginScreen is not imported. 
                // Wait, LoginScreen import might be missing.
                // Let's just pop if it's from registration, but if from Login redirect, pop might be empty.
                // Safer: Just go to root '/' which usually checks auth.
                (_) => false
             );
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded, color: AlloUrgenceTheme.primaryLight, size: 40),
                ),
                const SizedBox(height: 24),

                Text(
                  'Vérifiez votre courriel',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                
                // Email Display with Edit
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          auth.user?.email ?? 'votre adresse email',
                          style: TextStyle(
                             color: isDark ? Colors.white70 : Colors.grey.shade800,
                             fontWeight: FontWeight.w600,
                             fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: !auth.loading ? _showEditEmailDialog : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit_rounded, size: 16, color: AlloUrgenceTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                Text(
                  'Un code à 6 chiffres a été envoyé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : AlloUrgenceTheme.textSecondary),
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
                      style: const TextStyle(
                        color: Color(0xFF0F172A), // Always dark for max contrast
                        fontSize: 22, fontWeight: FontWeight.w700
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark 
                            ? Colors.white.withValues(alpha: 0.1) 
                            : const Color(0xFFF1F5F9), // Light grey, not white
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14), 
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1), width: 1.5)
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14), 
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1), width: 1.5)
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14), 
                            borderSide: BorderSide(color: AlloUrgenceTheme.primaryLight, width: 2)
                        ),
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
                    child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Vérifier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: _resending
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Renvoyer le code',
                        style: TextStyle(color: AlloUrgenceTheme.primaryLight, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                ),

                const Spacer(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
