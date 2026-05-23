import 'dart:ui';

enum LocationType { fixed, temporary }

class TravelLocation {
  final int? id;
  final String name;
  final Color color;
  final LocationType type;
  final int sortOrder;
  final int? year;    // 所属年（null=所有月可见，即固定目的地）
  final int? month;   // 所属月（null=所有月可见）

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
    this.year,
    this.month,
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

  TravelLocation copyWith({
    int? id,
    String? name,
    Color? color,
    LocationType? type,
    int? sortOrder,
    int? year,
    int? month,
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
      year: year ?? this.year,
      month: month ?? this.month,
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
        'sortOrder': sortOrder,
        'year': year,
        'month': month,
        'notificationDaysBefore': notificationDaysBefore,
        'followUpDaysAfter': followUpDaysAfter,
        'preparationTags': preparationTags,
        'reimbursementDaysAfter': reimbursementDaysAfter,
        'confirmationDaysBefore': confirmationDaysBefore,
        'reportDaysAfter': reportDaysAfter,
        'specialReminder': specialReminder,
        'invoicePaths': invoicePaths,
      };

  factory TravelLocation.fromJson(Map<String, dynamic> json) => TravelLocation(
        id: json['id'] as int?,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        type: LocationType.values.byName(json['type'] as String),
        sortOrder: json['sortOrder'] as int? ?? 0,
        year: json['year'] as int?,
        month: json['month'] as int?,
        notificationDaysBefore: json['notificationDaysBefore'] as int? ?? 7,
        followUpDaysAfter: json['followUpDaysAfter'] as int? ?? 3,
        preparationTags: _migrateTags((json['preparationTags'] as List<dynamic>?)?.map((e) => e as String).toList()),
        reimbursementDaysAfter: json['reimbursementDaysAfter'] as int? ?? 7,
        confirmationDaysBefore: json['confirmationDaysBefore'] as int? ?? 1,
        reportDaysAfter: json['reportDaysAfter'] as int? ?? 3,
        specialReminder: _parseSpecialReminder(json['specialReminder']),
        invoicePaths: (json['invoicePaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      );

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
    Color(0xFFFF6600), Color(0xFFFF9900), Color(0xFFFF3300), Color(0xFFCC5200), Color(0xFFFFBB77),
    Color(0xFF229922), Color(0xFF00CC00), Color(0xFF339933), Color(0xFF006600), Color(0xFFAAFFAA),
    Color(0xFF0055AA), Color(0xFF0066CC), Color(0xFF3399FF), Color(0xFF003399), Color(0xFFAADDFF),
    Color(0xFFDD3377), Color(0xFFFF6699), Color(0xFFFF99CC), Color(0xFFCC3366), Color(0xFFFFCCDD),
  ];

  /// 色系分组，用于颜色选择器
  static const Map<String, List<Color>> colorFamilies = {
    '橙': [Color(0xFFFF6600), Color(0xFFFF9900), Color(0xFFFF3300), Color(0xFFCC5200), Color(0xFFFFBB77)],
    '绿': [Color(0xFF229922), Color(0xFF00CC00), Color(0xFF339933), Color(0xFF006600), Color(0xFFAAFFAA)],
    '蓝': [Color(0xFF0055AA), Color(0xFF0066CC), Color(0xFF3399FF), Color(0xFF003399), Color(0xFFAADDFF)],
    '粉': [Color(0xFFDD3377), Color(0xFFFF6699), Color(0xFFFF99CC), Color(0xFFCC3366), Color(0xFFFFCCDD)],
  };
}
