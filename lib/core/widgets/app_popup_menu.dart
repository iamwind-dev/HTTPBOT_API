import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_context.dart';

/// Shared row layout for action-oriented popup menus.
class AppPopupMenuRow extends StatelessWidget {
  const AppPopupMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.destructive = false,
    this.enabled = true,
  });

  final bool destructive;
  final bool enabled;
  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foregroundColor = destructive
        ? colors.methodDelete
        : enabled
        ? colors.textPrimary
        : colors.textSecondary.withValues(alpha: 0.55);

    return Row(
      children: [
        Icon(icon, size: 18, color: foregroundColor),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: destructive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        if (trailing case final trailing?) ...[
          const SizedBox(width: AppSpacing.small),
          trailing,
        ],
      ],
    );
  }
}
