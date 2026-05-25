import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

enum NotificationType { prepare, confirm, followUp, reimburse, report, reminder, monthlySummary }

class NotificationService extends ChangeNotifier {
  List<TripNotification> _notifications = [];
  DateTime? _lastEvalDate;
  List<TravelMark>? _lastMarks;
  Map<int, TravelLocation>? _lastLocationMap;

  List<TripNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 月末汇总通知：根据出差天数分级
  static String monthlySummaryMessage(int totalDays) {
    if (totalDays <= 0) return '';
    if (totalDays <= 3) {
      return '您本月出差共 $totalDays 天，一切尽在掌握 📋';
    } else if (totalDays <= 7) {
      return '您本月出差共 $totalDays 天，奔波不少，好好休息 ☕';
    } else if (totalDays <= 14) {
      return '您本月出差共 $totalDays 天，已是半个常旅客了，记得多写点工时 ✈️';
    } else {
      return '您本月出差共 $totalDays 天，以路为家，身体要紧！差旅费记得报销 🏨';
    }
  }

  /// 增量计算：仅当天日期变化或数据变化时才重算
  void evaluate({
    required List<TravelMark> marks,
    required Map<int, TravelLocation> locationMap,
  }) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 增量判断
    final marksUnchanged = identical(_lastMarks, marks);
    final mapUnchanged = identical(_lastLocationMap, locationMap);
    if (_lastEvalDate != null &&
        _lastEvalDate == todayDate &&
        marksUnchanged &&
        mapUnchanged) {
      return;
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
        final reminderCount = loc.specialReminder.where((s) => s.trim().isNotEmpty).length;
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.prepare,
          message: '${loc.name}差旅计划距今$diff天，请确认提醒事项$reminderCount项完成',
        ));
      }

      // 差旅确认（提前N天）
      if (diff > 0 && diff <= loc.confirmationDaysBefore) {
        final reminderCount = loc.specialReminder.where((s) => s.trim().isNotEmpty).length;
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.confirm,
          message: '${loc.name}差旅计划距今$diff天，请确认提醒事项$reminderCount项完成',
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
        final reminderCount = loc.specialReminder.where((s) => s.trim().isNotEmpty).length;
        newNotifications.add(TripNotification(
          locationId: loc.id!,
          locationName: loc.name,
          tripDate: mark.date,
          type: NotificationType.followUp,
          message: '${loc.name}差旅已过去${diff.abs()}天，请确认提醒事项$reminderCount项完成',
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

    // ===== 月末汇总通知 =====
    final lastDay = DateTime(today.year, today.month + 1, 0);
    if (todayDate == lastDay) {
      // 统计当月所有出差天数（去重：同一天不同目的地算1天）
      final monthMarks = marks.where((m) =>
        m.date.year == today.year && m.date.month == today.month
      ).toList();
      final travelDays = monthMarks.map((m) => m.date).toSet().length;

      final summaryMsg = monthlySummaryMessage(travelDays);
      if (summaryMsg.isNotEmpty) {
        newNotifications.add(TripNotification(
          locationId: -1,  // 特殊 ID：汇总通知，不属于任何目的地
          locationName: '系统',
          tripDate: todayDate,
          type: NotificationType.monthlySummary,
          message: summaryMsg,
        ));
      }
    }

    newNotifications.sort((a, b) => a.tripDate.compareTo(b.tripDate));
    _notifications = newNotifications;
    notifyListeners();

    // 推送到系统通知栏（仅推送当天相关的新通知）
    _pushToSystem(newNotifications);
  }

  /// 将通知推送到 Android 系统通知栏
  Future<void> _pushToSystem(List<TripNotification> notifications) async {
    const platform = MethodChannel('com.biztrip.biztrip/notification');
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final n in notifications) {
      // 仅推当天相关通知（出发当天提醒、月末汇总）；其余通知在应用内查看即可
      final isTodayReminder = n.type == NotificationType.reminder && n.tripDate == todayDate;
      final isMonthlySummary = n.type == NotificationType.monthlySummary;
      if (!isTodayReminder && !isMonthlySummary) continue;

      // 按 type 排序编号，确保同类型通知覆盖而非累积
      final typeIndex = NotificationType.values.indexOf(n.type);
      final notificationId = n.locationId * 10 + typeIndex;

      try {
        await platform.invokeMethod('showNotification', {
          'id': notificationId,
          'title': _typeTitle(n.type),
          'body': n.message,
          'summary': 'Biztrip 差旅提醒',
        });
      } catch (_) {
        // 通知推送失败不阻塞主流程
      }
    }
  }

  static String _typeTitle(NotificationType type) {
    switch (type) {
      case NotificationType.prepare: return '差旅准备';
      case NotificationType.confirm: return '差旅确认';
      case NotificationType.followUp: return '差旅跟进';
      case NotificationType.reimburse: return '票据报销';
      case NotificationType.report: return '差旅报告';
      case NotificationType.reminder: return '今天出发';
      case NotificationType.monthlySummary: return '月末汇总';
    }
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
