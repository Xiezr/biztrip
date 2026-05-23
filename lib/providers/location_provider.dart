import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/travel_location.dart';
import '../database/storage_service.dart';

class LocationProvider extends ChangeNotifier {
  List<TravelLocation> _locations = [];
  List<TravelLocation> _archive = []; // 已删除的目的地（存档）
  int _nextId = 1;
  final StorageService _storage = StorageService();

  List<TravelLocation> get locations => List.unmodifiable(_locations);

  List<TravelLocation> get fixedLocations =>
      _locations.where((l) => l.type == LocationType.fixed).toList();

  List<TravelLocation> get temporaryLocations =>
      _locations.where((l) => l.type == LocationType.temporary).toList();

  Future<void> load() async {
    _locations = await _storage.loadLocations();
    _archive = await _storage.loadArchive();
    if (_locations.isEmpty) {
      _locations = _defaultLocations();
      await _storage.saveLocations(_locations);
    }
    _nextId = _locations.fold(0, (max, l) => l.id != null && l.id! > max ? l.id! : max) + 1;
    notifyListeners();
  }

  Future<void> save() async {
    await _storage.saveLocations(_locations);
    await _storage.saveArchive(_archive);
  }

  List<TravelLocation> get archive => List.unmodifiable(_archive);

  void addFixedLocation(String name, Color color) {
    _locations.add(TravelLocation(
      id: _nextId++,
      name: name,
      color: color,
      type: LocationType.fixed,
      sortOrder: _locations.length,
    ));
    notifyListeners();
    save();
  }

  int addTemporaryLocation(String name, {int? year, int? month}) {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    final usedColors = _locations.map((l) => l.color).toSet();
    Color color = TravelLocation.presetColors[0];
    for (final c in TravelLocation.presetColors) {
      if (!usedColors.contains(c)) {
        color = c;
        break;
      }
    }
    final id = _nextId++;
    _locations.add(TravelLocation(
      id: id,
      name: name,
      color: color,
      type: LocationType.temporary,
      sortOrder: _locations.length,
      year: y,
      month: m,
    ));
    notifyListeners();
    save();
    return id;
  }

  void removeLocation(int id) {
    _locations.removeWhere((l) => l.id == id);
    notifyListeners();
    save();
  }

  /// 临时删除：移入存档
  void archiveLocation(int id) {
    try {
      final loc = _locations.firstWhere((l) => l.id == id);
      _archive.add(loc);
      _locations.remove(loc);
    } catch (_) {}
    notifyListeners();
    save();
  }

  /// 从存档恢复到活跃列表（同时从存档移除）
  void restoreFromArchive(int id, {int? year, int? month}) {
    try {
      final loc = _archive.firstWhere((l) => l.id == id);
      final y = year ?? DateTime.now().year;
      final m = month ?? DateTime.now().month;
      _locations.add(loc.copyWith(year: y, month: m));
      _archive.remove(loc); // 恢复后从存档移除
    } catch (_) {}
    notifyListeners();
    save();
  }

  /// 从存档复制配置到新建当月目的地
  int copyFromArchive(int archiveId, {required int year, required int month}) {
    try {
      final src = _archive.firstWhere((l) => l.id == archiveId);
      final id = _nextId++;
      _locations.add(src.copyWith(id: id, year: year, month: month));
      notifyListeners();
      save();
      return id;
    } catch (_) {
      return -1;
    }
  }

  int get nextId => _nextId;

  void updateLocation(int id, String name, Color color) {
    // 搜索活跃列表和存档
    int idx = _locations.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      _locations[idx] = _locations[idx].copyWith(name: name, color: color);
    } else {
      idx = _archive.indexWhere((l) => l.id == id);
      if (idx >= 0) {
        _archive[idx] = _archive[idx].copyWith(name: name, color: color);
      }
    }
    notifyListeners();
    save();
  }

  void updateLocationFull(int id, {
    String? name,
    Color? color,
    int? notificationDaysBefore,
    int? followUpDaysAfter,
    List<String>? preparationTags,
    int? reimbursementDaysAfter,
    int? confirmationDaysBefore,
    int? reportDaysAfter,
    List<String>? specialReminder,
    List<String>? invoicePaths,
  }) {
    int idx = _locations.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      _locations[idx] = _locations[idx].copyWith(
        name: name,
        color: color,
        notificationDaysBefore: notificationDaysBefore,
        followUpDaysAfter: followUpDaysAfter,
        preparationTags: preparationTags,
        reimbursementDaysAfter: reimbursementDaysAfter,
        confirmationDaysBefore: confirmationDaysBefore,
        reportDaysAfter: reportDaysAfter,
        specialReminder: specialReminder,
        invoicePaths: invoicePaths,
      );
    } else {
      idx = _archive.indexWhere((l) => l.id == id);
      if (idx >= 0) {
        _archive[idx] = _archive[idx].copyWith(
          name: name,
          color: color,
          notificationDaysBefore: notificationDaysBefore,
          followUpDaysAfter: followUpDaysAfter,
          preparationTags: preparationTags,
          reimbursementDaysAfter: reimbursementDaysAfter,
          confirmationDaysBefore: confirmationDaysBefore,
          reportDaysAfter: reportDaysAfter,
          specialReminder: specialReminder,
          invoicePaths: invoicePaths,
        );
      }
    }
    notifyListeners();
    save();
  }

  TravelLocation? getById(int id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {
      try {
        return _archive.firstWhere((l) => l.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  List<TravelLocation> _defaultLocations() {
    return [
      TravelLocation(id: _nextId++, name: '目的地1', color: const Color.from(alpha: 1, red: 0.898, green: 0.224, blue: 0.208), type: LocationType.fixed, sortOrder: 0),
      TravelLocation(id: _nextId++, name: '目的地2', color: const Color.from(alpha: 1, red: 0.118, green: 0.533, blue: 0.898), type: LocationType.fixed, sortOrder: 1),
      TravelLocation(id: _nextId++, name: '目的地3', color: const Color.from(alpha: 1, red: 0.263, green: 0.627, blue: 0.278), type: LocationType.fixed, sortOrder: 2),
      TravelLocation(id: _nextId++, name: '目的地4', color: const Color.from(alpha: 1, red: 0.984, green: 0.737, blue: 0.0), type: LocationType.fixed, sortOrder: 3),
    ];
  }
}
