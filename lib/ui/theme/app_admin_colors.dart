import 'package:flutter/material.dart';

/// Color tokens for the admin panel dark theme.
///
/// Intentionally separate from [AppColors] — the admin panel uses a
/// dark theme independent of the kiosk application theme.
class AdminColors {
  static const Color background = Color(0xFF0B1020);
  static const Color cardBackground = Color(0xFF141A2E);
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB9C0D4);
  static const Color accent = Color(0xFF4DA3FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);
  static const Color divider = Color(0x33B9C0D4);
  static const Color tabBarBackground = Color(0xFF080D18); // daha koyu — TabBar
  static const Color appBarBackground = Color(0xFF060A14); // en koyu — AppBar
}
