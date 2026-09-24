import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../medical_palette.dart';

/// Compact KPI tile used across the Medical sector dashboard & screens.
///
/// Sizes its icon and padding from the available width so a row of these
/// never overflows on narrow phones or stretches awkwardly on desktop.
class MedicalStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color? background;
  final VoidCallback? onTap;

  const MedicalStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final bg = background ?? color.withAlpha(18);
    final iconSize = isWide ? 22.0 : 18.0;
    final valueSize = isWide ? 20.0 : 17.0;

    return Material(
      color: bg,
      borderRadius: AppTokens.borderMD,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.borderMD,
        child: Container(
          padding: EdgeInsets.all(isWide ? 14.0 : 10.0),
          decoration: BoxDecoration(
            borderRadius: AppTokens.borderMD,
            border: Border.all(color: color.withAlpha(55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: iconSize, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isWide ? 12.0 : 10.5,
                    color: theme.colorScheme.onSurface.withAlpha(170),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill that shows a label + value, e.g. "Batch: B-DL01".
class MedicalInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const MedicalInfoChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurface.withAlpha(175);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withAlpha(14),
        borderRadius: AppTokens.borderSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: accent),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(190),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header used above medical lists / groups.
class MedicalSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const MedicalSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: MedicalPalette.brandGradient,
            borderRadius: AppTokens.borderSM,
          ),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: AppTokens.spaceSM),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: MedicalPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
