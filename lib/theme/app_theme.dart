import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand identity colours ──
  static const _accent = Color(0xFF6366F1); // indigo
  static const _accentDark = Color(0xFF818CF8);

  // ────────────────────────────────────────────
  // LIGHT THEME
  // ────────────────────────────────────────────
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
      primary: _accent,
      secondary: _accentDark,
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
    );
  }

  // ────────────────────────────────────────────
  // DARK THEME
  // ────────────────────────────────────────────
  static ThemeData get dark {
    const bg = Color(0xFF050C1A);
    const surface = Color(0xFF0D1526);
    const card = Color(0xFF111C30);
    const border = Color(0xFF1E2D47);

    final base = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      primary: _accentDark,
      secondary: _accent,
      surface: bg,
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerHighest: card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: const Color(0xFFCBD5E1),
        displayColor: const Color(0xFFF1F5F9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFFF1F5F9),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBarrierColor: Colors.black.withValues(alpha: 0.7),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      dividerColor: border,
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF94A3B8),
        textColor: Color(0xFFCBD5E1),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
    );
  }

  // ── Utility: card background colour for current theme ──
  static Color cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF111C30) : Colors.white;
  }

  static Color cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E2D47) : Colors.white.withValues(alpha: 0.7);
  }

  static Color surfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF050C1A) : const Color(0xFFF8FAFC);
  }

  static Color mutedText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
  }

  static Color subtleText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
  }
}
