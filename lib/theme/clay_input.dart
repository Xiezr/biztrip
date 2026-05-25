/// 黏土拟态风格 — 输入组件
library;

import 'package:flutter/material.dart';
import 'clay_colors.dart';

/// 内凹黏土输入框
class ClayTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const ClayTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: clayInputBg, // 内凹：用输入底色（略深于页面背景）
        borderRadius: BorderRadius.circular(clayRadius),
        boxShadow: clayRecessedShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: clayTextTertiary, fontSize: 13),
          border: InputBorder.none,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 13, color: clayTextPrimary),
      ),
    );
  }
}

