import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = context.watch<NotificationService>();
    final items = notifService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (notifService.unreadCount > 0)
            TextButton(
              onPressed: () => notifService.markAllRead(),
              child: const Text('全部已读'),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('暂无通知'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = items[index];
                IconData icon;
                Color iconColor;
                switch (n.type) {
                  case NotificationType.prepare:
                    icon = Icons.airplanemode_active;
                    iconColor = Colors.blue;
                    break;
                  case NotificationType.confirm:
                    icon = Icons.check_circle_outline;
                    iconColor = Colors.indigo;
                    break;
                  case NotificationType.followUp:
                    icon = Icons.follow_the_signs;
                    iconColor = Colors.orange;
                    break;
                  case NotificationType.reimburse:
                    icon = Icons.receipt_long;
                    iconColor = Colors.green;
                    break;
                  case NotificationType.report:
                    icon = Icons.assignment;
                    iconColor = Colors.teal;
                    break;
                  case NotificationType.reminder:
                    icon = Icons.notifications_active;
                    iconColor = Colors.red;
                    break;
                  case NotificationType.monthlySummary:
                    icon = Icons.summarize;
                    iconColor = Colors.deepPurple;
                    break;
                }
                return ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(n.message, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${n.tripDate.month}/${n.tripDate.day}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  trailing: n.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  onTap: () => notifService.markRead(index),
                );
              },
            ),
    );
  }
}
