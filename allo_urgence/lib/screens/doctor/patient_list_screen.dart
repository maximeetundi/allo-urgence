import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../config/theme.dart';
import '../../models/ticket.dart';
import '../../models/hospital.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../auth/login_screen.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
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
    await context.read<QueueProvider>().loadQueue(_selectedHospital!.id);
    socketService.joinHospital(_selectedHospital!.id);
    socketService.onQueueUpdate((_) { if (mounted) _loadQueue(); });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<QueueProvider>();

    // Filter to triaged + in_progress patients
    final managedTickets = queue.tickets.where((t) =>
      t.status == 'triage' || t.status == 'in_progress'
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients assignés'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQueue),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await auth.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
            );
          }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Hospital selector
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.indigo.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.indigo),
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
                Expanded(
                  child: queue.loading
                      ? const Center(child: CircularProgressIndicator())
                      : managedTickets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_off, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text('Aucun patient en attente de consultation', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: managedTickets.length,
                              itemBuilder: (_, i) => _DoctorPatientCard(
                                ticket: managedTickets[i],
                                onTreat: () => _showTreatDialog(managedTickets[i]),
                                onNote: () => _showNoteDialog(managedTickets[i]),
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  void _showTreatDialog(Ticket ticket) {
    final notesC = TextEditingController();
    final diagC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Traitement — ${ticket.patientFullName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: diagC, decoration: const InputDecoration(labelText: 'Diagnostic'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: notesC, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final queue = context.read<QueueProvider>();
                  await queue.treatPatient(ticket.id, notes: notesC.text, diagnosis: diagC.text);
                  await queue.loadQueue(_selectedHospital!.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AlloUrgenceTheme.success),
                child: const Text('✅ Marquer comme traité'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(Ticket ticket) {
    final notesC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une note'),
        content: TextField(controller: notesC, decoration: const InputDecoration(hintText: 'Notes...'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () async {
            final queue = context.read<QueueProvider>();
            await queue.addDoctorNote(ticket.id, notesC.text, null);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}

class _DoctorPatientCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTreat;
  final VoidCallback onNote;

  const _DoctorPatientCard({required this.ticket, required this.onTreat, required this.onNote});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('P${ticket.effectivePriority}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.patientFullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text('${ticket.statusLabel}${ticket.assignedRoom != null ? ' • Salle ${ticket.assignedRoom}' : ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                )),
              ],
            ),
            if (ticket.allergies != null && ticket.allergies!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('⚠️ Allergies: ${ticket.allergies}', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ],
            if (ticket.conditionsMedicales != null && ticket.conditionsMedicales!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📋 Conditions: ${ticket.conditionsMedicales}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 44, child: OutlinedButton.icon(
                    onPressed: onNote,
                    icon: const Icon(Icons.note_add, size: 18),
                    label: const Text('Note'),
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(height: 44, child: ElevatedButton.icon(
                    onPressed: onTreat,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Traiter'),
                    style: ElevatedButton.styleFrom(backgroundColor: AlloUrgenceTheme.success),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
