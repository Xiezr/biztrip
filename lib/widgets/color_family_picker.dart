import 'package:flutter/material.dart';
import '../models/travel_location.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_container.dart';

/// 色系选择器（黏土拟态风格）
class ColorFamilyPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const ColorFamilyPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const familyLabels = {
    '橙': '橙色系',
    '绿': '绿色系',
    '蓝': '蓝色系',
    '粉': '粉色系',
    '紫': '紫色系',
  };

  @override
  Widget build(BuildContext context) {
    String? activeFamily;
    for (final entry in TravelLocation.colorFamilies.entries) {
      if (entry.value.contains(selected)) {
        activeFamily = entry.key;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 色系选择（黏土胶囊按钮，居中折行）
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 6,
            children: TravelLocation.colorFamilies.keys.map((family) {
              final colors = TravelLocation.colorFamilies[family]!;
              return ClayContainer(
                borderRadius: clayRadiusLarge,
                color: colors[2],
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: EdgeInsets.zero,
                onTap: () => onChanged(colors[2]),
                child: Text(
                  familyLabels[family]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 色阶选择（黏土圆形按钮）
        if (activeFamily != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: TravelLocation.colorFamilies[activeFamily]!.map((c) {
                return ClayContainer(
                  width: 36,
                  height: 36,
                  borderRadius: 18,
                  color: c,
                  margin: EdgeInsets.zero,
                  onTap: () => onChanged(c),
                  child: c == selected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : const SizedBox.shrink(),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
