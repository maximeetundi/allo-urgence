import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../config/theme.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final history = ticketProvider.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Historique des visites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AlloUrgenceTheme.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune visite passée',
                          style: TextStyle(fontSize: 18, color: AlloUrgenceTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final ticket = history[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HistoryCard(ticket: ticket),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic ticket;
  const _HistoryCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final color = AlloUrgenceTheme.getPriorityColor(ticket.effectivePriority);
    final treated = ticket.status == 'treated';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AlloUrgenceTheme.cardShadow],
        border: isDark ? Border.all(color: AlloUrgenceTheme.darkDivider.withOpacity(0.5)) : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'P${ticket.effectivePriority}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.hospitalName ?? 'Hôpital inconnu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.createdAt.toString().substring(0, 10),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (treated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AlloUrgenceTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Terminé',
                    style: TextStyle(color: AlloUrgenceTheme.success, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (ticket.preTriageCategory != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : AlloUrgenceTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Motif: ${ticket.preTriageCategory}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
