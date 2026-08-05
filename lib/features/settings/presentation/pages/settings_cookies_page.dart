import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../request_builder/presentation/widgets/request_cookies_sheet.dart';

class SettingsCookiesPage extends StatelessWidget {
  const SettingsCookiesPage({super.key, required this.controller});

  final SettingsCookiesController controller;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ManageCookiesView(
        useSheetCard: false,
        showHeader: false,
        cookiesController: controller,
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: AppSpacing.xxLarge,
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => PopupMenuButton<String?>(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsCookiesFilterButton,
              ),
              tooltip: AppStrings.cookiesAllDomains,
              onSelected: controller.selectDomain,
              itemBuilder: (context) => [
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text(AppStrings.cookiesAllDomains),
                ),
                for (final domain in controller.availableDomains)
                  PopupMenuItem<String?>(value: domain, child: Text(domain)),
              ],
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.pill),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.modalShadow,
                      blurRadius: AppSpacing.large,
                      offset: const Offset(0, AppSpacing.xxSmall),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.medium,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.selectedDomainLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: AppSpacing.xxSmall),
                      const Icon(
                        Icons.unfold_more_rounded,
                        size: AppSpacing.large,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
