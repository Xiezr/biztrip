import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/mark_provider.dart';
import '../providers/location_provider.dart';
import '../utils/calendar_utils.dart';
import '../widgets/month_card.dart';

class YearView extends StatelessWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.read<CalendarProvider>();
    final year = context.select<CalendarProvider, int>((p) => p.year);
    final markProvider = context.read<MarkProvider>();
    final locationProvider = context.read<LocationProvider>();
    // 只用 locations（reference 层）构建 validLocIds，确保 scope 过滤生效
    final validLocIds = locationProvider.locationIdsForYear(year);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > CalendarUtils.swipeThreshold) {
          calendarProvider.setYear(year - 1);
        } else if (velocity < -CalendarUtils.swipeThreshold) {
          calendarProvider.setYear(year + 1);
        }
      },
      child: Column(
        children: [
          // 年份标题行
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 26),
                  onPressed: () => calendarProvider.setYear(year - 1),
                ),
                GestureDetector(
                  onTap: () => calendarProvider.setYear(DateTime.now().year),
                  child: Text(
                    '$year 年',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 26),
                  onPressed: () => calendarProvider.setYear(year + 1),
                ),
              ],
            ),
          ),
        // 12宫格
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Spacer(),
        ],
      ),
    );
  }
}
