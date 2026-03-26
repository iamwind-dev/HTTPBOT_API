import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import 'settings_item.dart';
import 'settings_section.dart';

abstract final class SettingsCatalog {
  /// Returns the fixed settings overview structure used by the current feature slice.
  static List<SettingsSection> sections() => const <SettingsSection>[
    SettingsSection(
      items: <SettingsItem>[
        SettingsItem(
          id: 'request-settings',
          title: AppStrings.settingsRequestSettings,
          icon: Icons.tune_rounded,
        ),
        SettingsItem(
          id: 'disk-usage',
          title: AppStrings.settingsDiskUsage,
          icon: Icons.save_outlined,
        ),
      ],
    ),
    SettingsSection(
      title: AppStrings.settingsSectionSavedItems,
      items: <SettingsItem>[
        SettingsItem(
          id: 'cookies',
          title: AppStrings.settingsCookies,
          icon: Icons.square_outlined,
        ),
        SettingsItem(
          id: 'environments',
          title: AppStrings.settingsEnvironments,
          icon: Icons.square_outlined,
        ),
        SettingsItem(
          id: 'global-variables',
          title: AppStrings.settingsGlobalVariables,
          icon: Icons.public_rounded,
        ),
        SettingsItem(
          id: 'saved-auth',
          title: AppStrings.settingsSavedAuth,
          icon: Icons.key_rounded,
        ),
        SettingsItem(
          id: 'response-filters',
          title: AppStrings.settingsResponseFilters,
          icon: Icons.filter_list_rounded,
        ),
        SettingsItem(
          id: 'graphql',
          title: AppStrings.settingsGraphql,
          icon: Icons.square_outlined,
        ),
      ],
    ),
    SettingsSection(
      title: AppStrings.settingsSectionPostman,
      items: <SettingsItem>[
        SettingsItem(
          id: 'postman-account',
          title: AppStrings.settingsPostmanAccount,
          icon: Icons.circle_outlined,
        ),
      ],
    ),
    SettingsSection(
      title: AppStrings.settingsSectionHttpbot,
      items: <SettingsItem>[
        SettingsItem(
          id: 'more-settings',
          title: AppStrings.settingsMoreSettings,
          icon: Icons.tune_rounded,
        ),
      ],
    ),
  ];

  /// Resolves a settings item by route id for placeholder destination rendering.
  static SettingsItem? findItemById(String itemId) {
    for (final section in sections()) {
      for (final item in section.items) {
        if (item.id == itemId) {
          return item;
        }
      }
    }

    return null;
  }
}
