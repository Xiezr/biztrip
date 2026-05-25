import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/travel_location.dart';
import '../database/storage_service.dart';

class LocationProvider extends ChangeNotifier {
  List<TravelLocation> _locations = [];   // 第2层 Reference：新建差旅可选，受删除影响
  List<TravelLocation> _archive = [];     // 第1层 Archive：历史颜色查找 + 历史月标签
  List<TravelLocation> _preference = [];  // 第3层 Preference：临时删除配置留底，同名不可重复
  int _nextId = 1;
  final StorageService _storage = StorageService();

  /// 第2层：供新差旅创建使用（受临时/永久删除控制）
  List<TravelLocation> get locations => List.unmodifiable(_locations);

  /// 第1层：供日历渲染和目的地展示（append-only，不受删除影响）
  List<TravelLocation> get archive => List.unmodifiable(_archive);

  /// 第3层：临时删除的配置留底（用于恢复，同名不可重复）
  List<TravelLocation> get preference => List.unmodifiable(_preference);

  List<TravelLocation> get fixedLocations =>
      _locations.where((l) => l.scope == LocationScope.global).toList();

  List<TravelLocation> get temporaryLocations =>
      _locations.where((l) => l.scope == LocationScope.month).toList();

  /// 获取指定年月的目的地列表（global 全月可见，month 仅匹配年月）
  /// 注意：此方法基于 reference 层，供新建差旅使用
  /// 获取指定年份所有有效的目的地 ID（global 全月有效，month 仅匹配年份）
  Set<int> locationIdsForYear(int year) {
    final ids = <int>{};
    for (final l in _locations) {
      if (l.scope == LocationScope.global) {
        ids.add(l.id!);
      } else if (l.scope == LocationScope.month && l.scopedYear == year) {
        ids.add(l.id!);
      }
    }
    return ids;
  }

  List<TravelLocation> locationsForMonth(int year, int month) =>
      _locations.where((l) => l.belongsTo(year, month)).toList();

  Future<void> load() async {
    try {
      // 1. 加载三层数据
      _archive = await _storage.loadArchive();
      _locations = await _storage.loadLocations();
      _preference = await _storage.loadPreferences();

      // 2. 逐步执行初始化/迁移
      await _migrateLegacyArchive();
      await _syncArchiveFromLocations();
      await _resetOldData();
      await _ensureDefaults();
      await _deduplicateAndSave();
      _computeNextId();
    } catch (e, stack) {
      debugPrint('LocationProvider.load error: $e\n$stack');
      _locations = [];
      _archive = [];
      _preference = [];
      _nextId = 1;
      await _storage.saveLocations(_locations);
      await _storage.saveArchive(_archive);
      await _storage.savePreferences(_preference);
    }
    notifyListeners();
  }

  /// 迁移旧版 archive.json 数据（仅执行一次，通过 .migrated 标记跳过重复）
  Future<void> _migrateLegacyArchive() async {
    if (await _storage.isLegacyMigrated()) return;

    final oldArchive = await _storage.loadArchiveLegacy();
    if (oldArchive.isEmpty) {
      await _storage.markLegacyMigrated();
      return;
    }

    for (final archived in oldArchive) {
      final asGlobal = archived.copyWith(
        scope: LocationScope.global,
        scopedYear: null,
        scopedMonth: null,
      );
      if (!_archive.any((l) => l.name == archived.name)) {
        _archive.add(asGlobal);
      }
      if (!_locations.any((l) => l.name == archived.name)) {
        _locations.add(asGlobal);
      }
    }
    await _storage.saveArchive(_archive);
    await _storage.saveLocations(_locations);
    await _storage.deleteArchiveFile();
    await _storage.markLegacyMigrated();
  }

  /// archive 为空但 reference 有数据 → 从 reference 迁移填充 archive
  Future<void> _syncArchiveFromLocations() async {
    if (_archive.isNotEmpty || _locations.isEmpty) return;
    for (final l in _locations) {
      if (!_archive.any((a) => a.name == l.name)) {
        _archive.add(l.copyWith(
          scope: LocationScope.global,
          scopedYear: null,
          scopedMonth: null,
        ));
      }
    }
    await _storage.saveArchive(_archive);
  }

