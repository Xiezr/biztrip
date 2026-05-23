import 'package:flutter/foundation.dart';
import '../models/travel_mark.dart';
import '../models/travel_location.dart';

class TripNotification {
  final int locationId;
  final String locationName;
  final DateTime tripDate;
  final NotificationType type;
  final String message;
  final bool isRead;

  const TripNotification({
    required this.locationId,
    required this.locationName,
    required this.tripDate,
    required this.type,
    required this.message,
    this.isRead = false,
  });

  TripNotification copyWith({bool? isRead}) =>
      TripNotification(locationId: locationId, locationName: locationName, tripDate: tripDate, type: type, message: message, isRead: isRead ?? this.isRead);
}

enum NotificationType { prepare, confirm, followUp, reimburse, report, reminder }

class NotificationService extends ChangeNotifier {
  List<TripNotification> _notifications = [];

  List<TripNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void evaluate({
    required List<TravelMark> marks,
    required Map<int, TravelLocation> locationMap,
  }) {
    _notifications.clear();
    final today = DateTime.now();

    for (final mark in marks) {
      final loc = locationMap[mark.locationId];
      if (loc == null) continue;

      final diff = mark.date.difference(today).inDays;
      final reminderText = loc.specialReminder.where((s) => s.trim().isNotEmpty).join('\n');

      // 差旅通知（提前N天）
      if (diff > 0 && diff <= loc.notificationDaysBefore) {
        _notifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.prepare,
          message: '【${loc.name}】-${loc.notificationDaysBefore}天通知（第${loc.notificationDaysBefore - diff + 1}天）',
        ));
      }

      // 差旅确认（提前N天）
      if (diff > 0 && diff <= loc.confirmationDaysBefore) {
        _notifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.confirm,
          message: '【${loc.name}】请确认差旅安排（-${loc.confirmationDaysBefore}天）',
        ));
      }

      // 当天
      if (diff == 0) {
        _notifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.reminder,
          message: '今天去【${loc.name}】\n${reminderText.isNotEmpty ? reminderText : ""}',
        ));
      }

      // 差旅跟进（结束后N天内）
      if (diff < 0 && diff.abs() <= loc.followUpDaysAfter) {
        _notifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.followUp,
          message: '【${loc.name}】+${diff.abs()}天跟进',
        ));
      }

      // 票据报销（结束后N天内）
      if (diff < 0 && diff.abs() <= loc.reimbursementDaysAfter) {
        _notifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.reimburse,
          message: '【${loc.name}】请在${loc.reimbursementDaysAfter - diff.abs()}天内完成报销（+${loc.reimbursementDaysAfter}天截止）',
        ));
      }

      // 差旅报告（结束后N天内）
      if (diff < 0 && diff.abs() <= loc.reportDaysAfter) {
        _notifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.report,
          message: '【${loc.name}】请提交差旅报告（+${loc.reportDaysAfter}天截止）',
        ));
      }
    }

    _notifications.sort((a, b) => a.tripDate.compareTo(b.tripDate));
    notifyListeners();
  }

  void markAllRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void markRead(int index) {
    if (index < _notifications.length) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }
}
