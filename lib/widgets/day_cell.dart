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

    // 有标记：圆形涂抹
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: colors.length == 2
                ? _DiagonalSplitPainter(colors[0], colors[1])
                : _SolidColorPainter(colors[0]),
            child: _buildCore(colors, isToday, isCurrentMonth, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildCore(List<Color> colors, bool isToday, bool isCurrentMonth, ThemeData theme) {
    final hasMarks = colors.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = color..isAntiAlias = true);
  }
  @override
  bool shouldRepaint(covariant _SolidColorPainter oldDelegate) => oldDelegate.color != color;
}

class _DiagonalSplitPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  _DiagonalSplitPainter(this.color1, this.color2);
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1..isAntiAlias = true;
    final paint2 = Paint()..color = color2..isAntiAlias = true;

    // 右上到左下斜角分割（圆形内）
    final path1 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(path1, paint1);
  }
  @override
  bool shouldRepaint(covariant _DiagonalSplitPainter oldDelegate) =>
      oldDelegate.color1 != color1 || oldDelegate.color2 != color2;
}
