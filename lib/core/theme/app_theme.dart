import 'package:flutter/material.dart';

class AppTheme {
  // Light
  static const _lightBg = Color(0xFFF7F7F8); // page
  static const _lightSurface = Colors.white; // surfaces/cards/inputs
  static const _lightDivider = Color(0x14000000); // black with low alpha
  // Dark
  static const _darkBg = Color(0xFF0B0C10); // page background
  static const _darkSurface = Color(0xFF111318); // surface base
  static const _darkCard = Color(0xFF1E1F24); // cards, bubbles, inputs
  static const _darkDivider = Color(0x14FFFFFF); // white with low alpha
  static const _borderDark = Color(0xFF2F3239); // input borders

  static const _accent = Color(0xFF7C4DFF);

  // GoogleSansFlex için text theme oluşturma
  static TextTheme _googleSansFlexTextTheme(TextTheme base, Color color) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: 'GoogleSansFlex',
        color: color,
      ),
    );
  }

  // Alternatif: Tüm text theme'yi tek seferde uygulamak için
  static ThemeData _applyGoogleSansFlex(ThemeData theme, Color textColor) {
    return theme.copyWith(
      textTheme: theme.textTheme.apply(
        fontFamily: 'GoogleSansFlex',
        bodyColor: textColor,
        displayColor: textColor,
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
        surface: _lightSurface,
      ),
      scaffoldBackgroundColor: _lightBg,
      useMaterial3: true,
      fontFamily: 'GoogleSansFlex', // Burada global font family tanımlıyoruz
    );

    final theme = base.copyWith(
      // 1. Yöntem: Global font family kullanımı
      // textTheme: base.textTheme,

      // 2. Yöntem: Detaylı text theme özelleştirmesi
      textTheme: _googleSansFlexTextTheme(base.textTheme, Colors.black87),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontFamily: 'GoogleSansFlex',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      cardColor: _lightSurface,
      dividerColor: _lightDivider,
      iconTheme: IconThemeData(color: Colors.black87.withValues(alpha: 0.9)),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.black87.withValues(alpha: 0.9),
        textColor: Colors.black87.withValues(alpha: 0.92),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _lightSurface,
        side: BorderSide(color: _lightDivider),
        labelStyle: TextStyle(
          fontFamily: 'GoogleSansFlex',
          color: Colors.black87.withValues(alpha: 0.92),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _roundedBorder(_lightDivider),
        enabledBorder: _roundedBorder(_lightDivider),
        focusedBorder: _roundedBorder(_accent),
        hintStyle: const TextStyle(
          fontFamily: 'GoogleSansFlex',
          color: Color(0x73000000),
        ),
      ),
    );

    return _applyGoogleSansFlex(theme, Colors.black87.withValues(alpha: 0.92));
  }

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.dark,
        surface: _darkSurface,
      ),
      scaffoldBackgroundColor: _darkBg,
      useMaterial3: true,
      fontFamily: 'GoogleSansFlex',
    );

    final theme = base.copyWith(
      textTheme: _googleSansFlexTextTheme(
        base.textTheme,
        Colors.white.withValues(alpha: 0.92),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'GoogleSansFlex',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardColor: _darkCard,
      dividerColor: _darkDivider,
      iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.92)),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white.withValues(alpha: 0.92),
        textColor: Colors.white.withValues(alpha: 0.92),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _darkCard,
        side: BorderSide(color: _darkDivider),
        labelStyle: TextStyle(
          fontFamily: 'GoogleSansFlex',
          color: Colors.white.withValues(alpha: 0.92),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _roundedBorder(_borderDark),
        enabledBorder: _roundedBorder(_borderDark),
        focusedBorder: _roundedBorder(_accent),
        hintStyle: TextStyle(
          fontFamily: 'GoogleSansFlex',
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );

    return _applyGoogleSansFlex(theme, Colors.white.withValues(alpha: 0.92));
  }

  static OutlineInputBorder _roundedBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: 1),
  );
}
