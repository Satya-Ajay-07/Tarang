import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Tarang Text Styles
///
/// Named TextStyle definitions matching the Web Application's typography scale.
/// Import this file and reference these constants throughout the app.
/// Do NOT scatter GoogleFonts calls in feature files.
///
/// Web source: globals.css typography scale
///   --font-display: 'Outfit', 'Inter', system-ui
///   --font-body: 'Inter', system-ui
class AppTextStyles {
  AppTextStyles._();

  // ─── Display (Outfit / display font) ─────────────────────────────────────

  /// .text-display — Outfit w900 48px, letterSpacing -3%, lineHeight 1.15
  static final TextStyle display = GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.44, // -0.03em × 48
    height: 1.15,
  );

  /// h1 — Outfit w800 36px
  static final TextStyle h1 = GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  /// h2 — Outfit w800 30px
  static final TextStyle h2 = GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  /// h3 — Outfit w700 24px
  static final TextStyle h3 = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// h4 — Outfit w700 20px (mobile extension)
  static final TextStyle h4 = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  /// h5 — Outfit w600 18px
  static final TextStyle h5 = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ─── Body (Inter / body font) ─────────────────────────────────────────────

  /// .text-body — Inter w400 16px, lineHeight 1.5
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// body semibold — Inter w600 16px
  static final TextStyle bodySemibold = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// body bold — Inter w700 16px
  static final TextStyle bodyBold = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  /// .text-caption — Inter w400 14px, lineHeight 1.4
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// caption semibold — Inter w600 14px
  static final TextStyle captionSemibold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// caption bold — Inter w700 14px
  static final TextStyle captionBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  /// .text-metadata — Inter w400 12px, lineHeight 1.3
  static final TextStyle metadata = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// metadata semibold — Inter w600 12px
  static final TextStyle metadataSemibold = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ─── Labels ───────────────────────────────────────────────────────────────

  /// Small caps label (used for TextField labels on web) — Inter w700 11px uppercase
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.0,
  );

  /// Button text — Inter w700 15px, tight tracking
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Button small — Inter w600 13px
  static final TextStyle buttonSm = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  /// Button large — Inter w700 16px
  static final TextStyle buttonLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  // ─── Contextual helpers (with color pre-applied) ──────────────────────────

  /// For use on muted / timestamp text
  static TextStyle get muted => metadata.copyWith(color: AppTheme.textMuted);

  /// For secondary descriptive text
  static TextStyle get secondary => caption.copyWith(color: AppTheme.textSecondaryLight);

  /// For hashtag / mention text in waves
  static final TextStyle mention = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.primaryTeal,
    height: 1.4,
  );

  static final TextStyle mentionDark = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.primaryTealLight,
    height: 1.4,
  );
}
