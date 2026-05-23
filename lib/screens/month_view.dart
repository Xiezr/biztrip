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
              await markProvider.toggleMark(aid, date);
            },
          ),
        ),

        const SizedBox(height: 4),

        // 目的地列表
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              ...monthLocations.map((loc) => _DestChip(
                location: loc,
                isActive: loc.id == activeId,
                onTap: () => calendarProvider.setActiveLocation(loc.id),
                onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationEditPage(locationId: loc.id!))),
              )),
              GestureDetector(
                onTap: () => _addTempLocation(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.grey),
                      SizedBox(width: 2),
                      Text('新建', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? location.color.withValues(alpha: 0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? location.color : Colors.grey[300]!, width: isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: location.color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(location.name, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? location.color : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
