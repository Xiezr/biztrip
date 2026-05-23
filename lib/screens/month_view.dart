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
    final locationMap = {for (final l in allLocations) l.id!: l};
    final activeId = calendarProvider.activeLocationId;

    final monthLocations = allLocations.where((l) => l.id != null).toList();

    return Column(
      children: [
        // 月份标题（紧凑）
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, top: 0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => calendarProvider.setViewMode(ViewMode.year)),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => calendarProvider.goToPreviousMonth(), padding: EdgeInsets.zero),
              Expanded(
                child: GestureDetector(
                  onTap: () => calendarProvider.setViewMode(ViewMode.year),
                  child: Text('$year年 ${CalendarUtils.monthName(month)}', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => calendarProvider.goToNextMonth(), padding: EdgeInsets.zero),
              IconButton(icon: const Icon(Icons.add_location_alt_outlined, size: 18), onPressed: () => _addTempLocation(context)),
            ],
          ),
        ),

        if (activeId != null)
          Text('涂抹中：${locationProvider.getById(activeId)?.name ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),

        // 日历
        Padding(
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

              if (markProvider.hasMark(aid, date)) {
                await markProvider.toggleMark(aid, date);
                return;
              }

              final dayMarks = markProvider.getMarksForDate(date);
              if (dayMarks.length >= 2) return;

              // 判断是否连续日期（和已有标记相差1天以内）
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

        const SizedBox(height: 12),

        // 目的地列表（每行3列）
        _DestGrid(
          locations: monthLocations,
          activeId: activeId,
          onTap: (id) => calendarProvider.setActiveLocation(id),
          onLongPress: (id) => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationEditPage(locationId: id))),
          onAdd: () => _addTempLocation(context),
        ),

        // 底部时区
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '当前时区：UTC${DateTime.now().timeZoneOffset.isNegative ? "" : "+"}${DateTime.now().timeZoneOffset.inHours}',
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  void _addTempLocation(BuildContext context) {
    final locationProvider = context.read<LocationProvider>();
    final calendarProvider = context.read<CalendarProvider>();
    final existing = locationProvider.locations.where((l) => l.type == LocationType.temporary).toList();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('选择或新建目的地', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            if (existing.isNotEmpty) ...[
              const Divider(height: 1),
              SizedBox(
                height: existing.length * 48.0,
                child: ListView(
                  children: existing.map((loc) => ListTile(
                    leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: loc.color, shape: BoxShape.circle)),
                    title: Text(loc.name, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      calendarProvider.setActiveLocation(loc.id);
                    },
                  )).toList(),
                ),
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('新建目的地', style: TextStyle(fontSize: 14, color: Colors.blue)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
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
                final newId = context.read<LocationProvider>().addTemporaryLocation(controller.text.trim());
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
    // 按每行3个分组
    final rows = <List<TravelLocation?>>[];
    for (int i = 0; i < locations.length; i += 3) {
      final row = <TravelLocation?>[];
      for (int j = 0; j < 3; j++) {
        final idx = i + j;
        row.add(idx < locations.length ? locations[idx] : null);
      }
      rows.add(row);
    }
    // 如果最后一行+新建按钮超过3个，加到新行
    // 始终保证+新建在最后一个位置
    final allSlots = <TravelLocation?>[...locations, null]; // null表示新建按钮

    final slotRows = <List<TravelLocation?>>[];
    for (int i = 0; i < allSlots.length; i += 3) {
      final row = <TravelLocation?>[];
      for (int j = 0; j < 3; j++) {
        final idx = i + j;
        row.add(idx < allSlots.length ? allSlots[idx] : null);
      }
      slotRows.add(row);
    }

    return Column(
      children: slotRows.map((row) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: row.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: item == null
                    ? GestureDetector(
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
                      )
                    : _DestChip(
                        location: item,
                        isActive: item.id == activeId,
                        onTap: () => onTap(item.id),
                        onLongPress: () => onLongPress(item.id!),
                      ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
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
