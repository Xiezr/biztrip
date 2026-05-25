import 'dart:ui';

/// 目的地类型（固定 vs 临时）
enum LocationType { fixed, temporary }

/// 目的地作用域：替代 year==null 的隐式约定
enum LocationScope {
  /// 全局固定目的地，所有月份可见
  global,
  /// 按年作用域（预留扩展）
  year,
  /// 按月作用域，需配合 scopedYear + scopedMonth 使用
  month,
}

class TravelLocation {
  final int? id;
  final String name;
  final Color color;
  final LocationType type;
  final int sortOrder;

  /// 作用域（替代原来的 year/month 隐式约定）
  final LocationScope scope;

  /// 当 scope==month 时有效
  final int? scopedYear;

  /// 当 scope==month 时有效
  final int? scopedMonth;

  // 差旅配置（所有天数：正数表示"后"，用 UI ± 号显示方向）
  final int notificationDaysBefore;   // 差旅通知 (-N天)
  final int followUpDaysAfter;        // 差旅跟进 (+N天)
  final List<String> preparationTags; // 差旅准备
  final int reimbursementDaysAfter;   // 票据报销 (+N天)
  final int confirmationDaysBefore;   // 差旅确认 (-N天)
  final int reportDaysAfter;          // 差旅报告 (+N天)
  final List<String> specialReminder; // 本次差旅特别提醒（分行列表）
  final List<String> invoicePaths;    // 单据扫描图片路径

  const TravelLocation({
    this.id,
    required this.name,
    required this.color,
    this.type = LocationType.fixed,
    this.sortOrder = 0,
    this.scope = LocationScope.global,
    this.scopedYear,
    this.scopedMonth,
    this.notificationDaysBefore = 7,
    this.followUpDaysAfter = 3,
    this.preparationTags = const [
      '联络当地人员', '交通安排', '行李安排',
      '酒店住宿', '天气预警', '票据留存',
    ],
    this.reimbursementDaysAfter = 7,
    this.confirmationDaysBefore = 1,
    this.reportDaysAfter = 3,
    this.specialReminder = const ['证件+电子产品+衣袜+洗护', '差旅相关文件+物资'],
    this.invoicePaths = const [],
  });

  /// 兼容旧数据：从 year/month 推导航 scope
  static LocationScope _scopeFromYearMonth(int? year, int? month) {
    if (year == null) return LocationScope.global;
    return LocationScope.month;
  }

  /// 判断该目的地是否属于指定年月
  bool belongsTo(int year, int month) {
    if (scope == LocationScope.global) return true;
    return scopedYear == year && scopedMonth == month;
  }

  TravelLocation copyWith({
    int? id,
    String? name,
    Color? color,
    LocationType? type,
    int? sortOrder,
    LocationScope? scope,
    int? scopedYear,
    int? scopedMonth,
    int? notificationDaysBefore,
    int? followUpDaysAfter,
    List<String>? preparationTags,
    int? reimbursementDaysAfter,
    int? confirmationDaysBefore,
    int? reportDaysAfter,
    List<String>? specialReminder,
    List<String>? invoicePaths,
  }) {
    return TravelLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      scope: scope ?? this.scope,
      scopedYear: scopedYear ?? this.scopedYear,
      scopedMonth: scopedMonth ?? this.scopedMonth,
      notificationDaysBefore: notificationDaysBefore ?? this.notificationDaysBefore,
      followUpDaysAfter: followUpDaysAfter ?? this.followUpDaysAfter,
      preparationTags: preparationTags ?? this.preparationTags,
      reimbursementDaysAfter: reimbursementDaysAfter ?? this.reimbursementDaysAfter,
      confirmationDaysBefore: confirmationDaysBefore ?? this.confirmationDaysBefore,
      reportDaysAfter: reportDaysAfter ?? this.reportDaysAfter,
      specialReminder: specialReminder ?? this.specialReminder,
      invoicePaths: invoicePaths ?? this.invoicePaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'type': type.name,
        'scope': scope.name,
        'scopedYear': scopedYear,
        'scopedMonth': scopedMonth,
        'notificationDaysBefore': notificationDaysBefore,
        'followUpDaysAfter': followUpDaysAfter,
        'preparationTags': preparationTags,
        'reimbursementDaysAfter': reimbursementDaysAfter,
        'confirmationDaysBefore': confirmationDaysBefore,
        'reportDaysAfter': reportDaysAfter,
        'specialReminder': specialReminder,
        'invoicePaths': invoicePaths,
      };

