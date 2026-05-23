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
    final allLocations = locationProvider.locations;
    // archivedLocations 不再需要用于 locationMap（已在方案B中移除）

    // 活跃目的地跨月自动清除
    final rawActiveId = calendarProvider.activeLocationId;
    final activeId = (rawActiveId != null) ? () {
      final loc = locationProvider.getById(rawActiveId);
      if (loc != null && !loc.belongsTo(year, month)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => calendarProvider.setActiveLocation(null));
        return null;
      }
      return rawActiveId;
    }() : null;

    // locationMap 仅含活跃目的地（不含存档），用于日历格子颜色渲染
    final locationMap = <int, TravelLocation>{};
    for (final l in allLocations) {
      if (l.id != null) locationMap[l.id!] = l;
    }

    // 目的地列表：仅显示属于当前月或全局的目的地
    final activeLocIds = marksByDay.values.expand((list) => list).map((m) => m.locationId).toSet();
    final monthLocations = allLocations.where((l) =>
      l.id != null && l.belongsTo(year, month) &&
      (activeLocIds.contains(l.id) || l.id == activeId)
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
                onLongPress: (id) => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationEditPage(locationId: id))),
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
    // 仅显示当月或全局的临时目的地
    final existing = locationProvider.locations.where((l) =>
      l.scope == LocationScope.month && l.belongsTo(year, month)
    ).toList();
    final archived = locationProvider.archive;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
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
                  onTap: () { Navigator.pop(ctx); calendarProvider.setActiveLocation(loc.id); },
                )).toList()),
              ),
            ],
            if (archived.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 2), child: Row(children: [
                Text('已存档', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ])),
              SizedBox(
                height: (archived.length * 44.0).clamp(0, 180),
                child: ListView(children: archived.map((loc) => ListTile(
                  dense: true,
                  leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: loc.color, shape: BoxShape.circle)),
                  title: Text(loc.name, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  onTap: () {
                    final newId = context.read<LocationProvider>().copyFromArchive(loc.id!, year: year, month: month);
                    Navigator.pop(ctx);
                    if (newId > 0) {
                      calendarProvider.setActiveLocation(newId);
                    }
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
                context.read<CalendarProvider>().setActiveLocation(newId);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
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
