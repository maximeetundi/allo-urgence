import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/nurse_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  String _selectedFilter = 'all';
  int? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nurseProvider = Provider.of<NurseProvider>(context, listen: false);

    if (authProvider.user?.hospitalId != null) {
      nurseProvider.loadPatients(
        hospitalId: authProvider.user!.hospitalId!,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
        priority: _selectedPriority,
      );
      nurseProvider.loadAlerts(authProvider.user!.hospitalId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurseProvider = Provider.of<NurseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Infirmier'),
        actions: [
          // Alerts badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Show alerts
                  _showAlertsDialog(context);
                },
              ),
              if (nurseProvider.alerts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${nurseProvider.alerts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          if (nurseProvider.stats != null) _buildStatsCards(nurseProvider.stats!),

          // Filters
          _buildFilters(),

          // Patient List
          Expanded(
            child: nurseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : nurseProvider.patients.isEmpty
                    ? const Center(child: Text('Aucun patient'))
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        child: ListView.builder(
                          itemCount: nurseProvider.patients.length,
                          itemBuilder: (context, index) {
                            final patient = nurseProvider.patients[index];
                            return _buildPatientCard(patient);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'P1',
              stats['p1_count']?.toString() ?? '0',
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'P2',
              stats['p2_count']?.toString() ?? '0',
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'En attente',
              stats['waiting_count']?.toString() ?? '0',
              AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Tous')),
                ButtonSegment(value: 'waiting', label: Text('En attente')),
                ButtonSegment(value: 'in_progress', label: Text('En cours')),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedFilter = selection.first;
                  _loadData();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(dynamic patient) {
    final priorityColor = _getPriorityColor(patient.priorityLevel ?? 5);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'P${patient.priorityLevel ?? 5}',
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          '${patient.patientPrenom ?? ''} ${patient.patientNom ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Position: #${patient.queuePosition ?? '-'}'),
            Text('Attente: ${patient.estimatedWaitMinutes ?? '-'} min'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showTriageDialog(patient),
        ),
        onTap: () => _showPatientDetails(patient),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showTriageDialog(dynamic patient) {
    // TODO: Implement quick triage modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Triage'),
        content: const Text('Modal de triage rapide à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(dynamic patient) {
    // TODO: Implement patient details screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails Patient'),
        content: Text('Patient: ${patient.patientNom}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAlertsDialog(BuildContext context) {
    final nurseProvider = Provider.of<NurseProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alertes Critiques'),
        content: nurseProvider.alerts.isEmpty
            ? const Text('Aucune alerte')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: nurseProvider.alerts.length,
                  itemBuilder: (context, index) {
                    final alert = nurseProvider.alerts[index];
                    return ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text('${alert.patientNom}'),
                      subtitle: Text('P${alert.priorityLevel}'),
                      trailing: TextButton(
                        onPressed: () {
                          nurseProvider.acknowledgeAlert(alert.id!);
                          Navigator.pop(context);
                        },
                        child: const Text('Prendre en charge'),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
