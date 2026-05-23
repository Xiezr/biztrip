import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final isCurrentMonth = month == DateTime.now().month && year == DateTime.now().year;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentMonth ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentMonth ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              CalendarUtils.monthName(month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isCurrentMonth ? theme.colorScheme.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            if (travelDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$travelDays 天',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else
              Text(
                '无差旅',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}
