import '../../../../core/constants/app_strings.dart';
import '../../../../generated/assets.gen.dart';
import 'settings_item.dart';
import 'settings_section.dart';

abstract final class SettingsCatalog {
  /// Returns the fixed settings overview structure used by the current feature slice.
  static List<SettingsSection> sections() => <SettingsSection>[
    SettingsSection(
      items: <SettingsItem>[
        SettingsItem(
          id: 'request-settings',
          title: AppStrings.settingsRequestSettings,
          icon: Assets.icons.requestsSettingIc,
        ),
        SettingsItem(
          id: 'disk-usage',
          title: AppStrings.settingsDiskUsage,
          icon: Assets.icons.diskIc,
        ),
      ],
    ),
    SettingsSection(
      title: AppStrings.settingsSectionSavedItems,
      items: <SettingsItem>[
        SettingsItem(
          id: 'cookies',
          title: AppStrings.settingsCookies,
          icon: Assets.icons.cookieIc,
        ),
        SettingsItem(
          id: 'environments',
          title: AppStrings.settingsEnvironments,
          icon: Assets.icons.environmentIc,
        ),
        SettingsItem(
          id: 'global-variables',
          title: AppStrings.settingsGlobalVariables,
          icon: Assets.icons.globalVariablesIc,
        ),
        SettingsItem(
          id: 'saved-auth',
          title: AppStrings.settingsSavedAuth,
          icon: Assets.icons.savedAuthIc,
        ),
        SettingsItem(
          id: 'response-filters',
          title: AppStrings.settingsResponseFilters,
          icon: Assets.icons.responeFilterIc,
        ),
        SettingsItem(
          id: 'graphql',
          title: AppStrings.settingsGraphql,
          icon: Assets.icons.graphqlIc,
        ),
      ],
    ),
    SettingsSection(
      title: AppStrings.settingsSectionPostman,
      items: <SettingsItem>[
        SettingsItem(
          id: 'postman-account',
          title: AppStrings.settingsPostmanAccount,
          icon: Assets.icons.postmanIcon,
        ),
      ],
    ),
    SettingsSection(
      title: AppStrings.settingsSectionHttpbot,
      items: <SettingsItem>[
        // SettingsItem(
        //   id: 'more-settings',
        //   title: AppStrings.settingsMoreSettings,
        //   icon: Assets.icons.aboutIc,
        // ),
        SettingsItem(
          id: 'theme-mode',
          title: AppStrings.settingsDarkMode,
          icon: Assets.icons.settingsIc,
          kind: SettingsItemKind.themeToggle,
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
