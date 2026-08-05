import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/app_popup_menu.dart';
import '../../../request_builder/presentation/widgets/saved_response_filters_sheet.dart';

class SettingsResponseFiltersPage extends StatelessWidget {
  const SettingsResponseFiltersPage({super.key, required this.controller});

  final SavedResponseFiltersController controller;

  @override
  Widget build(BuildContext context) =>
      SavedResponseFiltersPage(controller: controller);
}

class SettingsResponseFiltersActions extends StatelessWidget {
  const SettingsResponseFiltersActions({super.key, required this.controller});

  final SavedResponseFiltersController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.headerActionSurface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
          ),
          child: PopupMenuButton<String>(
            key: const ValueKey<String>(
              AppWidgetKeys.settingsResponseFiltersMoreButton,
            ),
            onSelected: (_) => controller.deleteAll?.call(),
            icon: const Icon(CupertinoIcons.ellipsis),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'delete_all',
                child: AppPopupMenuRow(
                  icon: CupertinoIcons.trash,
                  label: AppStrings.settingsResponseFilterDeleteAll,
                  destructive: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.headerActionSurface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
          ),
          child: IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.settingsResponseFiltersAddButton,
            ),
            onPressed: () => controller.openCreate?.call(),
            icon: const Icon(CupertinoIcons.add),
          ),
        ),
      ],
    );
  }
}
