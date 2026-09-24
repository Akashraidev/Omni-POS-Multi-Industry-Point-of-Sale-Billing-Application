import 'package:flutter/material.dart';

/// Percentage-based responsive helpers.
///
/// Instead of hard-coded pixel values, widgets should derive their dimensions
/// from the available screen size using [widthPct] / [heightPct] or from the
/// constraints provided by [LayoutBuilder]. This guarantees the UI scales
/// gracefully across phones, tablets, laptops and desktops.
extension ResponsiveSize on BuildContext {
  /// Available screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Available screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Smallest screen dimension (useful for square-ish elements).
  double get shortestSide => MediaQuery.sizeOf(this).shortestSide;

  /// Returns [percent]% of the screen width.
  ///
  /// Example: `context.widthPct(80)` == 80% of the available width.
  double widthPct(double percent) => screenWidth * (percent.clamp(0, 100) / 100);

  /// Returns [percent]% of the screen height.
  double heightPct(double percent) => screenHeight * (percent.clamp(0, 100) / 100);

  /// Returns a fraction of the screen width.
  double widthFraction(double fraction) => screenWidth * fraction;

  /// Returns a fraction of the screen height.
  double heightFraction(double fraction) => screenHeight * fraction;

  /// Comfortable maximum content width for centered form layouts on wide screens.
  double get contentMaxWidth => screenWidth >= 1400 ? 1100 : (screenWidth >= 900 ? 840 : screenWidth);

  /// Responsive spacing that scales with the shortest side of the device.
  static double scaledSpacing(BuildContext context, double base) {
    final scale = (MediaQuery.sizeOf(context).shortestSide / 375.0).clamp(0.85, 1.6);
    return base * scale;
  }
}
