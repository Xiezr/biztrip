import 'package:flutter/material.dart';
import '../models/travel_location.dart';

/// 色系选择器：4色系 × 5色阶
class ColorFamilyPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const ColorFamilyPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String? activeFamily;
    for (final entry in TravelLocation.colorFamilies.entries) {
      if (entry.value.contains(selected)) {
        activeFamily = entry.key;
        break;
      }
    }

    const familyLabels = {'橙': '橙色系', '绿': '绿色系', '蓝': '蓝色系', '粉': '粉色系'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 色系选择（居中 椭圆形）
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: TravelLocation.colorFamilies.keys.map((family) {
              final isActive = family == activeFamily;
              final colors = TravelLocation.colorFamilies[family]!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => onChanged(colors[2]),
                  child: Container(
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors[2],
                      borderRadius: BorderRadius.circular(16),
                      border: isActive
                          ? Border.all(color: Colors.black87, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        familyLabels[family]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 色阶选择（居中 圆形）
        if (activeFamily != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: TravelLocation.colorFamilies[activeFamily]!.map((c) {
                final isActive = c == selected;
                return GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: Colors.black87, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
