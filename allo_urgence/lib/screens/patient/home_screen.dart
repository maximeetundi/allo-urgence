import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';
import 'pre_triage_screen.dart';
import 'ticket_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ticket = context.read<TicketProvider>();
    await ticket.loadActiveTicket();
    await ticket.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ticket = context.watch<TicketProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AlloUrgenceTheme.primaryLight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0, 0.5)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour, ${auth.user?.prenom ?? ''} 👋',
                                style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
                                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comment pouvons-nous vous aider ?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Theme toggle
                        _ThemeToggle(),
                        const SizedBox(width: 8),
                        _AvatarButton(
                          letter: auth.user?.prenom.isNotEmpty == true ? auth.user!.prenom[0] : '?',
                          onTap: () async {
                            await auth.logout();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Active ticket
              if (ticket.activeTicket != null)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.15, 0.65)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ActiveTicketCard(ticket: ticket),
                    ),
                  ),
                ),

              // Emergency button
              if (ticket.activeTicket == null)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.15, 0.65)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _EmergencyButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PreTriageScreen())),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // How it works
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.3, 0.8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _HowItWorks(),
                  ),
                ),
              ),

              // History
              if (ticket.history.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        children: [
                          Text('Historique', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                          )),
                          const Spacer(),
                          Text('${ticket.history.length} visites', style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final t = ticket.history[i];
                      return FadeTransition(
                        opacity: CurvedAnimation(parent: _animController, curve: Interval(0.5 + i * 0.05, 1.0)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          child: _HistoryCard(ticket: t),
                        ),
                      );
                    },
                    childCount: ticket.history.take(5).length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme Toggle ────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AlloUrgenceTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : AlloUrgenceTheme.divider,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: isDark ? const Color(0xFFFFD700) : AlloUrgenceTheme.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Avatar Button ───────────────────────────────────────────────
class _AvatarButton extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  const _AvatarButton({required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AlloUrgenceTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [AlloUrgenceTheme.coloredShadow(AlloUrgenceTheme.primaryLight)],
        ),
        child: Center(
          child: Text(letter.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
      ),
    );
  }
}

// ── Emergency Button ────────────────────────────────────────────
class _EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EmergencyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Déclarer une urgence',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Text(
              'Pré-triage en 30 secondes',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Ticket Card ──────────────────────────────────────────
class _ActiveTicketCard extends StatelessWidget {
  final TicketProvider ticket;
  const _ActiveTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket.activeTicket!;
    final color = AlloUrgenceTheme.getPriorityColor(t.effectivePriority);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketScreen(ticketId: t.id))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [AlloUrgenceTheme.cardShadow],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(AlloUrgenceTheme.getPriorityIcon(t.effectivePriority), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Ticket actif', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                  )),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text('P${t.effectivePriority}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AlloUrgenceTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: 'Position', value: '${t.queuePosition ?? '-'}', icon: Icons.people_outline_rounded),
                  Container(width: 1, height: 30, color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
                  _MiniStat(label: 'Attente', value: '${t.estimatedWaitMinutes ?? '-'} min', icon: Icons.schedule_rounded),
                  Container(width: 1, height: 30, color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
                  _MiniStat(label: 'Statut', value: t.statusLabel, icon: Icons.info_outline_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Voir les détails', style: TextStyle(fontSize: 13, color: AlloUrgenceTheme.primaryLight, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: AlloUrgenceTheme.primaryLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 16, color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary)),
      ],
    );
  }
}

// ── How It Works ────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AlloUrgenceTheme.cardShadow],
        border: isDark ? Border.all(color: AlloUrgenceTheme.darkDivider.withValues(alpha: 0.5)) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AlloUrgenceTheme.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Comment ça fonctionne ?', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          _Step(n: '1', text: 'Répondez au pré-triage (30 sec)', color: AlloUrgenceTheme.primaryGradientStart),
          _Step(n: '2', text: 'Obtenez votre ticket et temps estimé', color: AlloUrgenceTheme.primaryLight),
          _Step(n: '3', text: 'Rendez-vous à l\'hôpital au bon moment', color: AlloUrgenceTheme.accent),
          _Step(n: '4', text: 'Passez au triage avec l\'infirmier', color: AlloUrgenceTheme.success, last: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AlloUrgenceTheme.warning.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AlloUrgenceTheme.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'L\'application ne remplace pas le jugement clinique.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  final Color color;
  final bool last;
  const _Step({required this.n, required this.text, required this.color, this.last = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(
            fontSize: 14,
            color: isDark ? AlloUrgenceTheme.darkTextPrimary : AlloUrgenceTheme.textPrimary,
          ))),
        ],
      ),
    );
  }
}

// ── History Card ────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final dynamic ticket;
  const _HistoryCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority);
    final treated = ticket.status == 'treated';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AlloUrgenceTheme.cardShadow],
        border: isDark ? Border.all(color: AlloUrgenceTheme.darkDivider.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('P${ticket.effectivePriority}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.statusLabel, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                )),
                Text(ticket.createdAt.toString().substring(0, 10), style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
                )),
              ],
            ),
          ),
          Icon(
            treated ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: treated ? AlloUrgenceTheme.success : (isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary),
            size: 20,
          ),
        ],
      ),
    );
  }
}
