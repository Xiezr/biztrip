import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/mark_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/calendar_grid.dart';
import '../utils/calendar_utils.dart';
import '../models/travel_mark.dart';
import '../models/travel_location.dart';

class TwoMonthView extends StatelessWidget {
  const TwoMonthView({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final markProvider = context.watch<MarkProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final year = calendarProvider.year;
    final month = calendarProvider.month;
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;

    final locationMap = {for (final l in locationProvider.locations) l.id!: l};

    return Column(
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  calendarProvider.goToPreviousMonth();
                  calendarProvider.goToPreviousMonth();
                },
              ),
              Text(
                '${CalendarUtils.monthName(month)} / ${CalendarUtils.monthName(nextMonth)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  calendarProvider.goToNextMonth();
                  calendarProvider.goToNextMonth();
                },
              ),
            ],
          ),
        ),

        // 两个上下并列月历
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Expanded(
                  child: _MiniMonth(
                    year: year,
                    month: month,
                    marksByDay: markProvider.getMarksForMonth(year, month),
                    locationMap: locationMap,
                    onTap: () => calendarProvider.setViewMode(ViewMode.month),
                  ),
                ),
                const Divider(height: 4),
                Expanded(
                  child: _MiniMonth(
                    year: nextYear,
                    month: nextMonth,
                    marksByDay: markProvider.getMarksForMonth(nextYear, nextMonth),
                    locationMap: locationMap,
                    onTap: () {
                      calendarProvider.goToMonth(nextYear, nextMonth);
                      calendarProvider.setViewMode(ViewMode.month);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, List<TravelMark>> marksByDay;
  final Map<int, TravelLocation> locationMap;
  final VoidCallback onTap;

  const _MiniMonth({
    required this.year,
    required this.month,
    required this.marksByDay,
    required this.locationMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 收集当月涉及的差旅地点
    final locIds = <int>{};
    for (final list in marksByDay.values) {
      for (final m in list) {
        locIds.add(m.locationId);
      }
    }
    final locNames = locIds.map((id) => locationMap[id]).whereType<TravelLocation>().toList();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            '$year年${CalendarUtils.monthName(month)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (locNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SizedBox(
                height: 20,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: locNames.map((l) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
                        const SizedBox(width: 2),
                        Text(l.name, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          const SizedBox(height: 2),
          CalendarGrid(
            year: year,
            month: month,
            marksByDay: marksByDay,
            locationMap: locationMap,
            compact: true,
          ),
        ],
      ),
    );
  }
}
