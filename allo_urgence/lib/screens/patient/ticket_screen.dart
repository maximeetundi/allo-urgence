import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/ticket_provider.dart';
import '../../config/theme.dart';
import '../../models/ticket.dart';
import 'main_navigation_screen.dart';
import '../../providers/auth_provider.dart';
import 'patient_drawer.dart';

class TicketScreen extends StatefulWidget {
  final String ticketId;
  const TicketScreen({super.key, required this.ticketId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _loadTicket();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    await context.read<TicketProvider>().loadActiveTicket();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = context.watch<TicketProvider>();
    final t = ticket.activeTicket;

    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: PatientDrawer(
        auth: auth,
        onTabSelected: (index) {
           Navigator.pop(context); // Close drawer
           // Navigate to home with index
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const PatientMainScreen()),
             (_) => false,
           );
           // Actually, easiest is just pop until we hit MainScreen if we are there?
           // But TicketScreen might be top level after login?
           // The "Retour à l'accueil" button pushes PatientHomeScreen(), but PatientHomeScreen is a Child of PatientMainScreen.
           // pushing PatientHomeScreen directly will lose the bottom nav!
           // The "Retour à l'accueil" button is BUGGY too.
           // It should push PatientMainScreen().
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const PatientMainScreen()),
             (_) => false,
           );
        },
        selectedIndex: -1,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            t == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadTicket,
                  color: AlloUrgenceTheme.primaryLight,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 50), // Space for menu button
                        // Header
                        _buildHeader(t),
                        // Stats
                        _buildStats(t),
                        // QR Code
                        if (t.sharedToken != null) _buildQRSection(t),
                        // Details
                        _buildDetails(t),
                        const SizedBox(height: 24),
                        // Return button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const PatientMainScreen()),
                                (_) => false,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AlloUrgenceTheme.textSecondary,
                                side: const BorderSide(color: AlloUrgenceTheme.divider),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Retour à l\'accueil'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.menu, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Ticket t) {
    final color = AlloUrgenceTheme.getPriorityColor(t.effectivePriority);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: const Interval(0, 0.5)),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(AlloUrgenceTheme.getPriorityIcon(t.effectivePriority), size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              'Priorité ${AlloUrgenceTheme.getPriorityLabel(t.effectivePriority)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t.statusLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(Ticket t) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.7)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.people_outline_rounded,
              label: 'Position',
              value: '${t.queuePosition ?? '-'}',
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.schedule_rounded,
              label: 'Attente estimée',
              value: '${t.estimatedWaitMinutes ?? '-'} min',
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
            )),
            if (t.assignedRoom != null) ...[
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.meeting_room_rounded,
                label: 'Salle',
                value: t.assignedRoom!,
                gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF4ADE80)]),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection(Ticket t) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.4, 0.9)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [AlloUrgenceTheme.cardShadow],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2_rounded, color: AlloUrgenceTheme.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Text('Votre QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AlloUrgenceTheme.divider),
              ),
              child: QrImageView(
                data: t.sharedToken ?? t.id,
                version: QrVersions.auto,
                size: 160,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AlloUrgenceTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t.sharedToken ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 3, color: AlloUrgenceTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Présentez ce code à l\'accueil',
              style: TextStyle(fontSize: 13, color: AlloUrgenceTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(Ticket t) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [AlloUrgenceTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Détails du ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            if (t.preTriageCategory != null) _DetailRow(label: 'Motif', value: t.preTriageCategory!),
            _DetailRow(label: 'Priorité initiale', value: 'P${t.priorityLevel} — ${AlloUrgenceTheme.getPriorityLabel(t.priorityLevel)}'),
            if (t.validatedPriority != null)
              _DetailRow(label: 'Priorité validée', value: 'P${t.validatedPriority} — ${AlloUrgenceTheme.getPriorityLabel(t.validatedPriority!)}'),
            _DetailRow(label: 'Créé le', value: t.createdAt.substring(0, 16).replaceAll('T', ' à ')),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;
  const _StatCard({required this.icon, required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ── Detail Row ──────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: AlloUrgenceTheme.textTertiary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
