import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../config/theme.dart';
import '../../services/socket_service.dart';
import '../auth/login_screen.dart';
import 'pre_triage_screen.dart';
import 'ticket_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allo Urgence'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome
              Text(
                'Bonjour, ${auth.user?.prenom ?? ''} 👋',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Comment pouvons-nous vous aider ?',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Active ticket
              if (ticket.activeTicket != null) ...[
                _ActiveTicketCard(ticket: ticket),
                const SizedBox(height: 24),
              ],

              // Main action
              if (ticket.activeTicket == null)
                _EmergencyButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PreTriageScreen()),
                  ),
                ),

              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: AlloUrgenceTheme.primaryBlue, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Comment ça fonctionne ?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _infoStep('1', 'Répondez au pré‑triage (30 sec)'),
                    _infoStep('2', 'Obtenez votre ticket et temps estimé'),
                    _infoStep('3', 'Rendez-vous à l\'hôpital au bon moment'),
                    _infoStep('4', 'Passez au triage avec l\'infirmier'),
                    const SizedBox(height: 12),
                    Text(
                      '⚠️ L\'application ne remplace pas le jugement clinique.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // History
              if (ticket.history.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text('Historique', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...ticket.history.take(5).map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AlloUrgenceTheme.getPriorityColor(t.effectivePriority).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('P${t.effectivePriority}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AlloUrgenceTheme.getPriorityColor(t.effectivePriority)),
                        ),
                      ),
                    ),
                    title: Text(t.statusLabel),
                    subtitle: Text(t.createdAt.substring(0, 10)),
                    trailing: Icon(
                      t.status == 'treated' ? Icons.check_circle : Icons.schedule,
                      color: t.status == 'treated' ? AlloUrgenceTheme.success : Colors.grey,
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AlloUrgenceTheme.primaryBlue, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EmergencyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AlloUrgenceTheme.primaryBlue, Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AlloUrgenceTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(36)),
              child: const Icon(Icons.add_circle_outline, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Déclarer une urgence', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Commencer le pré‑triage', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }
}

class _ActiveTicketCard extends StatelessWidget {
  final TicketProvider ticket;
  const _ActiveTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket.activeTicket!;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketScreen(ticketId: t.id))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AlloUrgenceTheme.getPriorityColor(t.effectivePriority).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AlloUrgenceTheme.getPriorityColor(t.effectivePriority).withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🎫 Ticket actif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AlloUrgenceTheme.getPriorityColor(t.effectivePriority),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AlloUrgenceTheme.getPriorityLabel(t.effectivePriority),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Position', '${t.queuePosition ?? '-'}'),
                _stat('Attente', '${t.estimatedWaitMinutes ?? '-'} min'),
                _stat('Statut', t.statusLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text('Appuyez pour voir les détails →', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}
