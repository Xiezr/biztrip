import 'package:flutter/foundation.dart';

enum ViewMode { year, month }

class CalendarProvider extends ChangeNotifier {
  int _year;
  int _month;
  ViewMode _viewMode = ViewMode.year;
  int? _activeLocationId;
  bool _swipeLocked = false;

  CalendarProvider()
      : _year = DateTime.now().year,
        _month = DateTime.now().month,
        _minYear = DateTime.now().year - 1,
        _maxYear = DateTime.now().year;

  int get year => _year;
  int get month => _month;
  ViewMode get viewMode => _viewMode;
  int? get activeLocationId => _activeLocationId;
  bool get swipeLocked => _swipeLocked;

  void setYear(int y) {
    if (y < _minYear) y = _minYear;
    if (y > _maxYear) y = _maxYear;
    _year = y;
    notifyListeners();
  }

  int get minYear => _minYear;
  int get maxYear => _maxYear;

  final int _minYear;
  final int _maxYear;

  void setMonth(int m) {
    _month = m;
    notifyListeners();
  }

  void goToPreviousMonth() {
    _month--;
    if (_month < 1) {
      _month = 12;
      if (_year > _minYear) _year--;
    }
    notifyListeners();
  }

  void goToNextMonth() {
    _month++;
    if (_month > 12) {
      _month = 1;
      if (_year < _maxYear) _year++;
    }
    notifyListeners();
  }

  void goToMonth(int y, int m) {
    _year = y;
    _month = m;
    notifyListeners();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void setActiveLocation(int? id) {
    if (_activeLocationId == id) {
      _activeLocationId = null; // 点击已激活的 → 取消
    } else {
      _activeLocationId = id;
    }
    notifyListeners();
  }

  void clearActiveLocation() {
    _activeLocationId = null;
    notifyListeners();
  }

  void lockSwipe() {
    _swipeLocked = true;
  }

  void unlockSwipe() {
    _swipeLocked = false;
    notifyListeners();
  }
}
