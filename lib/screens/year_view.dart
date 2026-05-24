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
    final calendarProvider = context.read<CalendarProvider>();
    final year = context.select<CalendarProvider, int>((p) => p.year);
    final markProvider = context.watch<MarkProvider>();
    final locationProvider = context.read<LocationProvider>();
    // 只用 locations（reference 层）构建 validLocIds，确保 scope 过滤生效
    final validLocIds = locationProvider.locationIdsForYear(year);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 200) {
          calendarProvider.setYear(year - 1);
        } else if (velocity < -200) {
          calendarProvider.setYear(year + 1);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 年份标题（点击回当年，左右滑切换）
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => calendarProvider.setYear(DateTime.now().year),
              child: Text(
                '$year 年',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 2),
              ),
            ),
          ),
        // 12宫格（居中）
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: GridView.builder(
              shrinkWrap: true,
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
      ),
    );
  }
}
