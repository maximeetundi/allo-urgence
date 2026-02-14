import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dummy data
    final notifications = [
      _NotificationItem(
        title: 'Nouveau patient critique',
        body: 'Un patient P1 arrive à l\'urgence.',
        time: 'Il y a 2 min',
        isUnread: true,
        type: 'critical',
      ),
      _NotificationItem(
        title: 'Triage nécessaire',
        body: '3 patients en attente de triage.',
        time: 'Il y a 15 min',
        isUnread: true,
        type: 'info',
      ),
      _NotificationItem(
        title: 'Changement de quart',
        body: 'N\'oubliez pas de signer votre rapport.',
        time: 'Il y a 1h',
        isUnread: false,
        type: 'system',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () {},
            tooltip: 'Tout marquer comme lu',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => notifications[index],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isUnread;
  final String type;

  const _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color iconColor;
    IconData iconData;
    
    switch (type) {
      case 'critical':
        iconColor = AlloUrgenceTheme.error;
        iconData = Icons.warning_rounded;
        break;
      case 'info':
        iconColor = AlloUrgenceTheme.primaryLight;
        iconData = Icons.info_rounded;
        break;
      default:
        iconColor = AlloUrgenceTheme.textTertiary;
        iconData = Icons.notifications_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread 
            ? (isDark ? AlloUrgenceTheme.darkSurfaceVariant.withValues(alpha: 0.5) : AlloUrgenceTheme.primaryLight.withValues(alpha: 0.05))
            : (isDark ? AlloUrgenceTheme.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread 
              ? AlloUrgenceTheme.primaryLight.withValues(alpha: 0.2)
              : (isDark ? AlloUrgenceTheme.darkDivider : AlloUrgenceTheme.divider),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? Colors.white : AlloUrgenceTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AlloUrgenceTheme.darkTextTertiary : AlloUrgenceTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AlloUrgenceTheme.darkTextSecondary : AlloUrgenceTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AlloUrgenceTheme.primaryLight,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
