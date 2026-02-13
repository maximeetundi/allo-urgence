import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
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
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final doctor = context.read<DoctorProvider>();
    final hospitalId = auth.user?.hospitalId;
    if (hospitalId != null) {
      await doctor.loadPatients(hospitalId: hospitalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = context.watch<DoctorProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _filter == 'all'
      ? doctor.patients
      : doctor.patients.where((t) => t.status == _filter).toList();

    return Scaffold(
      drawer: _DoctorDrawer(auth: auth),
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
                                '👨‍⚕️ Dr. ${auth.user?.nom ?? ''}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3,
                                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text('Gestion des patients',
                                style: TextStyle(fontSize: 14, color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary)),
                            ],
                          ),
                        ),
                        // Patient count badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${doctor.patients.length}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AlloUrgenceTheme.primaryLight),
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
                          _FilterChip(label: 'Tous', active: _filter == 'all', count: doctor.patients.length,
                            onTap: () => setState(() => _filter = 'all')),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'En attente', active: _filter == 'waiting',
                            count: doctor.patients.where((t) => t.status == 'waiting').length,
                            color: AlloUrgenceTheme.warning,
                            onTap: () => setState(() => _filter = 'waiting')),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'En triage', active: _filter == 'triage',
                            count: doctor.patients.where((t) => t.status == 'triage').length,
                            color: AlloUrgenceTheme.accent,
                            onTap: () => setState(() => _filter = 'triage')),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'En cours', active: _filter == 'in_progress',
                            count: doctor.patients.where((t) => t.status == 'in_progress').length,
                            color: AlloUrgenceTheme.success,
                            onTap: () => setState(() => _filter = 'in_progress')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Loading state
              if (doctor.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Error state
              if (doctor.error != null && !doctor.isLoading)
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
                            child: Text(doctor.error!, style: TextStyle(color: AlloUrgenceTheme.error, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Patient list
              if (!doctor.isLoading && doctor.error == null)
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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
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
                            Text('Informations médicales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                          ],
                        ),
                        if (ticket.allergies != null) ...[
                          const SizedBox(height: 8),
                          Text('Allergies: ${ticket.allergies}', style: TextStyle(fontSize: 13,
                            color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textPrimary)),
                        ],
                        if (ticket.conditionsMedicales != null) ...[
                          const SizedBox(height: 4),
                          Text('Conditions: ${ticket.conditionsMedicales}', style: TextStyle(fontSize: 13,
                            color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textPrimary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Room assignment
                if (ticket.status != 'in_progress') ...[
                  Text('Assigner une salle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roomController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Salle 3, Cubicule A...',
                      filled: true,
                      fillColor: AlloUrgenceTheme.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.meeting_room_rounded, color: AlloUrgenceTheme.textTertiary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Diagnosis
                Text('Diagnostic', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
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
                Text('Notes cliniques', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary)),
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
                    // Assign room button (only if they entered a room)
                    if (ticket.status != 'in_progress')
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting ? null : () async {
                              if (roomController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Veuillez entrer un numéro de salle'),
                                    backgroundColor: AlloUrgenceTheme.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              try {
                                final queue = context.read<QueueProvider>();
                                await queue.assignRoom(ticket.id, roomController.text);
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Salle ${roomController.text} assignée'),
                                    backgroundColor: AlloUrgenceTheme.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                _loadData();
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: AlloUrgenceTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.meeting_room_rounded, size: 18),
                            label: const Text('Assigner'),
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
                          onPressed: isSubmitting ? null : () async {
                            setModalState(() => isSubmitting = true);
                            final doctor = context.read<DoctorProvider>();

                            // Save notes first if provided
                            if (notesController.text.isNotEmpty || diagnosisController.text.isNotEmpty) {
                              final noteContent = [
                                if (diagnosisController.text.isNotEmpty) 'Diagnostic: ${diagnosisController.text}',
                                if (notesController.text.isNotEmpty) notesController.text,
                              ].join('\n\n');
                              await doctor.addNote(
                                ticketId: ticket.id,
                                content: noteContent,
                                type: 'treatment',
                              );
                            }

                            // Mark as treated
                            final success = await doctor.updatePatientStatus(ticket.id, 'treated');
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${ticket.patientFullName} marqué comme traité'),
                                  backgroundColor: AlloUrgenceTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              _loadData(); // Refresh — the treated patient will disappear from the list
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(doctor.error ?? 'Erreur lors du traitement'),
                                  backgroundColor: AlloUrgenceTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          icon: isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, size: 18),
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

                // Save notes only button (without treating)
                if (ticket.status == 'in_progress') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isSubmitting ? null : () async {
                        if (notesController.text.isEmpty && diagnosisController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Veuillez ajouter des notes ou un diagnostic'),
                              backgroundColor: AlloUrgenceTheme.warning,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        final doctor = context.read<DoctorProvider>();
                        final noteContent = [
                          if (diagnosisController.text.isNotEmpty) 'Diagnostic: ${diagnosisController.text}',
                          if (notesController.text.isNotEmpty) notesController.text,
                        ].join('\n\n');
                        final success = await doctor.addNote(
                          ticketId: ticket.id,
                          content: noteContent,
                          type: 'observation',
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Notes enregistrées' : (doctor.error ?? 'Erreur')),
                            backgroundColor: success ? AlloUrgenceTheme.success : AlloUrgenceTheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Enregistrer les notes uniquement'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AlloUrgenceTheme.primaryLight,
                        side: BorderSide(color: AlloUrgenceTheme.primaryLight.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c : (isDark ? AlloUrgenceTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: active ? null : Border.all(color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
          boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : (isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary),
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.25) : (isDark ? AlloUrgenceTheme.darkSurfaceVariant : AlloUrgenceTheme.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : (isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
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
      case 'waiting': return AlloUrgenceTheme.warning;
      case 'triage': return AlloUrgenceTheme.accent;
      case 'in_progress': return AlloUrgenceTheme.success;
      default: return AlloUrgenceTheme.textSecondary;
    }
  }
}

// ── Doctor Drawer ───────────────────────────────────────────────
class _DoctorDrawer extends StatelessWidget {
  final AuthProvider auth;
  const _DoctorDrawer({required this.auth});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AlloUrgenceTheme.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar header
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
              'Dr. ${auth.user?.nom ?? ''}',
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
            _DrawerItem(icon: Icons.people_rounded, label: 'Liste des patients', selected: true,
              onTap: () => Navigator.pop(context)),
            const Spacer(),
            Divider(color: isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
            _DrawerItem(icon: Icons.logout_rounded, label: 'Se déconnecter', isDestructive: true,
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDestructive;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, this.selected = false, this.isDestructive = false, required this.onTap});

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
              Text(label, style: TextStyle(
                fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: isDestructive ? AlloUrgenceTheme.error : (isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
              )),
            ],
          ),
        ),
      ),
    );
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
