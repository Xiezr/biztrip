class CalendarUtils {
  static const weekDays = ['日', '一', '二', '三', '四', '五', '六'];

  /// 水平滑动切换月份/年份的最小速度阈值 (px/s)
  static const double swipeThreshold = 200.0;

  /// 某月的天数
  static int daysInMonth(int year, int month) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  }

  /// 某月1号是星期几 (0=周日)
  static int firstWeekday(int year, int month) {
    return DateTime(year, month, 1).weekday % 7;
  }

  /// 生成日历网格数据 List of int?，null = 空白占位
  static List<int?> buildGrid(int year, int month) {
    final days = daysInMonth(year, month);
    final start = firstWeekday(year, month);
    final grid = <int?>[];
    // 前面空白
    for (int i = 0; i < start; i++) {
      grid.add(null);
    }
    // 日期
    for (int i = 1; i <= days; i++) {
      grid.add(i);
    }
    // 补齐42格 (6行×7列)
    while (grid.length < 42) {
      grid.add(null);
    }
    return grid;
  }

  /// 中文月份名
  static String monthName(int month) {
    return ['一月', '二月', '三月', '四月', '五月', '六月',
            '七月', '八月', '九月', '十月', '十一月', '十二月'][month - 1];
  }
}
