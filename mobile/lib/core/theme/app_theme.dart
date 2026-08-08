import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tarang Design System — Theme
///
/// All values are taken directly from the Web Application's globals.css.
/// Do NOT change these values without cross-referencing the web source of truth.
class AppTheme {
  AppTheme._();

  // ─── Brand Palette (Light Mode) ──────────────────────────────────────────
  /// Primary: Signature Teal — web: #0D9488 (--primary light)
  static const Color primaryTeal = Color(0xFF0D9488);

  /// Primary Light: Glowing Teal — web: #14B8A6 (--primary dark / light accent)
  static const Color primaryTealLight = Color(0xFF14B8A6);

  /// Ocean Blue — web: #0B4F8C (--secondary / --ocean light)
  static const Color oceanBlue = Color(0xFF0B4F8C);

  /// Ocean Blue Dark — web: #0F4C81 (--secondary dark)
  static const Color oceanBlueDark = Color(0xFF0F4C81);

  /// Foam / Accent — web: #2DD4BF (--accent / --foam light)
  static const Color foam = Color(0xFF2DD4BF);

  /// Foam Dark — web: #6EE7E7 (--accent / --foam dark)
  static const Color foamDark = Color(0xFF6EE7E7);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  /// Success — web: #10B981 (light), #34D399 (dark)
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);

  /// Warning — web: #F59E0B (light), #FBBF24 (dark)
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

  /// Danger — web: #EF4444 (light), #F87171 (dark)
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFF87171);

  // ─── Light Theme Surfaces ─────────────────────────────────────────────────
  /// web: --background: #F8FAFC
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// web: --foreground: #0F172A
  static const Color lightForeground = Color(0xFF0F172A);

  /// web: --surface: #FFFFFF
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// web: --card-bg: #FFFFFF
  static const Color lightCard = Color(0xFFFFFFFF);

  /// web: --card-border: #E2E8F0
  static const Color lightCardBorder = Color(0xFFE2E8F0);

  // ─── Dark Theme Surfaces ──────────────────────────────────────────────────
  /// web: --background dark: #08131E
  static const Color darkBackground = Color(0xFF08131E);

  /// web: --foreground dark: #F8FBFD
  static const Color darkForeground = Color(0xFFF8FBFD);

  /// web: --surface dark: #0B1824
  static const Color darkSurface = Color(0xFF0B1824);

  /// web: --card-bg dark: #0F1E2E
  static const Color darkCard = Color(0xFF0F1E2E);

  /// web: --card-border dark: #1E2E3F
  static const Color darkCardBorder = Color(0xFF1E2E3F);

  // ─── Text Colors ──────────────────────────────────────────────────────────
  /// web: --text-primary light: #0F172A
  static const Color textPrimaryLight = Color(0xFF0F172A);

  /// web: --text-primary dark: #F8FBFD
  static const Color textPrimaryDark = Color(0xFFF8FBFD);

  /// web: --text-secondary light: #475569
  static const Color textSecondaryLight = Color(0xFF475569);

  /// web: --text-secondary dark: #A0AEC0
  static const Color textSecondaryDark = Color(0xFFA0AEC0);

  /// web: --text-muted (both modes): #64748B
  static const Color textMuted = Color(0xFF64748B);

  // ─── Spacing ──────────────────────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // ─── Border Radius (from web globals.css) ─────────────────────────────────
  /// --radius-btn-val: 12px
  static const double radiusButton = 12.0;

  /// --radius-card-val: 24px
  static const double radiusCard = 24.0;

  /// --radius-input-val: 12px
  static const double radiusInput = 12.0;

  /// --radius-dialog-val: 32px
  static const double radiusDialog = 32.0;

  /// --radius-dropdown-val: 16px
  static const double radiusDropdown = 16.0;

  /// Pill / full-round
  static const double radiusPill = 999.0;

  // ─── Legacy aliases (keep existing code compiling) ────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = radiusButton;
  static const double radiusL = radiusDropdown;
  static const double radiusXL = radiusCard;

  // ─── Elevation / Shadow ───────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 4),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
          spreadRadius: -1,
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(0, 10),
          spreadRadius: -3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ];

  // ─── Wave gradient (web: from-secondary to-primary) ───────────────────────
  static const LinearGradient waveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oceanBlue, primaryTeal],
  );

  static const LinearGradient waveGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oceanBlueDark, primaryTealLight],
  );

  /// Avatar gradient (web: from-ocean to-aqua)
  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oceanBlue, primaryTeal],
  );

  // ─── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: oceanBlue,
        surface: lightSurface,
        surfaceContainer: lightBackground,
        error: dangerLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onError: Colors.white,
        outline: lightCardBorder,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: lightCardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: lightCardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface.withValues(alpha: 0.4),
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textSecondaryLight,
          letterSpacing: 0.8,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: lightCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: lightCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: dangerLight.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: dangerLight),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: lightCardBorder,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
          side: const BorderSide(color: lightCardBorder),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightForeground,
        contentTextStyle: GoogleFonts.inter(color: lightBackground, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: lightCardBorder,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: textPrimaryLight),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primaryTeal.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryTeal,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryTealLight,
        secondary: oceanBlueDark,
        surface: darkSurface,
        surfaceContainer: darkBackground,
        error: dangerDark,
        onPrimary: darkBackground,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onError: darkBackground,
        outline: darkCardBorder,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: _buildTextTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: darkCardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTealLight,
          foregroundColor: darkBackground,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTealLight,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: darkCardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface.withValues(alpha: 0.4),
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textSecondaryDark,
          letterSpacing: 0.8,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryTealLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: dangerDark.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: dangerDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: darkCardBorder,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
          side: const BorderSide(color: darkCardBorder),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkForeground,
        contentTextStyle: GoogleFonts.inter(color: darkBackground, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: darkCardBorder,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: textPrimaryDark),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primaryTealLight.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryTealLight,
      ),
    );
  }

  // ─── Text Theme ───────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final textPrimary =
        brightness == Brightness.light ? textPrimaryLight : textPrimaryDark;
    final textSecondary =
        brightness == Brightness.light ? textSecondaryLight : textSecondaryDark;

    return TextTheme(
      // Display — Outfit w900 48px  (.text-display)
      displayLarge: GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.03 * 48,
        height: 1.15,
        color: textPrimary,
      ),
      // h1 — Outfit w800 36px
      displayMedium: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: textPrimary,
      ),
      // h2 — Outfit w800 30px
      displaySmall: GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.3,
        color: textPrimary,
      ),
      // h3 — Outfit w700 24px
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: textPrimary,
      ),
      // h4 — Outfit w700 20px
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: textPrimary,
      ),
      // h5 — Outfit w600 18px
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      // Title — Inter w600 16px
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: textPrimary,
      ),
      // Body — Inter w400 16px (.text-body)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
      // Caption — Inter w400 14px (.text-caption)
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textPrimary,
      ),
      // Metadata — Inter w400 12px (.text-metadata)
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: textSecondary,
      ),
      // Label — Inter w600 13px
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      // Small label — Inter w500 11px
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      // Tiny — Inter w500 10px
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    );
  }
}
