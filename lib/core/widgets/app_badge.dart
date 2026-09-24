import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum BadgeType { success, warning, error, info, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.success:
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case BadgeType.warning:
        bg = AppColors.warningLight;
        fg = const Color(0xFFB45309);
        break;
      case BadgeType.error:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
      case BadgeType.info:
        bg = AppColors.infoLight;
        fg = AppColors.info;
        break;
      case BadgeType.neutral:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTokens.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
