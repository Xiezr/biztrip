import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/travel_location.dart';
import '../models/travel_mark.dart';

/// 存储服务：JSON 文件持久化，含损坏备份保护
class StorageService {
  late String _appDir;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _appDir = '${dir.path}/biztrip';
      final appDir = Directory(_appDir);
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      _initialized = true;
      debugPrint('Storage path: $_appDir');
    } catch (e, stack) {
      debugPrint('StorageService.init error: $e\n$stack');
      rethrow;
    }
  }

  // ==================== 工具方法 ====================

  /// 保存前备份原文件（防止写入中断导致数据损坏）
  Future<File?> _backup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '$filePath.backup-$timestamp';
    try {
      await file.copy(backupPath);
      // 只保留最近5个备份
      final dir = Directory(p.dirname(filePath));
      final backups = await dir
          .list()
          .where((f) => f is File && f.path.startsWith('$filePath.backup-'))
          .cast<File>()
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final f in backups.skip(5)) {
        await f.delete();
      }
      return File(backupPath);
    } catch (e) {
      debugPrint('backup error: $e');
      return null;
    }
  }

  /// 安全保存：先写临时文件，成功后再替换
  Future<void> _safeWrite(String filePath, String content) async {
    final file = File(filePath);
    final tmpPath = '$filePath.tmp';
    final tmpFile = File(tmpPath);
    try {
      await tmpFile.writeAsString(content);
      if (await file.exists()) {
        await _backup(filePath);
      }
      await tmpFile.rename(filePath);
    } catch (e) {
      debugPrint('safeWrite error: $e');
      // 清理临时文件
      if (await tmpFile.exists()) await tmpFile.delete();
      rethrow;
    }
  }

  /// 加载 JSON 文件，损坏时恢复备份
  Future<List<dynamic>> _loadJson(String filePath, String label) async {
    await init();
    final file = File(filePath);
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      return jsonDecode(content) as List;
    } catch (e) {
      debugPrint('$label load error: $e');
      // 尝试从最近的备份恢复
      final dir = Directory(p.dirname(filePath));
      final backups = await dir
          .list()
          .where((f) => f is File && f.path.startsWith('$filePath.backup-'))
          .cast<File>()
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final backup in backups) {
        try {
          final content = await backup.readAsString();
          final data = jsonDecode(content) as List;
          debugPrint('$label restored from backup: ${p.basename(backup.path)}');
          // 把恢复的数据写回原文件
          await file.writeAsString(content);
          return data;
        } catch (_) {
          continue;
        }
      }
      debugPrint('$label: no valid backup found, returning empty');
      return [];
    }
  }

  // ==================== 地点 ====================

  Future<List<TravelLocation>> loadLocations() async {
    await init();
    try {
      final data = await _loadJson('$_appDir/locations.json', 'loadLocations');
      return data.map((e) => TravelLocation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadLocations parse error: $e');
      return [];
    }
  }

  Future<void> saveLocations(List<TravelLocation> locations) async {
    await init();
    try {
      final list = locations.map((l) => l.toJson()).toList();
      await _safeWrite('$_appDir/locations.json', jsonEncode(list));
    } catch (e) {
      debugPrint('saveLocations error: $e');
    }
  }

  // ==================== 存档（Archive 第1层） ====================

  Future<List<TravelLocation>> loadArchive() async {
    await init();
    try {
      final data = await _loadJson('$_appDir/archive.json', 'loadArchive');
      return data.map((e) => TravelLocation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadArchive parse error: $e');
      return [];
    }
  }

  Future<void> saveArchive(List<TravelLocation> archive) async {
    await init();
    try {
      final list = archive.map((l) => l.toJson()).toList();
      await _safeWrite('$_appDir/archive.json', jsonEncode(list));
    } catch (e) {
      debugPrint('saveArchive error: $e');
    }
  }

  // ==================== 标记 ====================

  Future<List<TravelMark>> loadMarks() async {
    await init();
    try {
      final data = await _loadJson('$_appDir/marks.json', 'loadMarks');
      return data.map((e) => TravelMark.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadMarks parse error: $e');
      return [];
    }
  }

  Future<void> saveMarks(List<TravelMark> marks) async {
    await init();
    try {
      final list = marks.map((m) => m.toJson()).toList();
      await _safeWrite('$_appDir/marks.json', jsonEncode(list));
    } catch (e) {
      debugPrint('saveMarks error: $e');
    }
  }

  // ==================== 存档迁移 ====================

  /// 加载旧存档数据（仅迁移时使用，迁移后删除文件）
  Future<List<TravelLocation>> loadArchiveLegacy() async {
    await init();
    try {
      final data = await _loadJson('$_appDir/archive.json', 'loadArchiveLegacy');
      return data.map((e) => TravelLocation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadArchiveLegacy parse error: $e');
      return [];
    }
  }

  /// 迁移完成：删除旧存档文件
  Future<void> deleteArchiveFile() async {
    await init();
    try {
      final file = File('$_appDir/archive.json');
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('deleteArchiveFile error: $e');
    }
  }

  // ==================== 迁移标记 ====================

  /// 检查是否已完成旧版→新版数据迁移
  Future<bool> isLegacyMigrated() async {
    await init();
    return File('$_appDir/.migrated').exists();
  }

  /// 写入迁移完成标记，后续启动跳过迁移流程
  Future<void> markLegacyMigrated() async {
    await init();
    try {
      await File('$_appDir/.migrated').writeAsString('done');
    } catch (e) {
      debugPrint('markLegacyMigrated error: $e');
    }
  }
}
