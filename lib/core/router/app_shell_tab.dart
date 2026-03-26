import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../keys/widget_keys.dart';
import '../theme/app_spacing.dart';
import '../../generated/assets.gen.dart';

enum AppShellTab { requests, websockets, collections, postman, settings }

extension AppShellTabX on AppShellTab {
  String get location => switch (this) {
    AppShellTab.requests => '/',
    AppShellTab.websockets => '/websockets',
    AppShellTab.collections => '/collections',
    AppShellTab.postman => '/postman',
    AppShellTab.settings => '/settings',
  };

  String get label => switch (this) {
    AppShellTab.requests => AppStrings.requestsTabLabel,
    AppShellTab.websockets => AppStrings.websocketsTabLabel,
    AppShellTab.collections => AppStrings.collectionsTabLabel,
    AppShellTab.postman => AppStrings.postmanTabLabel,
    AppShellTab.settings => AppStrings.settingsTabLabel,
  };

  String get title => switch (this) {
    AppShellTab.requests => AppStrings.requestsTitle,
    AppShellTab.websockets => AppStrings.websocketsTabLabel,
    AppShellTab.collections => AppStrings.collectionsTabLabel,
    AppShellTab.postman => AppStrings.postmanTabLabel,
    AppShellTab.settings => AppStrings.settingsTabLabel,
  };

  /// Build the shell tab icon with the active or inactive color from the nav.
  Widget buildIcon(Color color) => switch (this) {
    AppShellTab.requests => Assets.icons.requestsIc.svg(
      width: AppSpacing.large,
      height: AppSpacing.large,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
    AppShellTab.websockets => Icon(
      Icons.compare_arrows_rounded,
      color: color,
      size: AppSpacing.large,
    ),
    AppShellTab.collections => Assets.icons.collections.svg(
      width: AppSpacing.large,
      height: AppSpacing.large,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
    AppShellTab.postman => Assets.icons.postmanIcon.svg(
      width: AppSpacing.large,
      height: AppSpacing.large,
      // colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      
    ),
    AppShellTab.settings => Assets.icons.settingsIc.svg(
      width: AppSpacing.large,
      height: AppSpacing.large,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  };

  String get widgetKey => switch (this) {
    AppShellTab.requests => AppWidgetKeys.requestsTab,
    AppShellTab.websockets => AppWidgetKeys.websocketsTab,
    AppShellTab.collections => AppWidgetKeys.collectionsTab,
    AppShellTab.postman => AppWidgetKeys.postmanTab,
    AppShellTab.settings => AppWidgetKeys.settingsTab,
  };
}
