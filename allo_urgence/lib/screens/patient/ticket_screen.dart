import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/ticket_provider.dart';
import '../../config/theme.dart';
import '../../services/socket_service.dart';

class TicketScreen extends StatefulWidget {
  final String ticketId;
  const TicketScreen({super.key, required this.ticketId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  @override
  void initState() {
    super.initState();
    _loadTicket();
    _setupSocket();
  }

  Future<void> _loadTicket() async {
    await context.read<TicketProvider>().refreshTicket();
  }

  void _setupSocket() {
    socketService.joinTicket(widget.ticketId);
    socketService.onTicketUpdate((data) {
      if (mounted) {
        context.read<TicketProvider>().updateFromSocket(data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticket = context.watch<TicketProvider>();
    final t = ticket.activeTicket;

    if (t == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon ticket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = AlloUrgenceTheme.getPriorityColor(t.effectivePriority);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon ticket'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTicket),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTicket,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority level card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Icon(AlloUrgenceTheme.getPriorityIcon(t.effectivePriority), size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(AlloUrgenceTheme.getPriorityLabel(t.effectivePriority),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Priorité ${t.effectivePriority}', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                    if (t.validatedPriority != null) ...[
                      const SizedBox(height: 4),
                      Text('✅ Validé par infirmier', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Position', value: '${t.queuePosition ?? '-'}', icon: Icons.people)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Attente estimée', value: '${t.estimatedWaitMinutes ?? '-'} min', icon: Icons.schedule)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Statut', value: t.statusLabel, icon: Icons.info_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Salle', value: t.assignedRoom ?? '-', icon: Icons.meeting_room)),
                ],
              ),
              const SizedBox(height: 24),

              // Status timeline
              _StatusTimeline(status: t.status),
              const SizedBox(height: 24),

              // QR Code
              if (t.status == 'waiting') ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      const Text('QR Code de check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Présentez ce code à votre arrivée', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: '{"ticketId":"${t.id}"}',
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Check-in button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ticket.checkIn();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Check-in effectué! ✅'), backgroundColor: AlloUrgenceTheme.success),
                        );
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Je suis arrivé (check-in)'),
                    style: ElevatedButton.styleFrom(backgroundColor: AlloUrgenceTheme.success),
                  ),
                ),
              ],

              // Share link
              if (t.sharedToken != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share, color: AlloUrgenceTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Partager avec un proche', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Code: ${t.sharedToken}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      )),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copié!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(icon, color: AlloUrgenceTheme.primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['waiting', 'checked_in', 'triage', 'in_progress', 'treated'];
    final labels = ['En attente', 'Arrivé', 'Trié', 'En cours', 'Traité'];
    final icons = [Icons.hourglass_top, Icons.login, Icons.medical_services, Icons.local_hospital, Icons.check_circle];
    final currentIndex = steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parcours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (i) {
            final done = i <= currentIndex;
            final active = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: done ? AlloUrgenceTheme.success : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: active ? Border.all(color: AlloUrgenceTheme.primaryBlue, width: 2) : null,
                    ),
                    child: Icon(icons[i], size: 18, color: done ? Colors.white : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Text(labels[i], style: TextStyle(
                    fontSize: 16,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: done ? Colors.black : Colors.grey,
                  )),
                  if (active) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AlloUrgenceTheme.primaryBlue, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Actuel', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
