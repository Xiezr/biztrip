import 'package:flutter/material.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_container.dart';
import '../utils/calendar_utils.dart';

class MonthCard extends StatelessWidget {
  final int year;
  final int month;
  final int travelDays;
  final VoidCallback onTap;

  const MonthCard({
    super.key,
    required this.year,
    required this.month,
    required this.travelDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = month == DateTime.now().month && year == DateTime.now().year;

    return GestureDetector(
      onTap: onTap,
      child: ClayMonthCard(
        isCurrentMonth: isCurrentMonth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              CalendarUtils.monthName(month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isCurrentMonth ? clayPurple : clayTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (travelDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: clayPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$travelDays 天',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: clayPurple,
                  ),
                ),
              )
            else
              Text(
                '无差旅',
                style: TextStyle(fontSize: 11, color: clayTextTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
