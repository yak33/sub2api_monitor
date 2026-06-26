import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sub2API Monitor — "Dual-Plane Precision" 设计系统。
///
/// 暗色模式：Obsidian Command — 深空黑底 + 琥珀金数据 + 冰蓝交互。
/// 浅色模式：Precision Lab — 暖白底色 + 靛蓝数据 + 清晰线条。
/// 两套模式共享同一结构与排版，仅 ColorScheme 切换。
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════
  //  品牌色（不随主题变化 — 用于平台标识等）
  // ═══════════════════════════════════════════════
  static const openaiGreen = Color(0xFF10A37F);
  static const anthropicOrange = Color(0xFFD97757);
  static const geminiBlue = Color(0xFF4285F4);
  static const antigravityPurple = Color(0xFFA855F7);

  // ═══════════════════════════════════════════════
  //  浅色色板 — Precision Lab
  // ═══════════════════════════════════════════════
  static const _lightPrimary = Color(0xFF2D3FF5);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightPrimaryContainer = Color(0xFFDEE0FF);
  static const _lightSecondary = Color(0xFF00897B);
  static const _lightOnSecondary = Color(0xFFFFFFFF);
  static const _lightTertiary = Color(0xFF7C3AED);
  static const _lightOnTertiary = Color(0xFFFFFFFF);
  static const _lightError = Color(0xFFD32F2F);
  static const _lightOnError = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFFCFAF7);
  static const _lightOnSurface = Color(0xFF1A1C2E);
  static const _lightOnSurfaceVariant = Color(0xFF5F6368);
  static const _lightOutline = Color(0xFFC8C5BD);
  static const _lightOutlineVariant = Color(0xFFDFDCD4);
  static const _lightScaffoldBg = Color(0xFFF3F2EE);
  static const _lightSurfaceContainerLowest = Color(0xFFEEECE6);
  static const _lightSurfaceContainerLow = Color(0xFFF8F7F3);
  static const _lightSurfaceContainer = Color(0xFFF3F2EE);
  static const _lightSurfaceContainerHigh = Color(0xFFECEAE4);
  static const _lightSurfaceContainerHighest = Color(0xFFE5E3DB);

  // ═══════════════════════════════════════════════
  //  暗色色板 — Obsidian Command
  // ═══════════════════════════════════════════════
  static const _darkPrimary = Color(0xFFF0A500);
  static const _darkOnPrimary = Color(0xFF000000);
  static const _darkPrimaryContainer = Color(0xFF3D2A00);
  static const _darkSecondary = Color(0xFF4FC3F7);
  static const _darkOnSecondary = Color(0xFF000000);
  static const _darkTertiary = Color(0xFFA78BFA);
  static const _darkOnTertiary = Color(0xFF000000);
  static const _darkError = Color(0xFFFF5252);
  static const _darkOnError = Color(0xFF000000);
  static const _darkSurface = Color(0xFF101323);
  static const _darkOnSurface = Color(0xFFE8E6E3);
  static const _darkOnSurfaceVariant = Color(0xFF8286A6);
  static const _darkOutline = Color(0xFF252B4A);
  static const _darkOutlineVariant = Color(0xFF1A1F3A);
  static const _darkScaffoldBg = Color(0xFF0A0C18);
  static const _darkSurfaceContainerLowest = Color(0xFF080A14);
  static const _darkSurfaceContainerLow = Color(0xFF0D0F1C);
  static const _darkSurfaceContainer = Color(0xFF161B33);
  static const _darkSurfaceContainerHigh = Color(0xFF1C2240);
  static const _darkSurfaceContainerHighest = Color(0xFF22284A);

  // ═══════════════════════════════════════════════
  //  排版
  // ═══════════════════════════════════════════════

  static TextTheme _textTheme(Brightness b) {
    final c = b == Brightness.dark ? _darkOnSurface : _lightOnSurface;
    final c2 = b == Brightness.dark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant;
    return GoogleFonts.dmSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: c, height: 1.1),
      headlineMedium: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: c, height: 1.2),
      headlineSmall: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c),
      titleLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: c),
      titleMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: c),
      titleSmall: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: c2),
      bodyLarge: GoogleFonts.dmSans(fontSize: 16, height: 1.5, color: c),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: c),
      bodySmall: GoogleFonts.dmSans(fontSize: 12, color: c2, height: 1.4),
      labelLarge: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: c2),
      labelMedium: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: c2),
      labelSmall: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: c2),
    );
  }

  /// 等宽数据数字 — JetBrains Mono。
  static TextStyle monoData({double size = 14, required Color color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.5);

  /// 展示级标题 — Rajdhani。
  static TextStyle display({double size = 28, Color? color}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: 2);

  // ═══════════════════════════════════════════════
  //  装饰/图表/状态色（双模通用，不随主题切换）
  // ═══════════════════════════════════════════════
  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartPurple = Color(0xFF8B5CF6);
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartCyan = Color(0xFF06B6D4);
  static const Color chartAmber = Color(0xFFF59E0B);
  static const Color chartRed = Color(0xFFEF4444);

  // 向后兼容别名（原品牌色，页面/chart 中大量引用）
  static const Color accent = chartCyan;
  static const Color success = chartGreen;
  static const Color warning = chartAmber;
  static const Color error = chartRed;
  static const Color info = chartBlue;
  static const Color primary = chartPurple;

  // ═══════════════════════════════════════════════
  //  ThemeData 构建
  // ═══════════════════════════════════════════════

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ColorScheme _colorScheme(Brightness b) {
    final d = b == Brightness.dark;
    return ColorScheme(
      brightness: b,
      primary: d ? _darkPrimary : _lightPrimary,
      onPrimary: d ? _darkOnPrimary : _lightOnPrimary,
      primaryContainer: d ? _darkPrimaryContainer : _lightPrimaryContainer,
      onPrimaryContainer: d ? _darkPrimary : _lightPrimary,
      secondary: d ? _darkSecondary : _lightSecondary,
      onSecondary: d ? _darkOnSecondary : _lightOnSecondary,
      secondaryContainer: d ? const Color(0xFF0D3B4F) : const Color(0xFFB2DFDB),
      onSecondaryContainer: d ? _darkSecondary : _lightSecondary,
      tertiary: d ? _darkTertiary : _lightTertiary,
      onTertiary: d ? _darkOnTertiary : _lightOnTertiary,
      tertiaryContainer: d ? const Color(0xFF2D1B69) : const Color(0xFFEDE7F6),
      onTertiaryContainer: d ? _darkTertiary : _lightTertiary,
      error: d ? _darkError : _lightError,
      onError: d ? _darkOnError : _lightOnError,
      errorContainer: d ? const Color(0xFF4A1515) : const Color(0xFFFFEBEE),
      onErrorContainer: d ? _darkError : _lightError,
      surface: d ? _darkSurface : _lightSurface,
      onSurface: d ? _darkOnSurface : _lightOnSurface,
      onSurfaceVariant: d ? _darkOnSurfaceVariant : _lightOnSurfaceVariant,
      outline: d ? _darkOutline : _lightOutline,
      outlineVariant: d ? _darkOutlineVariant : _lightOutlineVariant,
      surfaceContainerLowest: d ? _darkSurfaceContainerLowest : _lightSurfaceContainerLowest,
      surfaceContainerLow: d ? _darkSurfaceContainerLow : _lightSurfaceContainerLow,
      surfaceContainer: d ? _darkSurfaceContainer : _lightSurfaceContainer,
      surfaceContainerHigh: d ? _darkSurfaceContainerHigh : _lightSurfaceContainerHigh,
      surfaceContainerHighest: d ? _darkSurfaceContainerHighest : _lightSurfaceContainerHighest,
      surfaceDim: d ? _darkSurfaceContainerLowest : _lightSurfaceContainerLow,
      surfaceBright: d ? _darkSurfaceContainer : _lightSurface,
      inverseSurface: d ? _darkOnSurface : _lightOnSurface,
      onInverseSurface: d ? _darkSurfaceContainerLowest : _lightSurface,
      inversePrimary: d ? const Color(0xFF3D2A00) : _lightPrimaryContainer,
      shadow: Colors.black26,
      scrim: Colors.black54,
    );
  }

  static ThemeData _build(Brightness b) {
    final d = b == Brightness.dark;
    final cs = _colorScheme(b);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: cs,
      scaffoldBackgroundColor: d ? _darkScaffoldBg : _lightScaffoldBg,
      textTheme: _textTheme(b),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        surfaceTintColor: Colors.transparent,
        // 浅色模式：状态栏用深色图标；暗色模式：用浅色图标
        systemOverlayStyle: d
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant, width: 1)),
        margin: EdgeInsets.zero,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: d ? _darkSurface.withValues(alpha: 0.95) : _lightSurface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
        selectedIconTheme: const IconThemeData(size: 22),
        unselectedIconTheme: const IconThemeData(size: 20),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return d ? const Color(0xFF0D0F1E) : const Color(0xFFE5E3DB);
          }
          return d ? const Color(0xFF151829) : Colors.white;
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.error)),
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        prefixIconColor: cs.onSurfaceVariant,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.surfaceContainerHighest,
          disabledForegroundColor: cs.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
        secondaryLabelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: cs.outlineVariant),
        checkmarkColor: cs.primary,
      ),

      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        contentTextStyle: GoogleFonts.dmSans(fontSize: 13, color: cs.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  装饰辅助（需传 ColorScheme）
  // ═══════════════════════════════════════════════

  static BoxDecoration cardDecoration(ColorScheme cs) => BoxDecoration(
    color: cs.surfaceContainerLow,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: cs.outlineVariant),
  );

  static BoxDecoration panelDecoration(ColorScheme cs) => BoxDecoration(
    color: cs.surfaceContainer,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: cs.outline),
  );

  static BoxDecoration elevatedDecoration(ColorScheme cs) => BoxDecoration(
    color: cs.surfaceContainer,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: cs.outline),
  );
}
