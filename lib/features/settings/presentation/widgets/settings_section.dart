import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../models/settings_section.dart' as models;
import 'settings_card.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.section,
    required this.onItemSelected,
  });

  final models.SettingsSection section;
  final ValueChanged<String> onItemSelected;

  /// Renders one grouped settings section with an optional muted title above its card.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          if (section.title != null) ...[
            Row(
              children: [
                SizedBox(width: AppSpacing.medium),
                Text(
                  section.title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xSmall),
          ],
          SettingsCard(items: section.items, onItemSelected: onItemSelected),
        ],
      ),
    );
  }
}
