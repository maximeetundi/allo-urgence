import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../config/theme.dart';
import '../../models/ticket.dart';
import '../../services/socket_service.dart';
import '../auth/login_screen.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> with SingleTickerProviderStateMixin {
  String? _selectedHospitalId;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadHospitals();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    // Load queue for first hospital by default
    final queue = context.read<QueueProvider>();
    if (_selectedHospitalId != null) {
      await queue.loadQueue(_selectedHospitalId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<QueueProvider>();

    return Scaffold(
      // backgroundColor follows theme
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHospitals,
          color: AlloUrgenceTheme.primaryLight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0, 0.4)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👩‍⚕️ Bonjour, ${auth.user?.prenom ?? ''}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 4),
                              Text('Tableau de bord infirmier',
                                style: TextStyle(fontSize: 14, color: AlloUrgenceTheme.textSecondary)),
                            ],
                          ),
                        ),
                        _buildLogoutButton(auth),
                      ],
                    ),
                  ),
                ),
              ),

              // Queue summary
              if (queue.summary.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.15, 0.6)),
                    child: _buildSummary(queue),
                  ),
                ),

              // Section title
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.3, 0.7)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      children: [
                        const Text('File d\'attente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${queue.tickets.length} patients',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AlloUrgenceTheme.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ticket list
              queue.tickets.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 56, color: AlloUrgenceTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text('Aucun patient en attente', style: TextStyle(fontSize: 16, color: AlloUrgenceTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PatientTicketCard(
                            ticket: queue.tickets[i],
                            onTriage: () => _showTriageSheet(queue.tickets[i]),
                          ),
                        ),
                        childCount: queue.tickets.length,
                      ),
                    ),
                  ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return GestureDetector(
      onTap: () async {
        await auth.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
        );
      },
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AlloUrgenceTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.logout_rounded, color: AlloUrgenceTheme.error, size: 20),
      ),
    );
  }

  Widget _buildSummary(QueueProvider queue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(
            icon: Icons.people_rounded,
            label: 'Actifs',
            value: '${queue.summary['totalActive'] ?? 0}',
            color: AlloUrgenceTheme.primaryLight,
          )),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(
            icon: Icons.schedule_rounded,
            label: 'Attente moy.',
            value: '${queue.summary['averageWaitMinutes'] ?? 0} min',
            color: AlloUrgenceTheme.warning,
          )),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(
            icon: Icons.warning_rounded,
            label: 'Urgents',
            value: '${(queue.summary['byPriority'] as Map?)?['1'] ?? 0}',
            color: AlloUrgenceTheme.error,
          )),
        ],
      ),
    );
  }

  void _showTriageSheet(Ticket ticket) {
    int selectedPriority = ticket.effectivePriority;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AlloUrgenceTheme.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Triage — ${ticket.patientFullName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (ticket.preTriageCategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Motif: ${ticket.preTriageCategory}', style: TextStyle(color: AlloUrgenceTheme.textSecondary)),
                ),
              const SizedBox(height: 20),

              // Priority selector
              const Text('Priorité validée', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(5, (i) {
                  final p = i + 1;
                  final c = AlloUrgenceTheme.getPriorityColor(p);
                  final selected = selectedPriority == p;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedPriority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: selected ? c : c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? c : c.withValues(alpha: 0.3), width: selected ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('P$p', style: TextStyle(color: selected ? Colors.white : c, fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notes d\'observation...',
                  filled: true,
                  fillColor: AlloUrgenceTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // TODO: Call triage API
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlloUrgenceTheme.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Valider le triage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary Card ────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [AlloUrgenceTheme.cardShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(fontSize: 11, color: AlloUrgenceTheme.textTertiary)),
        ],
      ),
    );
  }
}

// ── Patient Ticket Card ─────────────────────────────────────────
class _PatientTicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTriage;
  const _PatientTicketCard({required this.ticket, required this.onTriage});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority);

    return InkWell(
      onTap: onTriage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AlloUrgenceTheme.cardShadow],
        ),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('P${ticket.effectivePriority}',
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.patientFullName.isNotEmpty ? ticket.patientFullName : 'Patient',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(ticket.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(ticket.status)),
                        ),
                      ),
                      if (ticket.preTriageCategory != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ticket.preTriageCategory!,
                            style: TextStyle(fontSize: 12, color: AlloUrgenceTheme.textTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Position
            if (ticket.queuePosition != null)
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AlloUrgenceTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('#${ticket.queuePosition}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AlloUrgenceTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'waiting': return AlloUrgenceTheme.warning;
      case 'checked_in': return AlloUrgenceTheme.primaryLight;
      case 'triage': return AlloUrgenceTheme.accent;
      case 'in_progress': return AlloUrgenceTheme.success;
      case 'treated': return AlloUrgenceTheme.textTertiary;
      default: return AlloUrgenceTheme.textSecondary;
    }
  }
}
