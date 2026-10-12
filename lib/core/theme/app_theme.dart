import 'package:flutter/material.dart';

/// App colors. Neutral colors follow the current appearance (light/dark);
/// call [AppColors.setDark] when it changes and rebuild the widget tree.
abstract final class AppColors {
  static bool _isDark = false;

  static bool get isDark => _isDark;

  static void setDark(bool value) => _isDark = value;

  /// Brand navy for filled buttons, chips, and circles. Same in both modes.
  static const brand = Color(0xFF253858);

  /// Primary text and icon color.
  static Color get navy =>
      _isDark ? const Color(0xFFE8EEF6) : const Color(0xFF253858);
  static Color get background =>
      _isDark ? const Color(0xFF151A22) : const Color(0xFFF3F3F3);

  /// Card and input surface.
  static Color get white =>
      _isDark ? const Color(0xFF222A35) : const Color(0xFFFFFFFF);
  static Color get secondaryText =>
      _isDark ? const Color(0xFFA6B2C3) : const Color(0xFF7A8494);
  static Color get border =>
      _isDark ? const Color(0xFF353F4D) : const Color(0xFFE2E7ED);
  static Color get warmCream =>
      _isDark ? const Color(0xFF2A2F38) : const Color(0xFFF4F1E6);

  static const skyBlue = Color(0xFF6FA8DC);
  static const sageGreen = Color(0xFF89BC9A);
  static const highPriority = Color(0xFFE98989);
  static const mediumPriority = Color(0xFFE6B85C);
  static const lowPriority = Color(0xFF89BC9A);
}

abstract final class AppTheme {
  static ThemeData get light => build(dark: false);

  static ThemeData get dark => build(dark: true);

  /// Builds the theme for one appearance. Temporarily switches [AppColors]
  /// so its neutral colors resolve for that mode, then restores it.
  static ThemeData build({required bool dark}) {
    final previous = AppColors.isDark;
    AppColors.setDark(dark);
    try {
      return _build(dark ? Brightness.dark : Brightness.light);
    } finally {
      AppColors.setDark(previous);
    }
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary: isDark ? AppColors.skyBlue : AppColors.brand,
      secondary: AppColors.skyBlue,
      surface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.skyBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.highPriority),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.white),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.navy,
        iconColor: AppColors.navy,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.white),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.skyBlue.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.navy
                : AppColors.secondaryText,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.navy
                : AppColors.secondaryText,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          );
        }),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.navy),
        bodyMedium: TextStyle(color: AppColors.navy),
        bodySmall: TextStyle(color: AppColors.secondaryText),
      ),
    );
  }
}
