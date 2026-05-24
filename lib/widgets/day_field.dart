import 'package:flutter/material.dart';

/// 天数字段（点击弹出选择器）
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
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Text(
              '$displayValue天',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: displayValue < 0 ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