  /// 旧用户数据重置检查（ID >= 100 来自旧架构）→ 清空旧数据
  Future<void> _resetOldData() async {
    if (_locations.any((l) => (l.id ?? 0) >= 100)) {
      _locations = [];
      await _storage.saveLocations(_locations);
    }
    if (_archive.any((l) => (l.id ?? 0) >= 100)) {
      _archive = [];
      await _storage.saveArchive(_archive);
    }
  }

  /// 都为空：不再填充预设，由用户自行创建
  Future<void> _ensureDefaults() async {
    // 不再预填默认目的地，空数据即为合法初始状态
  }

  /// 两层去重后保存
  Future<void> _deduplicateAndSave() async {
    _deduplicateByName(_locations);
    _deduplicateByName(_archive);
    await _storage.saveLocations(_locations);
    await _storage.saveArchive(_archive);
  }

  /// 计算 nextId
  void _computeNextId() {
    _nextId = _locations.fold(
      0, (max, l) => l.id != null && l.id! > max ? l.id! : max,
    ) + 1;
    final amax = _archive.fold(
      0, (max, l) => l.id != null && l.id! > max ? l.id! : max,
    ) + 1;
    if (amax > _nextId) _nextId = amax;
  }

  /// 同名去重：保留 global 优先
  void _deduplicateByName(List<TravelLocation> list) {
    final deduped = <String, TravelLocation>{};
    for (final l in list) {
      final existing = deduped[l.name];
      if (existing == null) {
        deduped[l.name] = l;
      } else if (l.scope == LocationScope.global && existing.scope != LocationScope.global) {
        deduped[l.name] = l;
      }
    }
    if (deduped.length != list.length) {
      list
        ..clear()
        ..addAll(deduped.values);
    }
  }

  Future<void> save() async {
    await _storage.saveLocations(_locations);
    await _storage.saveArchive(_archive);
    await _storage.savePreferences(_preference);
  }

  /// 向 archive 追加（同名去重：global 全局唯一；month 按年月去重，不同月可共存）
  void _addToArchive(TravelLocation loc) {
    final existingIdx = _archive.indexWhere((a) => a.name == loc.name);
    if (existingIdx >= 0) {
      final existing = _archive[existingIdx];
      // global 或同月 → 真正重复，跳过
      if (existing.scope == LocationScope.global ||
          (existing.scopedYear == loc.scopedYear && existing.scopedMonth == loc.scopedMonth)) {
        return;
      }
      // 不同月 → 允许新增一条
    }
    _archive.add(loc.copyWith());
  }

  /// 添加全局固定目的地
  /// 返回 -1 表示已存在同名目的地
  int addFixedLocation(String name, Color color) {
    final conflict = _locations.any((l) => l.name == name) || _archive.any((l) => l.name == name);
    if (conflict) return -1;

    final id = _nextId++;
    final loc = TravelLocation(
      id: id,
      name: name,
      color: color,
      type: LocationType.fixed,
      scope: LocationScope.global,
      sortOrder: _locations.length,
    );
    _locations.add(loc);
    _addToArchive(loc); // archive 作为颜色查找表，需要此 ID
    notifyListeners();
    save();
    return id;
  }

  /// 返回 -1 表示已存在同名目的地（由 UI 处理冲突提示）
  int addTemporaryLocation(String name, {int? year, int? month}) {
    // 同名冲突检测：仅查 reference 层（temp-delete 后 archive 仍保留，但应允许重新添加）
    final conflict = _locations.any((l) => l.name == name);
    if (conflict) return -1;

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
    final loc = TravelLocation(
      id: id,
      name: name,
      color: color,
      type: LocationType.temporary,
      scope: LocationScope.month,
      scopedYear: y,
      scopedMonth: m,
      sortOrder: _locations.length,
    );
    _locations.add(loc);
    _addToArchive(loc); // archive 作为颜色查找表，需要此 ID
    notifyListeners();
    save();
    return id;
  }

