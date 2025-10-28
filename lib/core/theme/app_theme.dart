import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ChatGPT-like palette tokens
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

  // Accent: ChatGPT uses a purple accent for actions like Plus
  static const _accent = Color(0xFF7C4DFF);

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
    );

    return base.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: Colors.black87,
      ),
      cardColor: _lightSurface,
      dividerColor: _lightDivider,
      iconTheme: IconThemeData(color: Colors.black87.withValues(alpha: 0.9)),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.black87.withValues(alpha: 0.9),
        textColor: Colors.black87.withValues(alpha: 0.92),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _lightSurface,
        side: BorderSide(color: _lightDivider),
        labelStyle: base.textTheme.bodyMedium,
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
        hintStyle: const TextStyle(color: Color(0x73000000)), // black45
      ),
    );
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
    );

    return base.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(
        bodyColor: Colors.white.withValues(alpha: 0.92),
        displayColor: Colors.white.withValues(alpha: 0.92),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: Colors.white,
      ),
      cardColor: _darkCard,
      dividerColor: _darkDivider,
      iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.92)),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white.withValues(alpha: 0.92),
        textColor: Colors.white.withValues(alpha: 0.92),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _darkCard,
        side: BorderSide(color: _darkDivider),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
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
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }

  static OutlineInputBorder _roundedBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: 1),
  );
}
