import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../config/theme.dart';
import '../../models/ticket.dart';
import '../auth/login_screen.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _filter = 'all'; // all, in_progress, triage

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<QueueProvider>();

    final filtered = _filter == 'all'
      ? queue.tickets
      : queue.tickets.where((t) => t.status == _filter).toList();

    return Scaffold(
      // backgroundColor follows theme
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
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
                                '👨‍⚕️ Dr. ${auth.user?.nom ?? ''}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 4),
                              Text('Gestion des patients',
                                style: TextStyle(fontSize: 14, color: AlloUrgenceTheme.textSecondary)),
                            ],
                          ),
                        ),
                        GestureDetector(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.1, 0.5)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(label: 'Tous', active: _filter == 'all', count: queue.tickets.length,
                            onTap: () => setState(() => _filter = 'all')),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'En triage', active: _filter == 'triage',
                            count: queue.tickets.where((t) => t.status == 'triage').length,
                            color: AlloUrgenceTheme.accent,
                            onTap: () => setState(() => _filter = 'triage')),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'En cours', active: _filter == 'in_progress',
                            count: queue.tickets.where((t) => t.status == 'in_progress').length,
                            color: AlloUrgenceTheme.success,
                            onTap: () => setState(() => _filter = 'in_progress')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Patient list
              filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.person_search_rounded, size: 56, color: AlloUrgenceTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text('Aucun patient', style: TextStyle(fontSize: 16, color: AlloUrgenceTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DoctorPatientCard(
                            ticket: filtered[i],
                            onTap: () => _showPatientSheet(filtered[i]),
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientSheet(Ticket ticket) {
    final diagnosisController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AlloUrgenceTheme.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // Patient info
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: AlloUrgenceTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        ticket.patientFullName.isNotEmpty ? ticket.patientFullName[0] : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.patientFullName.isNotEmpty ? ticket.patientFullName : 'Patient',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'P${ticket.effectivePriority} — ${AlloUrgenceTheme.getPriorityLabel(ticket.effectivePriority)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Medical info
              if (ticket.allergies != null || ticket.conditionsMedicales != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AlloUrgenceTheme.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_information_rounded, size: 16, color: AlloUrgenceTheme.warning),
                          const SizedBox(width: 6),
                          const Text('Informations médicales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      if (ticket.allergies != null) ...[
                        const SizedBox(height: 8),
                        Text('Allergies: ${ticket.allergies}', style: const TextStyle(fontSize: 13)),
                      ],
                      if (ticket.conditionsMedicales != null) ...[
                        const SizedBox(height: 4),
                        Text('Conditions: ${ticket.conditionsMedicales}', style: const TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Diagnosis
              const Text('Diagnostic', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: diagnosisController,
                decoration: InputDecoration(
                  hintText: 'Diagnostic...',
                  filled: true,
                  fillColor: AlloUrgenceTheme.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              const Text('Notes cliniques', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Observations, traitements administrés...',
                  filled: true,
                  fillColor: AlloUrgenceTheme.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (ticket.status != 'in_progress')
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.meeting_room_rounded, size: 18),
                          label: const Text('Assigner salle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AlloUrgenceTheme.primaryLight,
                            side: BorderSide(color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  if (ticket.status != 'in_progress') const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // TODO: Call treat API
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Marquer traité'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlloUrgenceTheme.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Chip ─────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final int count;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.count, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AlloUrgenceTheme.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: active ? null : Border.all(color: AlloUrgenceTheme.divider),
          boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AlloUrgenceTheme.textSecondary,
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.25) : AlloUrgenceTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AlloUrgenceTheme.textTertiary,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Doctor Patient Card ─────────────────────────────────────────
class _DoctorPatientCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const _DoctorPatientCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority);

    return InkWell(
      onTap: onTap,
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
            // Avatar with priority
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  ticket.patientFullName.isNotEmpty ? ticket.patientFullName[0].toUpperCase() : '?',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.patientFullName.isNotEmpty ? ticket.patientFullName : 'Patient',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TagBadge(
                        label: 'P${ticket.effectivePriority}',
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      _TagBadge(
                        label: ticket.statusLabel,
                        color: _statusColor(ticket.status),
                        filled: false,
                      ),
                      if (ticket.assignedRoom != null) ...[
                        const SizedBox(width: 6),
                        _TagBadge(label: ticket.assignedRoom!, color: AlloUrgenceTheme.textSecondary, filled: false),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AlloUrgenceTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'triage': return AlloUrgenceTheme.accent;
      case 'in_progress': return AlloUrgenceTheme.success;
      default: return AlloUrgenceTheme.textSecondary;
    }
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _TagBadge({required this.label, required this.color, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}
