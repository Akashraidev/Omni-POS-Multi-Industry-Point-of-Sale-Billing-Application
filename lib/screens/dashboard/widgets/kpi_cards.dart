import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';

/// Primary KPI card with a genuine period-over-period delta.
///
/// The delta is computed from actual data by the caller — no hardcoded trend
/// strings anywhere on the dashboard.
class DashboardKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double deltaPercent;
  final bool invertDelta;
  final VoidCallback? onTap;

  const DashboardKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.deltaPercent = 0.0,
    this.invertDelta = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDelta = deltaPercent.abs() > 0.001;
    final isGood = invertDelta ? deltaPercent < 0 : deltaPercent > 0;
    final deltaColor = !hasDelta
        ? theme.colorScheme.onSurface.withAlpha(120)
        : (isGood ? const Color(0xFF059669) : const Color(0xFFDC2626));

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderLG,
        child: InkWell(
          borderRadius: AppTokens.borderLG,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: AppTokens.borderMD,
                      ),
                      child: Icon(icon, color: color, size: 19),
                    ),
                    if (hasDelta)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: deltaColor.withAlpha(20),
                          borderRadius: AppTokens.borderPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              deltaPercent > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 12,
                              color: deltaColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${deltaPercent > 0 ? '+' : ''}${deltaPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: deltaColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(165),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact secondary metric tile used for operational counts (stock, expiry,
/// compliance). Reflows instead of overflowing on narrow screens.
class CompactStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subLabel;

  const CompactStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withAlpha(14),
      borderRadius: AppTokens.borderMD,
      child: InkWell(
        borderRadius: AppTokens.borderMD,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: AppTokens.borderMD,
            border: Border.all(color: color.withAlpha(45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withAlpha(175),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.4,
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment-method collection chip used in the collections strip.
class CollectionTile extends StatelessWidget {
  final String method;
  final double amount;
  final int count;
  final IconData icon;
  final Color color;

  const CollectionTile({
    super.key,
    required this.method,
    required this.amount,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = amount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(12) : theme.colorScheme.onSurface.withAlpha(5),
        borderRadius: AppTokens.borderMD,
        border: Border.all(color: active ? color.withAlpha(55) : theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: active ? color : theme.colorScheme.onSurface.withAlpha(120)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  method,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? color : theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                Text(
                  active
                      ? CurrencyFormatter.format(amount, symbol: '', decimalDigits: amount % 1 == 0 ? 0 : 2)
                      : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: active ? color : theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          if (active)
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
        ],
      ),
    );
  }
}
