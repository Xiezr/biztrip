import 'package:flutter/material.dart';
import '../theme/clay_colors.dart';
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
      // 无标记：内凹效果
      cell = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: clayInputBg,
          boxShadow: clayRecessedShadow,
        ),
        child: _buildCore(colors, isToday, isCurrentMonth, theme),
      );
    } else {
      // 有标记：黏土凸起 + 目的地颜色
      cell = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: clayRaisedShadow,
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

    // 节假日角标 — 紫色 "休"
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
                  color: clayHoliday,
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
            ? Border.all(color: clayPurple, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: hasMarks ? Colors.white : (isCurrentMonth ? clayTextPrimary : clayTextTertiary),
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
