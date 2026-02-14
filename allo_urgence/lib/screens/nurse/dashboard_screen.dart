import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nurse_provider.dart';
import '../../config/theme.dart';
import '../../models/ticket.dart';
import '../auth/login_screen.dart';
import '../common/settings_screen.dart';
import '../common/notifications_screen.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> with SingleTickerProviderStateMixin {
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
    final auth = context.read<AuthProvider>();
    final nurse = context.read<NurseProvider>();
    final hospitalId = auth.user?.hospitalId;
    if (hospitalId != null) {
      await Future.wait([
        nurse.loadPatients(hospitalId: hospitalId),
        nurse.loadAlerts(hospitalId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nurse = context.watch<NurseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _NurseDrawer(auth: auth),
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
                  opacity: CurvedAnimation(parent: _animController, curve: const Interval(0, 0.4)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => GestureDetector(
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? AlloUrgenceTheme.darkSurfaceVariant : AlloUrgenceTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.menu_rounded, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👩‍⚕️ Bonjour, ${auth.user?.prenom ?? ''}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3,
                                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text('Tableau de bord infirmier',
                                style: TextStyle(fontSize: 14, color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary)),
                            ],
                          ),
                        ),
                        // Alerts badge
                        _AlertsBadge(
                          count: nurse.alerts.length,
                          onTap: () => _showAlertsSheet(nurse),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats summary
              if (nurse.stats != null)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.15, 0.6)),
                    child: _buildSummary(nurse),
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
                        Text('File d\'attente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${nurse.patients.length} patients',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AlloUrgenceTheme.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading state
              if (nurse.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Error state
              if (nurse.error != null && !nurse.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AlloUrgenceTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AlloUrgenceTheme.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(nurse.error!, style: TextStyle(color: AlloUrgenceTheme.error, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Ticket list
              if (!nurse.isLoading && nurse.error == null)
                nurse.patients.isEmpty
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
                              ticket: nurse.patients[i],
                              onTriage: () => _showTriageSheet(nurse.patients[i]),
                            ),
                          ),
                          childCount: nurse.patients.length,
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

  Widget _buildSummary(NurseProvider nurse) {
    final stats = nurse.stats!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(
            icon: Icons.people_rounded,
            label: 'Actifs',
            value: '${stats['total_active'] ?? stats['totalActive'] ?? nurse.patients.length}',
            color: AlloUrgenceTheme.primaryLight,
          )),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(
            icon: Icons.schedule_rounded,
            label: 'Attente moy.',
            value: '${stats['avg_wait'] ?? stats['averageWaitMinutes'] ?? 0} min',
            color: AlloUrgenceTheme.warning,
          )),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(
            icon: Icons.warning_rounded,
            label: 'P1-P2',
            value: '${(stats['p1_count'] ?? 0) + (stats['p2_count'] ?? 0)}',
            color: AlloUrgenceTheme.error,
          )),
        ],
      ),
    );
  }

  void _showTriageSheet(Ticket ticket) {
    int selectedPriority = ticket.effectivePriority;
    final notesController = TextEditingController();
    final roomController = TextEditingController(text: ticket.assignedRoom ?? '');
    bool isSubmitting = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                ),
                if (ticket.preTriageCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Motif: ${ticket.preTriageCategory}', style: TextStyle(color: AlloUrgenceTheme.textSecondary)),
                  ),
                const SizedBox(height: 20),

                // Priority selector
                Text('Priorité validée', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
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

                // Room assignment
                Text('Salle (optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: roomController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Salle 3, Cubicule A...',
                    filled: true,
                    fillColor: AlloUrgenceTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.meeting_room_rounded, color: AlloUrgenceTheme.textTertiary, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                Text('Justification / Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                const SizedBox(height: 8),
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
                    onPressed: isSubmitting ? null : () async {
                      setModalState(() => isSubmitting = true);
                      final nurse = context.read<NurseProvider>();
                      final success = await nurse.validateTriage(
                        ticketId: ticket.id,
                        validatedPriority: selectedPriority,
                        assignedRoom: roomController.text.isNotEmpty ? roomController.text : null,
                        justification: notesController.text.isNotEmpty ? notesController.text : null,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Triage validé — P$selectedPriority'),
                            backgroundColor: AlloUrgenceTheme.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        _loadData(); // Refresh list
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(nurse.error ?? 'Erreur lors du triage'),
                            backgroundColor: AlloUrgenceTheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AlloUrgenceTheme.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Valider le triage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertsSheet(NurseProvider nurse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            Row(
              children: [
                Icon(Icons.warning_rounded, color: AlloUrgenceTheme.error, size: 22),
                const SizedBox(width: 8),
                Text('Alertes critiques', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AlloUrgenceTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${nurse.alerts.length}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AlloUrgenceTheme.error)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nurse.alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 48, color: AlloUrgenceTheme.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('Aucune alerte', style: TextStyle(color: AlloUrgenceTheme.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: nurse.alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final alert = nurse.alerts[i];
                    final color = AlloUrgenceTheme.getPriorityColor(alert.effectivePriority);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('P${alert.effectivePriority}',
                                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert.patientFullName.isNotEmpty ? alert.patientFullName : 'Patient',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                                if (alert.preTriageCategory != null)
                                  Text(alert.preTriageCategory!, style: TextStyle(fontSize: 12, color: AlloUrgenceTheme.textSecondary)),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () async {
                                await nurse.acknowledgeAlert(alert.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Prendre en charge'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Alerts Badge ────────────────────────────────────────────────
class _AlertsBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _AlertsBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDark ? AlloUrgenceTheme.darkSurfaceVariant : AlloUrgenceTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.notifications_rounded,
              color: count > 0 ? AlloUrgenceTheme.error : (isDark ? Colors.white : AlloUrgenceTheme.textPrimary), size: 22),
          ),
          if (count > 0)
            Positioned(
              right: 4, top: 4,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: AlloUrgenceTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white, width: 2),
                ),
                child: Center(
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [AlloUrgenceTheme.cardShadow],
        border: isDark ? Border.all(color: AlloUrgenceTheme.darkDivider.withValues(alpha: 0.5)) : null,
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTriage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AlloUrgenceTheme.cardShadow],
          border: isDark ? Border.all(color: AlloUrgenceTheme.darkDivider.withValues(alpha: 0.5)) : null,
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
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
                      if (ticket.assignedRoom != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.meeting_room_rounded, size: 10, color: AlloUrgenceTheme.primaryLight),
                              const SizedBox(width: 2),
                              Text(ticket.assignedRoom!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: AlloUrgenceTheme.primaryLight)),
                            ],
                          ),
                        ),
                      ],
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
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

// ── Nurse Drawer ────────────────────────────────────────────────
class _NurseDrawer extends StatelessWidget {
  final AuthProvider auth;
  const _NurseDrawer({required this.auth});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nurse = context.watch<NurseProvider>();

    return Drawer(
      backgroundColor: isDark ? AlloUrgenceTheme.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AlloUrgenceTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AlloUrgenceTheme.coloredShadow(AlloUrgenceTheme.primaryLight)],
              ),
              child: Center(
                child: Text(
                  auth.user?.prenom.isNotEmpty == true ? auth.user!.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${auth.user?.prenom ?? ''} ${auth.user?.nom ?? ''}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
            ),
            Text(
              auth.user?.email ?? '',
              style: TextStyle(fontSize: 13, color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary),
            ),
            if (auth.user?.hospitalId != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Hôpital assigné', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AlloUrgenceTheme.primaryLight)),
              ),
            ],
            const SizedBox(height: 24),
            Divider(color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
            const SizedBox(height: 8),
            // Menu items
            _NurseDrawerItem(
              icon: Icons.dashboard_rounded,
              label: 'Tableau de bord',
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            _NurseDrawerItem(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
            ),
            _NurseDrawerItem(
              icon: Icons.settings_rounded,
              label: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            _NurseDrawerItem(
              icon: Icons.warning_rounded,
              label: 'Alertes critiques',
              badge: nurse.alerts.isNotEmpty ? '${nurse.alerts.length}' : null,
              onTap: () {
                Navigator.pop(context);
                // Find the NurseDashboardScreen state and show alerts
                final scaffoldState = context.findAncestorStateOfType<_NurseDashboardScreenState>();
                scaffoldState?._showAlertsSheet(nurse);
              },
            ),
            const Spacer(),
            Divider(color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
            _NurseDrawerItem(icon: Icons.logout_rounded, label: 'Se déconnecter', isDestructive: true,
              onTap: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NurseDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDestructive;
  final String? badge;
  final VoidCallback onTap;
  const _NurseDrawerItem({required this.icon, required this.label, this.selected = false, this.isDestructive = false, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDestructive ? AlloUrgenceTheme.error : AlloUrgenceTheme.primaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isDestructive ? AlloUrgenceTheme.error : (selected ? activeColor : (isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary))),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: TextStyle(
                  fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: isDestructive ? AlloUrgenceTheme.error : (isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                )),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AlloUrgenceTheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