  /// 将已有目的地激活到指定月份（月度隔离）
  /// - 从 archive / locations 中按 ID 查找源（保留配置信息）
  /// - 若当前月已有该名称的目的地 → 直接返回已有 ID
  /// - 否则创建新的月独属副本（新 ID），scope=month，写入 _locations + _archive
  /// 返回：新创建的目的地 ID（或已有 ID），-1 表示 ID 无效
  int activateInMonth(int id, int year, int month) {
    // 从 archive 中查找源
    TravelLocation? src;
    try { src = _archive.firstWhere((l) => l.id == id); } catch (_) {}
    src ??= (() { try { return _locations.firstWhere((l) => l.id == id); } catch (_) { return null; } })();
    if (src == null) return -1;

    final s = src;

    // 检查当前月是否已有同名目的地
    final existingIdx = _locations.indexWhere(
      (l) => l.name == s.name && l.scopedYear == year && l.scopedMonth == month,
    );
    if (existingIdx >= 0) return _locations[existingIdx].id!;

    // 创建当前月独属副本（新 ID）
    final newId = _nextId++;
    final copy = s.copyWith(
      id: newId,
      scope: LocationScope.month,
      scopedYear: year,
      scopedMonth: month,
    );
    _locations.add(copy);
    _addToArchive(copy);
    notifyListeners();
    save();
    return newId;
  }

  /// 临时删除：从 reference 移除，archive 保留（历史月份仍需显示），配置保存到 preference（同名不可重复）
  /// 调用方需自行清除该目的地的未来标记（MarkProvider.removeFutureMarks）
  void tempDeleteLocation(int id) {
    // 1. 找到源对象（优先 archive 后 locations）
    TravelLocation? src;
    try {
      src = _archive.firstWhere((l) => l.id == id);
    } catch (_) {}
    src ??= (() { try { return _locations.firstWhere((l) => l.id == id); } catch (_) { return null; } })();
    if (src == null) return;

    // 2. preference 同名不可重复
    final s = src; // 流分析辅助：src 已通过 null check
    final conflict = _preference.any((p) => p.name == s.name);
    if (!conflict) {
      _preference.add(s.copyWith());
    }

    // 3. 仅移除 reference 层，archive 保留供历史月渲染
    _locations.removeWhere((l) => l.id == id);

    notifyListeners();
    save();
  }

  /// 永久删除：从 reference + preference 移除，archive 保留（供历史差旅颜色渲染）
  /// 调用方需自行清除该目的地的未来标记（MarkProvider.removeFutureMarks）
  void permDeleteLocation(int id) {
    _locations.removeWhere((l) => l.id == id);
    _preference.removeWhere((l) => l.id == id);
    // archive 不动 —— 历史差旅仍需颜色查找

    notifyListeners();
    save();
  }

  /// 保留旧方法兼容性（如果外部有调用），内部委托给 tempDeleteLocation
  void archiveLocation(int id, {int? year, int? month}) {
    tempDeleteLocation(id);
  }

  /// 保留旧方法兼容性，内部委托给 permDeleteLocation
  void removeLocation(int id) {
    permDeleteLocation(id);
  }

  int get nextId => _nextId;

  void updateLocation(int id, String name, Color color) {
    int idx = _locations.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      _locations[idx] = _locations[idx].copyWith(name: name, color: color);
    }
    // 同步更新 archive：名称和颜色需要反映到日历视图
    final aidx = _archive.indexWhere((l) => l.id == id);
    if (aidx >= 0) {
      _archive[aidx] = _archive[aidx].copyWith(name: name, color: color);
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
    }
    // 同步更新 archive：名称和颜色反映到日历视图；配置类字段仅保留在 reference
    final aidx = _archive.indexWhere((l) => l.id == id);
    if (aidx >= 0) {
      _archive[aidx] = _archive[aidx].copyWith(name: name, color: color);
    }
    notifyListeners();
    save();
  }

  TravelLocation? getById(int id) {
    try {
      return _archive.firstWhere((l) => l.id == id);
    } catch (_) {}
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {}
    try {
      return _preference.firstWhere((l) => l.id == id);
    } catch (_) {}
    return null;
  }

}
