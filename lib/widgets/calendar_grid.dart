import 'package:flutter/material.dart';
import '../utils/calendar_utils.dart';
import '../models/travel_mark.dart';
import '../models/travel_location.dart';
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
    final cellSize = compact ? 40.0 : 48.0;
    final dayFontSize = compact ? 13.0 : 16.0;
    final headerFontSize = compact ? 12.0 : 14.0;

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
                height: 22,
                child: Center(
                  child: Text(d, style: TextStyle(fontSize: headerFontSize, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 1),
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

                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: DayCell(
                    day: day,
                    isToday: isToday,
                    marks: dayMarks,
                    locationMap: locationMap,
                    fontSize: dayFontSize,
                    onTap: onTapDay != null ? () => onTapDay!(DateTime(year, month, day)) : null,
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
