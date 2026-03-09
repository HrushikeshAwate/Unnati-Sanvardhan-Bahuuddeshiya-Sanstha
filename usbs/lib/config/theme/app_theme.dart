// scaffold file
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSerif',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading.copyWith(fontSize: 30),
        headlineMedium: AppTextStyles.heading,
        titleLarge: AppTextStyles.title,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Color(0x12000000),
        elevation: 1.5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'NotoSerif',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'NotoSerif',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        prefixIconColor: AppColors.primary,
        labelStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: AppTextStyles.caption,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softTeal,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.title.copyWith(fontSize: 16),
        subtitleTextStyle: AppTextStyles.caption,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: const Color(0xFF6FB4E8),
      secondary: const Color(0xFFE0B67A),
      brightness: Brightness.dark,
      surface: const Color(0xFF1A2330),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSerif',
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF111821),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D5F58),
        surfaceTintColor: Color(0xFF0D5F58),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading.copyWith(
          fontSize: 30,
          color: Colors.white,
        ),
        headlineMedium: AppTextStyles.heading.copyWith(color: Colors.white),
        titleLarge: AppTextStyles.title.copyWith(color: Colors.white),
        bodyMedium: AppTextStyles.body.copyWith(color: const Color(0xFFE3E9F2)),
        bodySmall: AppTextStyles.caption.copyWith(color: const Color(0xFFB5C0CF)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2330),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black45,
        elevation: 1.5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B78A9),
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'NotoSerif',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6FB4E8)),
          foregroundColor: const Color(0xFF9BD0F7),
          textStyle: const TextStyle(
            fontFamily: 'NotoSerif',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF202B3A),
        filled: true,
        prefixIconColor: const Color(0xFF9BD0F7),
        labelStyle: AppTextStyles.body.copyWith(
          color: const Color(0xFFE3E9F2),
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: AppTextStyles.caption.copyWith(color: const Color(0xFFA7B3C4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2F3D50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6FB4E8), width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF213246),
        side: const BorderSide(color: Color(0xFF2F3D50)),
        labelStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2F3D50),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: const Color(0xFF9BD0F7),
        textColor: Colors.white,
        titleTextStyle: AppTextStyles.title.copyWith(
          fontSize: 16,
          color: Colors.white,
        ),
        subtitleTextStyle: AppTextStyles.caption.copyWith(
          color: const Color(0xFFA7B3C4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
