import 'package:flutter/material.dart';
import '../theme/clay_colors.dart';

/// 内凹黏土日期/天数选择字段
class DayField extends StatelessWidget {
  final String label;
  final int value;
  final bool isBefore;
  final VoidCallback onTap;

  const DayField({
    super.key,
    required this.label,
    required this.value,
    required this.isBefore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value; // 直接使用有符号值，负数自带 "-"
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: clayInputBg, // 内凹：用输入底色
          borderRadius: BorderRadius.circular(clayRadiusSmall),
          boxShadow: clayRecessedShadow,
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: clayTextSecondary)),
            const Spacer(),
            Text(
              '$displayValue天',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: displayValue < 0 ? clayPurple : clayWarning,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: clayTextTertiary),
          ],
        ),
      ),
    );
  }
}