  factory TravelLocation.fromJson(Map<String, dynamic> json) {
    // 兼容旧版数据：有 year 字段且为 null → global；有值 → month
    final legacyYear = json['year'] as int?;
    final legacyMonth = json['month'] as int?;
    final scopeStr = json['scope'] as String?;
    final LocationScope scope;
    final int? sy;
    final int? sm;
    if (scopeStr != null) {
      scope = LocationScope.values.byName(scopeStr);
      sy = json['scopedYear'] as int?;
      sm = json['scopedMonth'] as int?;
    } else {
      // 旧数据迁移
      scope = _scopeFromYearMonth(legacyYear, legacyMonth);
      sy = legacyYear;
      sm = legacyMonth;
    }

    return TravelLocation(
      id: json['id'] as int?,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      type: LocationType.values.byName(json['type'] as String? ?? 'fixed'),
      sortOrder: json['sortOrder'] as int? ?? 0,
      scope: scope,
      scopedYear: sy,
      scopedMonth: sm,
      notificationDaysBefore: json['notificationDaysBefore'] as int? ?? 7,
      followUpDaysAfter: json['followUpDaysAfter'] as int? ?? 3,
      preparationTags: _migrateTags((json['preparationTags'] as List<dynamic>?)?.map((e) => e as String).toList()),
      reimbursementDaysAfter: json['reimbursementDaysAfter'] as int? ?? 7,
      confirmationDaysBefore: json['confirmationDaysBefore'] as int? ?? 1,
      reportDaysAfter: json['reportDaysAfter'] as int? ?? 3,
      specialReminder: _parseSpecialReminder(json['specialReminder']),
      invoicePaths: (json['invoicePaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  /// 标签迁移：旧版旧标签替换为新默认
  static List<String> _migrateTags(List<String>? tags) {
    if (tags == null) return ['联络当地人员', '交通安排', '行李安排', '酒店住宿', '天气预警', '票据留存'];
    // 检测是否还包含旧的默认标签（只有2个或包含旧词）
    if (tags.length <= 2 && tags.every((t) => ['联络', '出行安排', '联络当地人员', '交通安排'].contains(t))) {
      return ['联络当地人员', '交通安排', '行李安排', '酒店住宿', '天气预警', '票据留存'];
    }
    return tags;
  }

  /// 兼容旧版 String 和新版 List of String
  static List<String> _parseSpecialReminder(dynamic value) {
    if (value is List) {
      final list = value.map((e) => e as String).toList();
      // 迁移：旧版空行替换为默认值
      if (list.every((s) => s.isEmpty) || list.length < 2) {
        return ['证件+电子产品+衣袜+洗护', '差旅相关文件+物资'];
      }
      return list;
    }
    if (value is String) return value.isEmpty ? ['证件+电子产品+衣袜+洗护', '差旅相关文件+物资'] : [value];
    return ['证件+电子产品+衣袜+洗护', '差旅相关文件+物资'];
  }

  static const presetColors = [
    Color(0xFFFF9500), Color(0xFFFF6D00), Color(0xFFFF3B00), Color(0xFFFF7A00), Color(0xFFFFB340),
    Color(0xFF34C759), Color(0xFF30D158), Color(0xFF28A745), Color(0xFF00B84A), Color(0xFF5EEA7E),
    Color(0xFF007AFF), Color(0xFF0066EA), Color(0xFF0055D4), Color(0xFF3B82F6), Color(0xFF60A5FA),
    Color(0xFFFF2D55), Color(0xFFFF3B6E), Color(0xFFFF6482), Color(0xFFE02D4E), Color(0xFFFF8FA8),
    Color(0xFFAF52DE), Color(0xFF8944C4), Color(0xFF7B2D8E), Color(0xFFBF5AF2), Color(0xFFD580FF),
  ];

  /// 色系分组，用于颜色选择器
  static const Map<String, List<Color>> colorFamilies = {
    '橙': [Color(0xFFFF9500), Color(0xFFFF6D00), Color(0xFFFF3B00), Color(0xFFFF7A00), Color(0xFFFFB340)],
    '绿': [Color(0xFF34C759), Color(0xFF30D158), Color(0xFF28A745), Color(0xFF00B84A), Color(0xFF5EEA7E)],
    '蓝': [Color(0xFF007AFF), Color(0xFF0066EA), Color(0xFF0055D4), Color(0xFF3B82F6), Color(0xFF60A5FA)],
    '粉': [Color(0xFFFF2D55), Color(0xFFFF3B6E), Color(0xFFFF6482), Color(0xFFE02D4E), Color(0xFFFF8FA8)],
    '紫': [Color(0xFFAF52DE), Color(0xFF8944C4), Color(0xFF7B2D8E), Color(0xFFBF5AF2), Color(0xFFD580FF)],
  };
}
