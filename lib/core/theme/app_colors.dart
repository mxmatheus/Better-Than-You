import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF141419);
  static const Color surfaceElevated = Color(0xFF1C1C24);
  static const Color surfaceBorder = Color(0xFF262636);
  static const Color surfaceBorderLight = Color(0xFF38384E);

  // Brand / Accents
  static const Color primary = Color(0xFF00E676); // Emerald Win / Ready
  static const Color primaryDim = Color(0xFF00B057);
  static const Color accent = Color(0xFF00E5FF); // Cyan

  // Competitive State Colors
  static const Color win = Color(0xFF00E676); // Vibrant Green
  static const Color loss = Color(0xFFFF1744); // Electric Crimson
  static const Color draw = Color(0xFFFFD600); // Amber Yellow
  static const Color opponent = Color(0xFFFF5252); // Reddish-Coral for Opponent

  // Neutral Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B2);
  static const Color textMuted = Color(0xFF5A5A70);

  // Challenge Trigger
  static const Color triggerWait = Color(0xFFFF1744);
  static const Color triggerGo = Color(0xFF00E676);
}
