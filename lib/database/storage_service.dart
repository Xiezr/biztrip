import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/travel_location.dart';
import '../models/travel_mark.dart';

class StorageService {
  late String _appDir;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _appDir = '${dir.path}/biztrip';
    final appDir = Directory(_appDir);
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    _initialized = true;
    debugPrint('Storage path: $_appDir');
  }

  // ==================== 地点 ====================

  Future<List<TravelLocation>> loadLocations() async {
    await init();
    try {
      final file = File('$_appDir/locations.json');
      if (!await file.exists()) return _defaultLocations();
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      return list.map((e) => TravelLocation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadLocations error: $e');
      return _defaultLocations();
    }
  }

  Future<void> saveLocations(List<TravelLocation> locations) async {
    await init();
    try {
      final file = File('$_appDir/locations.json');
      final list = locations.map((l) => l.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('saveLocations error: $e');
    }
  }

  List<TravelLocation> _defaultLocations() {
    return [
      TravelLocation(id: 1, name: '目的地1', color: const Color.from(alpha: 1, red: 0.898, green: 0.224, blue: 0.208), type: LocationType.fixed, sortOrder: 0),
      TravelLocation(id: 2, name: '目的地2', color: const Color.from(alpha: 1, red: 0.118, green: 0.533, blue: 0.898), type: LocationType.fixed, sortOrder: 1),
      TravelLocation(id: 3, name: '目的地3', color: const Color.from(alpha: 1, red: 0.263, green: 0.627, blue: 0.278), type: LocationType.fixed, sortOrder: 2),
      TravelLocation(id: 4, name: '目的地4', color: const Color.from(alpha: 1, red: 0.984, green: 0.737, blue: 0.0), type: LocationType.fixed, sortOrder: 3),
    ];
  }

  // ==================== 标记 ====================

  Future<List<TravelMark>> loadMarks() async {
    await init();
    try {
      final file = File('$_appDir/marks.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      return list.map((e) => TravelMark.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadMarks error: $e');
      return [];
    }
  }

  Future<void> saveMarks(List<TravelMark> marks) async {
    await init();
    try {
      final file = File('$_appDir/marks.json');
      final list = marks.map((m) => m.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('saveMarks error: $e');
    }
  }
}
