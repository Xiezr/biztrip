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

    // 收集当月有涂抹的目的地ID
    final activeLocIds = <int>{};
    for (final list in marksByDay.values) {
      for (final m in list) {
        activeLocIds.add(m.locationId);
      }
    }
    final monthLocations = allLocations.where((l) => l.id != null && activeLocIds.contains(l.id)).toList();

    return Column(
      children: [
        // 月份标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => calendarProvider.setViewMode(ViewMode.year),
              ),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => calendarProvider.goToPreviousMonth()),
              Expanded(
                child: GestureDetector(
                  onTap: () => calendarProvider.setViewMode(ViewMode.year),
                  child: Text('$year年 ${CalendarUtils.monthName(month)}', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => calendarProvider.goToNextMonth()),
              // 添加临时目的地按钮
              IconButton(
                icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                onPressed: () => _addTempLocation(context),
                tooltip: '添加临时目的地',
              ),
            ],
          ),
        ),

        if (activeId != null)
          Text('涂抹中：${locationProvider.getById(activeId)?.name ?? ''}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),

        // 日历主体（居中）
        Expanded(
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

                // 检查是否已有此标记
                if (markProvider.hasMark(aid, date)) {
                  await markProvider.toggleMark(aid, date);
                  return;
                }

                // 检查当天是否已有2个标记
                final dayMarks = markProvider.getMarksForDate(date);
                if (dayMarks.length >= 2) return;

                // 检查上次去该目的地距今多久
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
        ),

        // 当月差旅目的地 + 添加按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              ...monthLocations.map((loc) => _DestChip(
                location: loc,
                isActive: loc.id == activeId,
                onTap: () => calendarProvider.setActiveLocation(loc.id),
                onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationEditPage(locationId: loc.id!))),
              )),
              // 添加新目的地
              GestureDetector(
                onTap: () => _addTempLocation(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('新建', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _addTempLocation(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加临时目的地'),
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
                context.read<LocationProvider>().addTemporaryLocation(controller.text.trim());
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

  const _DestChip({
    required this.location,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? location.color.withValues(alpha: 0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? location.color : Colors.grey[300]!, width: isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: location.color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(location.name, style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? location.color : Colors.black87,
            )),
          ],
        ),
      ),
    );
  }
}
