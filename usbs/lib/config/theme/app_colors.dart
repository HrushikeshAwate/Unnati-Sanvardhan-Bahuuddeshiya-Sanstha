import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF115E59);
  static const Color accent = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF5F7FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2433);
  static const Color textMuted = Color(0xFF6A7485);
  static const Color border = Color(0xFFE1E6EF);
  static const Color softTeal = Color(0xFFE5F3F4);
  static const Color softAmber = Color(0xFFFFF2D8);
  static const Color softRed = Color(0xFFFFE8E7);
  static const Color statusUnanswered = Color(0xFFC62828);
  static const Color statusAnswered = Color(0xFF2E7D32);
  static const Color statusInProgress = Color(0xFFF4C542);
  static const Color error = Colors.red;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static LinearGradient pageGradient(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF111821), Color(0xFF162233)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF0F4FA), Color(0xFFF8FAFF)],
    );
  }

  static LinearGradient pageGradientSoft(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF111821), Color(0xFF1A2638), Color(0xFF202D40)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF0F4FA), Color(0xFFF7F9FC), Color(0xFFFFFFFF)],
    );
  }

  static Color elevatedSurface(BuildContext context) {
    return isDark(context) ? const Color(0xFF1A2330) : Colors.white;
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'answered':
        return statusAnswered;
      case 'in_progress':
        return statusInProgress;
      case 'unanswered':
      default:
        return statusUnanswered;
    }
  }
}
