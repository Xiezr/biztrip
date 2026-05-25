import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_container.dart';
import '../services/notification_service.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = context.read<NotificationService>();
    final items = notifService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (notifService.unreadCount > 0)
            TextButton(
              onPressed: () => notifService.markAllRead(),
              child: const Text('全部已读', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(child: Text('暂无通知', style: TextStyle(color: clayTextTertiary)))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
              itemBuilder: (context, index) {
                final n = items[index];
                IconData icon;
                Color iconColor;
                switch (n.type) {
                  case NotificationType.prepare:
                    icon = Icons.airplanemode_active;
                    iconColor = clayPurple;
                    break;
                  case NotificationType.confirm:
                    icon = Icons.check_circle_outline;
                    iconColor = clayPurpleDark; // deep purple
                    break;
                  case NotificationType.followUp:
                    icon = Icons.follow_the_signs;
                    iconColor = clayWarning; // warm amber
                    break;
                  case NotificationType.reimburse:
                    icon = Icons.receipt_long;
                    iconColor = claySuccess; // soft green
                    break;
                  case NotificationType.report:
                    icon = Icons.assignment;
                    iconColor = clayTeal; // teal — unique for reports
                    break;
                  case NotificationType.reminder:
                    icon = Icons.notifications_active;
                    iconColor = clayError; // soft red
                    break;
                  case NotificationType.monthlySummary:
                    icon = Icons.summarize;
                    iconColor = clayPurpleDark;
                    break;
                }
                return ClayCard(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.message,
                              style: TextStyle(
                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                                fontSize: 13,
                                color: clayTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${n.tripDate.month}/${n.tripDate.day}',
                              style: TextStyle(color: clayTextTertiary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: clayPurple, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
