import 'package:flutter/material.dart';
import '../models/travel_mark.dart';
import '../models/travel_location.dart';

class DayCell extends StatelessWidget {
  final int? day;
  final bool isToday;
  final bool isCurrentMonth;
  final bool isHoliday;
  final List<TravelMark> marks;
  final Map<int, TravelLocation> locationMap;
  final VoidCallback? onTap;
  final double fontSize;

  const DayCell({
    super.key,
    this.day,
    required this.isToday,
    this.isCurrentMonth = true,
    this.isHoliday = false,
    this.marks = const [],
    this.locationMap = const {},
    this.onTap,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox.shrink();

    // 按 locationId 去重，确保相同目的地不触发对角线分割
    final seenIds = <int>{};
    final colors = <Color>[];
    for (final m in marks) {
      if (seenIds.add(m.locationId)) {
        final c = locationMap[m.locationId]?.color;
        if (c != null) colors.add(c);
        if (colors.length >= 2) break;
      }
    }

    final hasMarks = colors.isNotEmpty;
    final theme = Theme.of(context);

    Widget cell;
    if (!hasMarks) {
      cell = _buildCore(colors, isToday, isCurrentMonth, theme);
    } else {
      // 有标记：圆形涂抹
      cell = Container(
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
      );
    }

    // 节假日角标
    if (isHoliday) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            cell,
            Positioned(
              top: -2,
              right: -2,
              child: Text(
                '休',
                style: TextStyle(
                  fontSize: fontSize * 0.55,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF007AFF),
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(onTap: onTap, child: cell);
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
