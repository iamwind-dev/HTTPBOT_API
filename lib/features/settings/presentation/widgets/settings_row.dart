import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/theme/cubit/theme_cubit.dart';
import '../models/settings_item.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.item, required this.onTap});

  final SettingsItem item;
  final VoidCallback onTap;

  /// Renders one grouped-settings row with an iOS-style icon and label layout.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final isThemeToggle = item.isThemeToggle;
    final isDarkMode = context.select<ThemeCubit, bool>(
      (cubit) => cubit.state == ThemeMode.dark,
    );
    final resolvedOnTap = isThemeToggle
        ? () => context.read<ThemeCubit>().setDarkModeEnabled(!isDarkMode)
        : onTap;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(item.widgetKey),
        onTap: resolvedOnTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Icon(item.icon, color: colors.navActive, size: AppSpacing.large),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isThemeToggle)
                Switch.adaptive(
                  key: const ValueKey<String>(
                    AppWidgetKeys.settingsThemeModeSwitch,
                  ),
                  value: isDarkMode,
                  onChanged: (value) =>
                      context.read<ThemeCubit>().setDarkModeEnabled(value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
