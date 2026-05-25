/// 黏土拟态风格 — 通用容器组件
library;

import 'package:flutter/material.dart';
import 'clay_colors.dart';

/// 通用黏土容器
/// [recessed] = true 时为内凹效果（输入框用）
/// [color] 不传时使用 [claySurface]
class ClayContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final bool recessed;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const ClayContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = clayRadius,
    this.color,
    this.recessed = false,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? claySurface;
    final shadows = recessed ? clayRecessedShadow : clayRaisedShadow;

    Widget w = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      w = GestureDetector(onTap: onTap, child: w);
    }
    return w;
  }
}

/// 黏土卡片（配合 ListView/Column 使用）
class ClayCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final bool recessed;
  final VoidCallback? onTap;

  const ClayCard({
    super.key,
    required this.child,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.padding = const EdgeInsets.all(14),
    this.recessed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      width: width,
      borderRadius: clayRadius,
      recessed: recessed,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// 黏土胶囊标签（用于目的地标签、Chip 替代）
class ClayChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ClayChip({
    super.key,
    required this.label,
    this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      borderRadius: clayRadiusLarge,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      margin: EdgeInsets.zero,
      color: color ?? claySurface,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: clayTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 黏土图标按钮（凸起风格）
class ClayIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final VoidCallback? onPressed;

  const ClayIconButton({
    super.key,
    required this.icon,
    this.size = 30,
    this.color,
    this.onPressed,
  });

  @override
  State<ClayIconButton> createState() => _ClayIconButtonState();
}

class _ClayIconButtonState extends State<ClayIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: ClayContainer(
        width: widget.size + 12,
        height: widget.size + 12,
        borderRadius: clayRadius,
        color: widget.color ?? claySurface,
        recessed: _pressed,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.size * 0.65,
            color: clayPurple,
          ),
        ),
      ),
    );
  }
}

/// 当前月份高亮卡片（MonthCard 专用）
class ClayMonthCard extends StatelessWidget {
  final Widget child;
  final bool isCurrentMonth;

  const ClayMonthCard({
    super.key,
    required this.child,
    this.isCurrentMonth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: claySurface,
        borderRadius: BorderRadius.circular(clayRadiusSmall),
        boxShadow: isCurrentMonth ? clayRaisedShadowStrong : clayRaisedShadowLight,
        border: isCurrentMonth
            ? Border.all(color: clayPurple.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: child,
    );
  }
}
