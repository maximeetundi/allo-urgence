import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'patient_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<dynamic> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await apiService.get('/notifications');
      if (mounted) {
        setState(() {
          _notifications = data['notifications'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les notifications';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: isDark ? AlloUrgenceTheme.darkBackground : AlloUrgenceTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      drawer: PatientDrawer(
        auth: auth,
        onTabSelected: (index) {
          Navigator.pop(context); // Close drawer
          Navigator.pop(context, index); // Return to main screen with selected tab index
        },
        selectedIndex: -1, // No tab selected in notifications
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AlloUrgenceTheme.error)))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LineIcons.bellSlash, size: 64, color: AlloUrgenceTheme.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune activité récente',
                            style: TextStyle(fontSize: 18, color: AlloUrgenceTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _NotificationCard(notification: _notifications[index]);
                      },
                    ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconName = notification['icon'] as String?;
    
    IconData iconData = Icons.info_outline;
    Color iconColor = AlloUrgenceTheme.primaryLight;

    switch (iconName) {
      case 'ticket':
        iconData = LineIcons.medicalNotes;
        iconColor = AlloUrgenceTheme.primaryLight;
        break;
      case 'triage':
        iconData = LineIcons.stethoscope;
        iconColor = AlloUrgenceTheme.warning;
        break;
      case 'doctor':
        iconData = LineIcons.doctor;
        iconColor = AlloUrgenceTheme.success;
        break;
      case 'profile':
        iconData = LineIcons.userEdit;
        iconColor = AlloUrgenceTheme.accent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AlloUrgenceTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AlloUrgenceTheme.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'Notification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(notification['created_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
