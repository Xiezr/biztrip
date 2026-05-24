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
  DateTime? _lastEvalDate; // 增量计算：仅日期变化时重算
  List<TravelMark>? _lastMarks;
  Map<int, TravelLocation>? _lastLocationMap;

  List<TripNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 增量计算：仅当天日期变化或数据变化时才重算
  void evaluate({
    required List<TravelMark> marks,
    required Map<int, TravelLocation> locationMap,
  }) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 增量判断：日期未变且数据引用未变，跳过计算
    final marksUnchanged = identical(_lastMarks, marks);
    final mapUnchanged = identical(_lastLocationMap, locationMap);
    if (_lastEvalDate != null &&
        _lastEvalDate == todayDate &&
        marksUnchanged &&
        mapUnchanged) {
      return; // 无变化，直接返回缓存
    }

    _lastEvalDate = todayDate;
    _lastMarks = marks;
    _lastLocationMap = locationMap;

    final newNotifications = <TripNotification>[];

    for (final mark in marks) {
      final loc = locationMap[mark.locationId];
      if (loc == null) continue;

      final diff = mark.date.difference(todayDate).inDays;
      final reminderText = loc.specialReminder.where((s) => s.trim().isNotEmpty).join('\n');

      // 差旅通知（提前N天）
      if (diff > 0 && diff <= loc.notificationDaysBefore) {
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.prepare,
          message: '【${loc.name}】-${loc.notificationDaysBefore}天通知（第${loc.notificationDaysBefore - diff + 1}天）',
        ));
      }

      // 差旅确认（提前N天）
      if (diff > 0 && diff <= loc.confirmationDaysBefore) {
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.confirm,
          message: '【${loc.name}】请确认差旅安排（-${loc.confirmationDaysBefore}天）',
        ));
      }

      // 当天
      if (diff == 0) {
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.reminder,
          message: '今天去【${loc.name}】\n${reminderText.isNotEmpty ? reminderText : ""}',
        ));
      }

      // 差旅跟进（结束后N天内）
      if (diff < 0 && diff.abs() <= loc.followUpDaysAfter) {
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.followUp,
          message: '【${loc.name}】+${diff.abs()}天跟进',
        ));
      }

      // 票据报销（结束后N天内）
      if (diff < 0 && diff.abs() <= loc.reimbursementDaysAfter) {
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.reimburse,
          message: '【${loc.name}】请在${loc.reimbursementDaysAfter - diff.abs()}天内完成报销（+${loc.reimbursementDaysAfter}天截止）',
        ));
      }

      // 差旅报告（结束后N天内）
      if (diff < 0 && diff.abs() <= loc.reportDaysAfter) {
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.report,
          message: '【${loc.name}】请提交差旅报告（+${loc.reportDaysAfter}天截止）',
        ));
      }
    }

    newNotifications.sort((a, b) => a.tripDate.compareTo(b.tripDate));
    _notifications = newNotifications;
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
