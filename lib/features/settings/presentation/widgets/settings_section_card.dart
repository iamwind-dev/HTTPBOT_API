import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/settings_item.dart';
import '../models/settings_section.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.section,
    required this.onItemSelected,
  });

  final SettingsSection section;
  final ValueChanged<String> onItemSelected;

  // Render a section label followed by a card of tappable settings rows.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.small,
              bottom: AppSpacing.small,
            ),
            child: Text(
              section.title!,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
          ),
          child: Column(
            children: [
              for (final (index, item) in section.items.indexed) ...[
                SettingsEntryTile(
                  item: item,
                  onTap: () => onItemSelected(item.id),
                ),
                if (index != section.items.length - 1)
                  const Divider(
                    height: 1,
                    indent: AppSpacing.xxxLarge + AppSpacing.medium,
                    endIndent: AppSpacing.small,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsEntryTile extends StatelessWidget {
  const SettingsEntryTile({super.key, required this.item, required this.onTap});

  final SettingsItem item;
  final VoidCallback onTap;

  // Present a single settings row with icon, label, and tap affordance.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface.withValues(alpha: 0),
      child: InkWell(
        key: ValueKey<String>(item.widgetKey),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.large,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: AppColors.methodGet,
                size: AppSpacing.large,
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(item.title, style: theme.textTheme.bodyLarge),
              ),
              const SizedBox(width: AppSpacing.small),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
