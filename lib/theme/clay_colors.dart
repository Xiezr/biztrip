/// 黏土拟态风格 — 颜色常量
library;

import 'package:flutter/material.dart';

// ── 背景 / 表面 ─────────────────────────────────────
/// 页面背景色（比组件颜色略深，形成凸起对比）
const Color clayBg = Color(0xFFF0EDE8);

/// 组件表面色（凸起元素，与背景有明确区分度）
const Color claySurface = Color(0xFFF8F5F0);

/// 输入区域背景（略深于页面，形成内凹视觉层次）
const Color clayInputBg = Color(0xFFE9E4DD);

// ── 主紫色系 ───────────────────────────────────────
const Color clayPurple = Color(0xFF7F77DD);
const Color clayPurpleLight = Color(0xFFAFA9EC);
const Color clayPurpleLighter = Color(0xFFCECBF6);
const Color clayPurpleDark = Color(0xFF534AB7);
const Color clayPurpleDarker = Color(0xFF3C3489);

// ── 语义状态色 ─────────────────────────────────────
const Color claySuccess = Color(0xFF3D8B5F);   // 柔和绿 — 报销/完成
const Color clayWarning = Color(0xFFE8963A);   // 暖琥珀 — 提醒/跟进
const Color clayError = Color(0xFFD35F5F);     // 柔和红 — 删除/危险
const Color clayInfo = Color(0xFF5B8FBF);      // 柔和蓝 — 信息提示

// ── 节假日 ─────────────────────────────────────────
const Color clayHoliday = Color(0xFFE57373);   // 柔红 — 节假日"休"字

// ── 芯片特殊色 ────────────────────────────────────
const Color clayCream = Color(0xFFFDF4E8);     // 暖奶油 — 差旅标签 chip 背景
const Color clayInvoiceBg = Color(0xFFEBF2F8);  // 冷蓝灰 — 发票 chip 背景
const Color clayTeal = Color(0xFF0D9488);       // 青绿 — 报告通知图标

// ── 阴影用色 ───────────────────────────────────────
/// 外阴影暗色（光源从左上角照射，右下产生暗影）
const Color clayShadowDark = Color(0x33000000); // 20% 黑

/// 内高光亮色（左上角亮边，模拟光源反射）
const Color clayHighlight = Color(0xAAFFFFFF); // 67% 白

/// 内凹阴影（用于输入框、按下状态）—— 已弃用，使用 clayInnerShadowStrong
const Color clayInnerShadow = Color(0x1A000000); // 10% 黑

// ── 文字用色 ───────────────────────────────────────
const Color clayTextPrimary = Color(0xFF2C2C2A);
const Color clayTextSecondary = Color(0xFF5F5E5A);
const Color clayTextTertiary = Color(0xFF888780);

// ── 圆角 ───────────────────────────────────────────
const double clayRadius = 20.0;
const double clayRadiusSmall = 12.0;
const double clayRadiusLarge = 28.0;

// ── 阴影预设 ───────────────────────────────────────
/// 标准凸起阴影（用于卡片、按钮等凸起元素）
List<BoxShadow> get clayRaisedShadow => const [
      // 内高光（左上亮边）
      BoxShadow(
        color: clayHighlight,
        offset: Offset(-4, -4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      // 外阴影（右下暗边）
      BoxShadow(
        color: clayShadowDark,
        offset: Offset(5, 5),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];

/// 强力凸起阴影（用于 FAB、主要按钮）
List<BoxShadow> get clayRaisedShadowStrong => const [
      BoxShadow(
        color: clayHighlight,
        offset: Offset(-5, -5),
        blurRadius: 10,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: clayShadowDark,
        offset: Offset(6, 6),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ];

/// 内凹阴影（用于输入框、按下状态）
List<BoxShadow> get clayRecessedShadow => const [
      // 内阴影：右下暗边（模拟光线被遮挡）—— 略加深便于辨识边界
      BoxShadow(
        color: clayInnerShadowStrong,
        offset: Offset(3, 3),
        blurRadius: 5,
        spreadRadius: 0,
      ),
      // 内高光：左上亮边（模拟内壁反光）
      BoxShadow(
        color: clayInnerHighlight,
        offset: Offset(-1, -1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ];

/// 内凹暗影加强（略深于 clayInnerShadow，避免输入框溶于背景）
const Color clayInnerShadowStrong = Color(0x26000000); // 15% 黑

/// 内凹高亮色（左上亮边，模拟光源反射）
const Color clayInnerHighlight = Color(0x40FFFFFF); // 25% 白

/// 轻微凸起（用于小卡片、标签）
List<BoxShadow> get clayRaisedShadowLight => const [
      BoxShadow(
        color: clayHighlight,
        offset: Offset(-2, -2),
        blurRadius: 5,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x19000000), // 10% 黑
        offset: Offset(3, 3),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ];
