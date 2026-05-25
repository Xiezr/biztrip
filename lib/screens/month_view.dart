import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_container.dart';
import '../theme/clay_input.dart';
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
    final year = context.select<CalendarProvider, int>((p) => p.year);
    final month = context.select<CalendarProvider, int>((p) => p.month);
    final activeId = context.select<CalendarProvider, int?>((p) => p.activeLocationId);
    final calendarProvider = context.read<CalendarProvider>();
    final markProvider = context.watch<MarkProvider>();
    final locationProvider = context.read<LocationProvider>();
    final archiveLocations = context.select<LocationProvider, List<TravelLocation>>((p) => p.archive);
    final locations = context.select<LocationProvider, List<TravelLocation>>((p) => p.locations);

    final marksByDay = markProvider.getMarksForMonth(year, month);

    // locationMap：使用 archive（第1层）渲染日历格子颜色，避免 id! 断言
    final locationMap = <int, TravelLocation>{};
    for (final l in archiveLocations) {
      final id = l.id;
      if (id != null) locationMap[id] = l;
    }

    // 目的地列表：当月/未来月仅显示 reference 层中存在的，历史月显示全部 archive
    final dateNow = DateTime.now();
    final isCurrentOrFuture = (year > dateNow.year) || (year == dateNow.year && month >= dateNow.month);
    final referenceIds = locations.map((l) => l.id).whereType<int>().toSet();
    final monthLocations = archiveLocations.where((l) {
      final id = l.id;
      if (id == null || !l.belongsTo(year, month)) return false;
      if (!isCurrentOrFuture) return true;
      return referenceIds.contains(id);
    }).toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > CalendarUtils.swipeThreshold) {
          calendarProvider.goToPreviousMonth();
        } else if (velocity < -CalendarUtils.swipeThreshold) {
          calendarProvider.goToNextMonth();
        }
      },
      child: Column(
      children: [
        // 月份标题行（箭头 + 标题 + 箭头），内容整体下移
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 26),
                onPressed: () => calendarProvider.goToPreviousMonth(),
              ),
              GestureDetector(
                onTap: () => calendarProvider.setViewMode(ViewMode.year),
                child: Text('$year年 ${CalendarUtils.monthName(month)}', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 26),
                onPressed: () => calendarProvider.goToNextMonth(),
              ),
            ],
          ),
        ),
        // 日历（61.8%）
        Flexible(
          flex: 618,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                showAddButton: isCurrentOrFuture, // 过去的月份不允许添加目的地
                onTap: (id) => calendarProvider.setActiveLocation(id),
                onLongPress: (id) => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationEditPage(locationId: id, viewYear: year, viewMonth: month))),
                onAdd: () => _addTempLocation(context, year: year, month: month),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '当前时区：UTC${DateTime.now().timeZoneOffset.isNegative ? "" : "+"}${DateTime.now().timeZoneOffset.inHours}',
                  style: TextStyle(fontSize: 9, color: clayTextTertiary),
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
    // 过去月份不允许添加目的地
    final dateNow = DateTime.now();
    if (year < dateNow.year || (year == dateNow.year && month < dateNow.month)) return;

    final locationProvider = context.read<LocationProvider>();
    final calendarProvider = context.read<CalendarProvider>();
    // 目的地候选列表（按名称去重，含 archive + locations）
    final seen = <String>{};
    final candidates = <TravelLocation>[];
    for (final loc in locationProvider.locations) {
      if (seen.add(loc.name)) candidates.add(loc);
    }
    for (final loc in locationProvider.archive) {
      if (seen.add(loc.name)) candidates.add(loc);
    }

    showDialog(
      context: context,
      barrierColor: const Color(0x33FFFFFF), // 半透明遮罩
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
          child: AlertDialog(
            backgroundColor: clayBg,
            title: const Text('选择或新建目的地'),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            if (candidates.isNotEmpty) ...[
              SizedBox(
                height: (candidates.length * 56.0).clamp(0, 220),
                child: ListView(children: candidates.map((loc) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    final newId = locationProvider.activateInMonth(loc.id!, year, month);
                    if (newId >= 0) calendarProvider.setActiveLocation(newId);
                  },
                  child: ClayCard(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: loc.color, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Text(loc.name, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                )).toList()),
              ),
              const Divider(),
            ],
            GestureDetector(
              onTap: () { Navigator.pop(ctx); Future.microtask(() => _showAddDialog(context, year: year, month: month)); },
              child: ClayCard(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: clayPurple, size: 20),
                    SizedBox(width: 10),
                    Text('新建目的地', style: TextStyle(fontSize: 14, color: clayPurple, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
            ),
          ),
    );
  }

  void _showAddDialog(BuildContext context, {required int year, required int month}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
          child: AlertDialog(
        backgroundColor: clayBg,
        title: const Text('新建目的地'),
        content: ClayTextField(
          controller: controller,
          hintText: '目的地名称',
          onChanged: (_) {},
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newId = context.read<LocationProvider>().addTemporaryLocation(controller.text.trim(), year: year, month: month);
                if (newId == -1) {
                  Navigator.pop(ctx);
                  _showConflictDialog(context, name: controller.text.trim(), year: year, month: month);
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
            ),
          ),
    );
  }

  void _showConflictDialog(BuildContext context, {required String name, required int year, required int month}) {
    final locationProvider = context.read<LocationProvider>();
    final existing = locationProvider.locations.where((l) => l.name == name).first;
    showDialog(
      context: context,
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
          child: AlertDialog(
        backgroundColor: clayBg,
        title: const Text('名称冲突'),
        content: Text('已存在同名目的地"$name"，是否直接使用已有的？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newId = context.read<LocationProvider>().activateInMonth(existing.id!, year, month);
              if (newId >= 0) context.read<CalendarProvider>().setActiveLocation(newId);
            },
            child: const Text('使用已有的'),
          ),
        ],
      ),
            ),
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
  final bool showAddButton;

  const _DestGrid({
    required this.locations,
    required this.activeId,
    required this.onTap,
    required this.onLongPress,
    required this.onAdd,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // 3列网格：目的地按序排列，新建按钮跟在最后一个目的地之后（过去的月份不显示）
    final cols = 3;
    final items = locations.length + (showAddButton ? 1 : 0);
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
        child: ClayContainer(
          height: 32,
          borderRadius: clayRadius,
          color: clayBg,
          recessed: true,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: const Center(child: Icon(Icons.add, size: 16, color: clayTextTertiary)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? clayPurple.withValues(alpha: 0.10) : claySurface,
          borderRadius: BorderRadius.circular(clayRadius),
          boxShadow: isActive ? null : clayRaisedShadowLight,
          border: isActive ? Border.all(color: location.color.withValues(alpha: 0.5), width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: location.color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Flexible(child: Text(location.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? location.color : clayTextPrimary))),
          ],
        ),
      ),
    );
  }
}
