import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0F766E); // Deep Teal (Govt/Tax feeling, professional)
  static const Color primaryLight = Color(0xFF14B8A6); // Bright Teal
  static const Color primaryDark = Color(0xFF115E59); // Dark Teal
  
  static const Color secondary = Color(0xFFF59E0B); // Amber / Gold
  static const Color accent = Color(0xFF8B5CF6); // Purple Accent for badges/charts

  // Neutral Colors (Light Theme)
  static const Color background = Color(0xFFF5F5F5); // Whitesmoke background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF475569); // Slate gray
  static const Color border = Color(0xFFE2E8F0); // Subtle gray border

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF0F172A); // Dark slate background
  static const Color surfaceDark = Color(0xFF1E293B); // Dark slate card
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Status/Alert Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Orange / Warning
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF3B82F6); // Blue
}
