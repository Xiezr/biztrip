import 'package:flutter/foundation.dart';
import '../models/travel_mark.dart';
import '../database/storage_service.dart';

class MarkProvider extends ChangeNotifier {
  List<TravelMark> _marks = [];
  int _nextId = 1;
  final StorageService _storage = StorageService();

  List<TravelMark> get marks => List.unmodifiable(_marks);

  Future<void> load() async {
    _marks = await _storage.loadMarks();
    _nextId = _marks.fold(0, (max, m) => m.id != null && m.id! > max ? m.id! : max) + 1;
    notifyListeners();
  }

  /// 获取某天的所有标记
  List<TravelMark> getMarksForDate(DateTime date) {
    final d = _normalizeDate(date);
    return _marks.where((m) => _normalizeDate(m.date) == d).toList();
  }

  /// 获取某月的所有标记，按日聚合
  Map<int, List<TravelMark>> getMarksForMonth(int year, int month) {
    final result = <int, List<TravelMark>>{};
    for (final m in _marks) {
      if (m.date.year == year && m.date.month == month) {
        result.putIfAbsent(m.date.day, () => []).add(m);
      }
    }
    return result;
  }

  /// 获取某月的差旅天数（有标记的天数，可选过滤有效目的地）
  int getTravelDaysForMonth(int year, int month, {Set<int>? validLocationIds}) {
    final days = <int>{};
    for (final m in _marks) {
      if (m.date.year == year && m.date.month == month) {
        if (validLocationIds == null || validLocationIds.contains(m.locationId)) {
          days.add(m.date.day);
        }
      }
    }
    return days.length;
  }

  /// 检查某天是否有指定地点的标记
  bool hasMark(int locationId, DateTime date) {
    final d = _normalizeDate(date);
    return _marks.any((m) => m.locationId == locationId && _normalizeDate(m.date) == d);
  }

  /// 获取指定地点最近一次差旅日期（在给定日期之前）
  DateTime? getLastMarkDate(int locationId, DateTime beforeDate) {
    final before = _normalizeDate(beforeDate);
    DateTime? last;
    for (final m in _marks) {
      if (m.locationId == locationId && _normalizeDate(m.date).isBefore(before)) {
        if (last == null || m.date.isAfter(last)) {
          last = m.date;
        }
      }
    }
    return last;
  }

  /// 添加/切换标记（已有则删除，没有则添加，每天最多2个）
  Future<void> toggleMark(int locationId, DateTime date) async {
    final d = _normalizeDate(date);
    final existing = _marks.where(
      (m) => m.locationId == locationId && _normalizeDate(m.date) == d,
    ).toList();

    if (existing.isNotEmpty) {
      // 已有此地点标记 → 删除
      _marks.removeWhere((m) => existing.contains(m));
    } else {
      // 检查当天是否已有2个标记
      final dayMarks = _marks.where((m) => _normalizeDate(m.date) == d).toList();
      if (dayMarks.length >= 2) return; // 最多2个
      _marks.add(TravelMark(id: _nextId++, locationId: locationId, date: d));
    }
    notifyListeners();
    await _storage.saveMarks(_marks);
  }

  /// 删除某天指定地点的所有标记
  Future<void> removeMarksForDate(int locationId, DateTime date) async {
    final d = _normalizeDate(date);
    _marks.removeWhere((m) => m.locationId == locationId && _normalizeDate(m.date) == d);
    notifyListeners();
    await _storage.saveMarks(_marks);
  }

  /// 删除指定地点的所有标记（永久删除时使用）
  Future<void> removeMarksByLocation(int locationId) async {
    _marks.removeWhere((m) => m.locationId == locationId);
    notifyListeners();
    await _storage.saveMarks(_marks);
  }

  DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
