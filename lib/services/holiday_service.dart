/// 中国法定节假日服务
/// 硬编码 2025-2026 数据，包含假期日期范围和调休补班日期。
/// 判断逻辑：周末默认休息，但调休补班日视为工作日。
class HolidayService {
  // 私有构造，单例
  HolidayService._();
  static final HolidayService _instance = HolidayService._();
  factory HolidayService() => _instance;

  // ─── 假期日期范围 ───
  // key: 年份, value: List<(开始, 结束)>
  static final Map<int, List<_DateRange>> _holidays = {
    2025: [
      _DateRange(DateTime(2025, 1, 1),   DateTime(2025, 1, 1)),    // 元旦 1天
      _DateRange(DateTime(2025, 1, 28),  DateTime(2025, 2, 4)),    // 春节 8天
      _DateRange(DateTime(2025, 4, 4),   DateTime(2025, 4, 6)),    // 清明 3天
      _DateRange(DateTime(2025, 5, 1),   DateTime(2025, 5, 5)),    // 劳动节 5天
      _DateRange(DateTime(2025, 5, 31),  DateTime(2025, 6, 2)),    // 端午 3天
      _DateRange(DateTime(2025, 10, 1),  DateTime(2025, 10, 8)),   // 国庆+中秋 8天
    ],
    2026: [
      _DateRange(DateTime(2026, 1, 1),   DateTime(2026, 1, 3)),    // 元旦 3天
      _DateRange(DateTime(2026, 2, 15),  DateTime(2026, 2, 23)),   // 春节 9天
      _DateRange(DateTime(2026, 4, 4),   DateTime(2026, 4, 6)),    // 清明 3天
      _DateRange(DateTime(2026, 5, 1),   DateTime(2026, 5, 5)),    // 劳动节 5天
      _DateRange(DateTime(2026, 6, 19),  DateTime(2026, 6, 21)),   // 端午 3天
      _DateRange(DateTime(2026, 9, 25),  DateTime(2026, 9, 27)),   // 中秋 3天
      _DateRange(DateTime(2026, 10, 1),  DateTime(2026, 10, 7)),   // 国庆 7天
    ],
  };

  // ─── 调休补班日期（周末但必须上班） ───
  static final Set<DateTime> _workdays = {
    // 2025
    DateTime(2025, 1, 26),   // 春节补班（周日）
    DateTime(2025, 2, 8),    // 春节补班（周六）
    DateTime(2025, 4, 27),   // 劳动节补班（周日）
    DateTime(2025, 9, 28),   // 国庆补班（周日）
    DateTime(2025, 10, 11),  // 国庆补班（周六）
    // 2026
    DateTime(2026, 1, 4),    // 元旦补班（周日）
    DateTime(2026, 2, 14),   // 春节补班（周六）
    DateTime(2026, 2, 28),   // 春节补班（周六）
    DateTime(2026, 5, 9),    // 劳动节补班（周六）
    DateTime(2026, 9, 20),   // 国庆补班（周日）
    DateTime(2026, 10, 10),  // 国庆补班（周六）
  };

  /// 判断某天是否为休息日（法定节假日 + 周末，扣除调休补班）
  bool isHoliday(DateTime date) {
    final d = _dateOnly(date);

    // 1. 调休补班日 → 工作日，不是休息日
    if (_workdays.contains(d)) return false;

    // 2. 法定节假日范围内 → 休息日
    final list = _holidays[d.year];
    if (list != null) {
      for (final range in list) {
        if (!d.isBefore(range.start) && !d.isAfter(range.end)) return true;
      }
    }

    // 3. 周末 → 休息日
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) return true;

    return false;
  }

  /// 判断某天是否为工作日
  bool isWorkday(DateTime date) => !isHoliday(date);

  /// 去掉时分秒，只保留日期
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

/// 内部日期范围
class _DateRange {
  final DateTime start;
  final DateTime end;
  const _DateRange(this.start, this.end);
}
