import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/mark_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/calendar_grid.dart';
import '../utils/calendar_utils.dart';
import '../models/travel_location.dart';
import 'location_edit_page.dart';

class MonthView extends StatelessWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final markProvider = context.watch<MarkProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final year = calendarProvider.year;
    final month = calendarProvider.month;
    final marksByDay = markProvider.getMarksForMonth(year, month);

    // 活跃目的地不再自动清除（修复 bug：global 目的地无需当月有 mark 即可选中）
    final activeId = calendarProvider.activeLocationId;

    // locationMap：使用 archive（第1层）渲染日历格子颜色
    // archive 为全局可见，历史目的地不会被删除影响
    final archiveLocations = locationProvider.archive;
    final locationMap = <int, TravelLocation>{};
    for (final l in archiveLocations) {
      if (l.id != null) locationMap[l.id!] = l;
    }

    // 目的地列表：展示当月的所有 archive 目的地（不再要求必须有 mark）
    final monthLocations = archiveLocations.where((l) =>
      l.id != null && l.belongsTo(year, month)
    ).toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 200) {
          calendarProvider.goToPreviousMonth();
        } else if (velocity < -200) {
          calendarProvider.goToNextMonth();
        }
      },
      child: Column(
      children: [
        // 月份标题
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () => calendarProvider.setViewMode(ViewMode.year),
            child: Text('$year年 ${CalendarUtils.monthName(month)}', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1)),
          ),
        ),
        // 日历（61.8%）
        Flexible(
          flex: 618,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CalendarGrid(
                year: year,
                month: month,
                marksByDay: marksByDay,
                locationMap: locationMap,
                onTapDay: (date) async {
                  final aid = calendarProvider.activeLocationId;
                  final today = DateTime.now();
                  if (date.isBefore(DateTime(today.year, today.month, today.day))) return;
                  if (aid == null) return;

                  // 检查活跃目的地是否属于当前月或为全局
                  final loc = locationMap[aid];
                  if (loc != null && !loc.belongsTo(year, month)) return;

                  if (markProvider.hasMark(aid, date)) {
                    await markProvider.toggleMark(aid, date);
                    return;
                  }

                  final dayMarks = markProvider.getMarksForDate(date);
                  if (dayMarks.length >= 2) return;

                  bool isConsecutive = false;
                  final prev = DateTime(date.year, date.month, date.day - 1);
                  final next = DateTime(date.year, date.month, date.day + 1);
                  if (markProvider.hasMark(aid, prev) || markProvider.hasMark(aid, next)) {
                    isConsecutive = true;
                  }

                  if (!isConsecutive) {
                    final lastDate = markProvider.getLastMarkDate(aid, date);
                    if (lastDate != null) {
                      final daysSince = date.difference(lastDate).inDays;
                      final locName = locationProvider.getById(aid)?.name ?? '';
                      if (daysSince > 0) {
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('距离上一次去$locName'),
                            content: Text('已有 $daysSince 天', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了'))],
                          ),
                        );
                      }
                    }
                  }
                  await markProvider.toggleMark(aid, date);
                },
              ),
            ),
          ),

        // 目的地（38.2%）
        Flexible(
          flex: 382,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DestGrid(
                locations: monthLocations,
                activeId: activeId,
                onTap: (id) => calendarProvider.setActiveLocation(id),
                onLongPress: (id) => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationEditPage(locationId: id, viewYear: year, viewMonth: month))),
                onAdd: () => _addTempLocation(context, year: year, month: month),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '当前时区：UTC${DateTime.now().timeZoneOffset.isNegative ? "" : "+"}${DateTime.now().timeZoneOffset.inHours}',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  void _addTempLocation(BuildContext context, {required int year, required int month}) {
    final locationProvider = context.read<LocationProvider>();
    final calendarProvider = context.read<CalendarProvider>();
    // 全部目的地（不分月过滤，统一可选）
    final existing = locationProvider.locations.toList();

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF9F5F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('选择或新建目的地', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            if (existing.isNotEmpty) ...[
              const Divider(height: 1),
              SizedBox(
                height: (existing.length * 48.0).clamp(0, 200),
                child: ListView(children: existing.map((loc) => ListTile(
                  dense: true,
                  leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: loc.color, shape: BoxShape.circle)),
                  title: Text(loc.name, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    locationProvider.activateInMonth(loc.id!, year, month);
                    calendarProvider.setActiveLocation(loc.id);
                  },
                )).toList()),
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('新建目的地', style: TextStyle(fontSize: 14, color: Colors.blue)),
              onTap: () { Navigator.pop(ctx); _showAddDialog(context, year: year, month: month); },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, {required int year, required int month}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建目的地'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '目的地名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newId = context.read<LocationProvider>().addTemporaryLocation(controller.text.trim(), year: year, month: month);
                if (newId == -1) {
                  // 同名冲突：弹出选择框
                  Navigator.pop(ctx);
                  _showConflictDialog(context, name: controller.text.trim());
                } else {
                  context.read<CalendarProvider>().setActiveLocation(newId);
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showConflictDialog(BuildContext context, {required String name}) {
    final locationProvider = context.read<LocationProvider>();
    final existing = locationProvider.locations.where((l) => l.name == name).first;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('名称冲突'),
        content: Text('已存在同名目的地"$name"，是否直接使用已有的？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CalendarProvider>().setActiveLocation(existing.id);
            },
            child: const Text('使用已有的'),
          ),
        ],
      ),
    );
  }
}

class _DestGrid extends StatelessWidget {
  final List<TravelLocation> locations;
  final int? activeId;
  final void Function(int? id) onTap;
  final void Function(int id) onLongPress;
  final VoidCallback onAdd;

  const _DestGrid({
    required this.locations,
    required this.activeId,
    required this.onTap,
    required this.onLongPress,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // 3列网格：目的地按序排列，新建按钮跟在最后一个目的地之后
    final cols = 3;
    final items = locations.length + 1; // +1 for "+"按钮
    final rowCount = (items + cols - 1) ~/ cols;

    return Column(
      children: List.generate(rowCount, (r) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(cols, (c) {
            final idx = r * cols + c;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: _slotWidget(idx),
            ));
          }),
        ),
      )),
    );
  }

  Widget _slotWidget(int idx) {
    if (idx < locations.length) {
      final loc = locations[idx];
      return _DestChip(
        location: loc,
        isActive: loc.id == activeId,
        onTap: () => onTap(loc.id),
        onLongPress: () => onLongPress(loc.id!),
      );
    } else if (idx == locations.length) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(child: Icon(Icons.add, size: 16, color: Colors.grey)),
        ),
      );
    } else {
      return const SizedBox(height: 32);
    }
  }
}

class _DestChip extends StatelessWidget {
  final TravelLocation location;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DestChip({required this.location, required this.isActive, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? location.color.withValues(alpha: 0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? location.color : Colors.grey[300]!, width: isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: location.color, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Flexible(child: Text(location.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? location.color : Colors.black87))),
          ],
        ),
      ),
    );
  }
}
