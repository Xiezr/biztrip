import 'package:flutter/material.dart';
import '../utils/calendar_utils.dart';
import '../models/travel_mark.dart';
import '../models/travel_location.dart';
import '../services/holiday_service.dart';
import 'day_cell.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, List<TravelMark>> marksByDay;
  final Map<int, TravelLocation> locationMap;
  final void Function(DateTime)? onTapDay;
  final bool compact;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    this.marksByDay = const {},
    this.locationMap = const {},
    this.onTapDay,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final grid = CalendarUtils.buildGrid(year, month);
    final today = DateTime.now();
    final holidayService = HolidayService();
    final cellSize = compact ? 42.0 : 48.0;
    final dayFontSize = compact ? 13.0 : 15.0;
    final headerFontSize = compact ? 11.0 : 13.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 星期行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: CalendarUtils.weekDays.map((d) {
              return SizedBox(
                width: cellSize,
                height: 20,
                child: Center(
                  child: Text(d, style: TextStyle(fontSize: headerFontSize, color: Colors.grey[500], fontWeight: FontWeight.w400, letterSpacing: 1.2)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 2),
          // 日历网格
          ...List.generate(6, (row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (col) {
                final idx = row * 7 + col;
                if (idx >= grid.length) return SizedBox(width: cellSize, height: cellSize);
                final day = grid[idx];
                if (day == null) return SizedBox(width: cellSize, height: cellSize);

                final dayMarks = marksByDay[day] ?? [];
                final isToday = day == today.day && month == today.month && year == today.year;
                final date = DateTime(year, month, day);
                final isHoliday = holidayService.isHoliday(date);

                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: DayCell(
                    day: day,
                    isToday: isToday,
                    isHoliday: isHoliday,
                    marks: dayMarks,
                    locationMap: locationMap,
                    fontSize: dayFontSize,
                    onTap: onTapDay != null ? () => onTapDay!(date) : null,
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
