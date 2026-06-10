import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../models/settings_item.dart';
import 'settings_row.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.items,
    required this.onItemSelected,
  });

  final List<SettingsItem> items;
  final ValueChanged<String> onItemSelected;

  /// Groups settings rows inside a rounded iOS-style white card.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.card,
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    ),
    child: Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          SettingsRow(item: item, onTap: () => onItemSelected(item.id)),
          if (index != items.length - 1)
            Padding(
              padding: EdgeInsets.only(
                // left: AppSpacing.xxxLarge + AppSpacing.medium,
                left: AppSpacing.large,
                right: AppSpacing.large,
              ),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.appColors.divider,
              ),
            ),
        ],
      ],
    ),
  );
}
