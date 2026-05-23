import 'package:flutter/material.dart';
import '../models/travel_mark.dart';
import '../models/travel_location.dart';

class DayCell extends StatelessWidget {
  final int? day;
  final bool isToday;
  final bool isCurrentMonth;
  final List<TravelMark> marks;
  final Map<int, TravelLocation> locationMap;
  final VoidCallback? onTap;
  final double fontSize;

  const DayCell({
    super.key,
    this.day,
    required this.isToday,
    this.isCurrentMonth = true,
    this.marks = const [],
    this.locationMap = const {},
    this.onTap,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox.shrink();

    // 最多取前2个标记
    final colors = marks
        .map((m) => locationMap[m.locationId]?.color)
        .whereType<Color>()
        .take(2)
        .toList();

    final hasMarks = colors.isNotEmpty;
    final theme = Theme.of(context);

    if (!hasMarks) {
      return GestureDetector(
        onTap: onTap,
        child: _buildCore(colors, isToday, isCurrentMonth, theme),
      );
    }

    // 有标记：用CustomPaint画斜对角
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: colors.length == 2
              ? _DiagonalSplitPainter(colors[0], colors[1])
              : _SolidColorPainter(colors[0]),
          child: _buildCore(colors, isToday, isCurrentMonth, theme),
        ),
      ),
    );
  }

  Widget _buildCore(List<Color> colors, bool isToday, bool isCurrentMonth, ThemeData theme) {
    final hasMarks = colors.isNotEmpty;
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: hasMarks ? Colors.white : (isCurrentMonth ? Colors.black87 : Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}

class _SolidColorPainter extends CustomPainter {
  final Color color;
  _SolidColorPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DiagonalSplitPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  _DiagonalSplitPainter(this.color1, this.color2);
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    // 右上到左下斜角分割
    final path1 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
    canvas.drawPath(path1, paint1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
