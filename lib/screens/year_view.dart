import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/mark_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/month_card.dart';

class YearView extends StatelessWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final markProvider = context.watch<MarkProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final year = calendarProvider.year;
    final validLocIds = locationProvider.locations.map((l) => l.id!).toSet();

    return Column(
      children: [
        // 年份标题 + 导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => calendarProvider.setYear(year - 1),
              ),
              Text(
                '$year 年',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => calendarProvider.setYear(year + 1),
              ),
            ],
          ),
        ),
        // 12宫格
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final days = markProvider.getTravelDaysForMonth(year, month, validLocationIds: validLocIds);
                return MonthCard(
                  year: year,
                  month: month,
                  travelDays: days,
                  onTap: () {
                    calendarProvider.goToMonth(year, month);
                    calendarProvider.setViewMode(ViewMode.month);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
