import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppTokens.breakpointMobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppTokens.breakpointMobile &&
      MediaQuery.sizeOf(context).width < AppTokens.breakpointTablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppTokens.breakpointTablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= AppTokens.breakpointTablet) {
      return desktop;
    } else if (width >= AppTokens.breakpointMobile && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
