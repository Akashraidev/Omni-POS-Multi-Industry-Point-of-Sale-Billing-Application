import 'package:flutter/material.dart';

/// Centralized design tokens for the Medical / Pharmacy sector.
///
/// Every medical screen derives its colors, radii and severity accents from
/// here so the sector looks and feels like one cohesive product — while the
/// base palette still matches the global [BusinessType.medical] theme.
class MedicalPalette {
  MedicalPalette._();

  // Brand — matches BusinessType.medical.primaryColor (Teal)
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color brandGradientStart = Color(0xFF0D9488);
  static const Color brandGradientEnd = Color(0xFF2563EB);

  // Severity accents used across expiry / compliance screens
  static const Color critical = Color(0xFFDC2626); // expired / <15d
  static const Color criticalBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706); // <45d
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color watch = Color(0xFF2563EB); // <90d
  static const Color watchBg = Color(0xFFDBEAFE);
  static const Color safe = Color(0xFF059669);
  static const Color safeBg = Color(0xFFD1FAE5);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, brandGradientEnd],
  );
}

/// Maps a remaining-shelf-life value to a consistent severity presentation.
enum ExpirySeverity { critical, warning, watch, safe }

extension ExpirySeverityX on ExpirySeverity {
  Color get color {
    switch (this) {
      case ExpirySeverity.critical:
        return MedicalPalette.critical;
      case ExpirySeverity.warning:
        return MedicalPalette.warning;
      case ExpirySeverity.watch:
        return MedicalPalette.watch;
      case ExpirySeverity.safe:
        return MedicalPalette.safe;
    }
  }

  Color get background {
    switch (this) {
      case ExpirySeverity.critical:
        return MedicalPalette.criticalBg;
      case ExpirySeverity.warning:
        return MedicalPalette.warningBg;
      case ExpirySeverity.watch:
        return MedicalPalette.watchBg;
      case ExpirySeverity.safe:
        return MedicalPalette.safeBg;
    }
  }

  String get label {
    switch (this) {
      case ExpirySeverity.critical:
        return 'Critical';
      case ExpirySeverity.warning:
        return 'Warning';
      case ExpirySeverity.watch:
        return 'Watch';
      case ExpirySeverity.safe:
        return 'Safe';
    }
  }

  /// Mirrors the badge logic that already existed, kept as the single
  /// source of truth so the tracker and dashboard stay in sync.
  static ExpirySeverity fromDays(int days) {
    if (days <= 15) return ExpirySeverity.critical;
    if (days <= 45) return ExpirySeverity.warning;
    if (days <= 90) return ExpirySeverity.watch;
    return ExpirySeverity.safe;
  }
}
