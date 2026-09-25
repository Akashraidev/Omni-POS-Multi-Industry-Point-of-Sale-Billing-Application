import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorder = borderColor ?? theme.dividerColor;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(color: effectiveBorder, width: 1),
        boxShadow: AppTokens.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderLG,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.borderLG,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTokens.spaceLG),
            child: child,
          ),
        ),
      ),
    );
  }
}
