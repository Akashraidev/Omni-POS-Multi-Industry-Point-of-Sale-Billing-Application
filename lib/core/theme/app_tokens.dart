import 'package:flutter/material.dart';

class AppTokens {
  // Spacing Scale
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;

  // Radius Scale
  static const double radiusSM = 6.0;
  static const double radiusMD = 10.0;
  static const double radiusLG = 14.0;
  static const double radiusXL = 20.0;
  static const double radiusPill = 999.0;

  static const BorderRadius borderSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(radiusPill));

  // Elevation / Box Shadows
  static const List<BoxShadow> shadowSM = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowMD = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowLG = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // Breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;
}
