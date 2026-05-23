import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/calendar_provider.dart';
import '../models/travel_location.dart';
import '../screens/location_edit_page.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final calendarProvider = context.watch<CalendarProvider>();
    final allLocations = locationProvider.locations;
    final activeId = calendarProvider.activeLocationId;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeId != null)
            Text(
              '正在标记：${locationProvider.getById(activeId)?.name ?? ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...allLocations.where((loc) => loc.id != null).map((loc) => _LocationChip(
                      location: loc,
                      isActive: loc.id == activeId,
                      onTap: () => calendarProvider.setActiveLocation(loc.id),
                      onLongPress: () => _openEditPage(context, loc.id!),
                    )),
                const SizedBox(width: 4),
                Center(
                  child: InkWell(
                    onTap: () => _showAddLocationDialog(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.add, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditPage(BuildContext context, int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocationEditPage(locationId: id)),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加临时地点'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '地点名称'),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final cal = context.read<CalendarProvider>();
                  context.read<LocationProvider>().addTemporaryLocation(
                    controller.text.trim(),
                    year: cal.year,
                    month: cal.month,
                  );
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

class _LocationChip extends StatelessWidget {
  final TravelLocation location;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LocationChip({
    required this.location,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? location.color.withValues(alpha: 0.2) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? location.color : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: location.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                location.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? location.color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
