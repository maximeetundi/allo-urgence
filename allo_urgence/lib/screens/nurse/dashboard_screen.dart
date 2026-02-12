import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../config/theme.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../models/hospital.dart';
import '../auth/login_screen.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final data = await apiService.get('/hospitals');
      setState(() {
        _hospitals = (data['hospitals'] as List).map((h) => Hospital.fromJson(h)).toList();
        if (_hospitals.isNotEmpty) {
          _selectedHospital = _hospitals.first;
          _loadQueue();
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadQueue() async {
    if (_selectedHospital == null) return;
    final queue = context.read<QueueProvider>();
    await queue.loadQueue(_selectedHospital!.id);

    // Setup socket
    socketService.joinHospital(_selectedHospital!.id);
    socketService.onQueueUpdate((data) {
      if (mounted) _loadQueue();
    });
    socketService.onNewTicket((data) {
      if (mounted) _loadQueue();
    });
    socketService.onCriticalAlert((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 ALERTE : Patient priorité ${data['priority']} !'),
            backgroundColor: AlloUrgenceTheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Infirmier'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQueue),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Hospital selector
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AlloUrgenceTheme.primaryBlue.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital, color: AlloUrgenceTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedHospital?.id,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _hospitals.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))).toList(),
                          onChanged: (id) {
                            setState(() => _selectedHospital = _hospitals.firstWhere((h) => h.id == id));
                            _loadQueue();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _miniStat('Total', '${queue.summary['totalActive'] ?? 0}', AlloUrgenceTheme.primaryBlue),
                      _miniStat('Attente', '${queue.summary['averageWaitMinutes'] ?? 0} min', AlloUrgenceTheme.warning),
                      _miniStat('P1-P2', '${((queue.summary['byPriority'] as Map?)?.entries.where((e) => int.tryParse(e.key.toString()) != null && int.parse(e.key.toString()) <= 2).fold(0, (sum, e) => sum + (e.value as int)) ?? 0)}', AlloUrgenceTheme.error),
                    ],
                  ),
                ),

                // Patient list
                Expanded(
                  child: queue.loading
                      ? const Center(child: CircularProgressIndicator())
                      : queue.tickets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text('Aucun patient en attente', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: queue.tickets.length,
                              itemBuilder: (_, i) => _PatientCard(
                                ticket: queue.tickets[i],
                                onTriage: () => _showTriageDialog(queue.tickets[i]),
                                onAssignRoom: () => _showRoomDialog(queue.tickets[i]),
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  void _showTriageDialog(Ticket ticket) {
    int priority = ticket.effectivePriority;
    final notesC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Triage — ${ticket.patientFullName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Pré-triage: P${ticket.priorityLevel}', style: TextStyle(color: Colors.grey[600])),
              if (ticket.allergies != null && ticket.allergies!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('⚠️ Allergies: ${ticket.allergies}', style: const TextStyle(color: AlloUrgenceTheme.error)),
              ],
              const SizedBox(height: 16),
              const Text('Priorité validée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final p = i + 1;
                  final color = AlloUrgenceTheme.getPriorityColor(p);
                  return GestureDetector(
                    onTap: () => setSheetState(() => priority = p),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: priority == p ? color : color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: priority == p ? Border.all(color: color, width: 3) : null,
                      ),
                      child: Center(child: Text('P$p',
                        style: TextStyle(
                          color: priority == p ? Colors.white : color,
                          fontWeight: FontWeight.bold, fontSize: 18,
                        ),
                      )),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesC,
                decoration: const InputDecoration(labelText: 'Notes de triage', hintText: 'Observations...'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final queue = context.read<QueueProvider>();
                    await queue.triageTicket(ticket.id, priority, notesC.text.isEmpty ? null : notesC.text);
                    await queue.loadQueue(_selectedHospital!.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('✅ Valider le triage'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDialog(Ticket ticket) {
    final roomC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assigner salle — ${ticket.patientFullName}'),
        content: TextField(
          controller: roomC,
          decoration: const InputDecoration(labelText: 'Numéro de salle', hintText: 'Ex: A-12'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (roomC.text.isEmpty) return;
              final queue = context.read<QueueProvider>();
              await queue.assignRoom(ticket.id, roomC.text);
              await queue.loadQueue(_selectedHospital!.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Assigner'),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTriage;
  final VoidCallback onAssignRoom;

  const _PatientCard({required this.ticket, required this.onTriage, required this.onAssignRoom});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority);
    final isCheckedIn = ticket.status == 'checked_in';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCheckedIn ? BorderSide(color: AlloUrgenceTheme.success, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority badge
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('P${ticket.effectivePriority}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.patientFullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          if (isCheckedIn) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AlloUrgenceTheme.success, borderRadius: BorderRadius.circular(4)),
                              child: const Text('ARRIVÉ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(ticket.statusLabel, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          if (ticket.assignedRoom != null) ...[
                            Text(' • Salle ${ticket.assignedRoom}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text('#${ticket.queuePosition ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            if (ticket.allergies != null && ticket.allergies!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text('⚠️ ${ticket.allergies}', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (ticket.status == 'waiting' || ticket.status == 'checked_in')
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onTriage,
                        icon: const Icon(Icons.medical_services, size: 18),
                        label: const Text('Triage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlloUrgenceTheme.primaryBlue,
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                if (ticket.status == 'triage') ...[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onAssignRoom,
                        icon: const Icon(Icons.meeting_room, size: 18),
                        label: const Text('Assigner salle'),
                        style: ElevatedButton.styleFrom(backgroundColor: AlloUrgenceTheme.accent),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
