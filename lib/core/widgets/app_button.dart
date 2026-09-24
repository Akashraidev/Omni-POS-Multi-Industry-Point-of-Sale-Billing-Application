import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

enum AppButtonType { primary, secondary, outlined, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    BorderSide? border;

    switch (type) {
      case AppButtonType.primary:
        bg = theme.colorScheme.primary;
        fg = Colors.white;
        break;
      case AppButtonType.secondary:
        bg = theme.colorScheme.secondary;
        fg = Colors.white;
        break;
      case AppButtonType.outlined:
        bg = Colors.transparent;
        fg = theme.colorScheme.primary;
        border = BorderSide(color: theme.dividerColor, width: 1.5);
        break;
      case AppButtonType.danger:
        bg = theme.colorScheme.error;
        fg = Colors.white;
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSM),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppTokens.spaceSM),
        ],
        Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 44,
      child: Material(
        color: onPressed == null ? bg.withAlpha(120) : bg,
        borderRadius: AppTokens.borderMD,
        shape: border != null ? RoundedRectangleBorder(borderRadius: AppTokens.borderMD, side: border) : null,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppTokens.borderMD,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
