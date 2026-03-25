import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../keys/widget_keys.dart';

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

  IconData get icon => switch (this) {
    AppShellTab.requests => Icons.sync_alt_rounded,
    AppShellTab.websockets => Icons.compare_arrows_rounded,
    AppShellTab.collections => Icons.folder_rounded,
    AppShellTab.postman => Icons.adjust_rounded,
    AppShellTab.settings => Icons.settings_rounded,
  };

  String get widgetKey => switch (this) {
    AppShellTab.requests => AppWidgetKeys.requestsTab,
    AppShellTab.websockets => AppWidgetKeys.websocketsTab,
    AppShellTab.collections => AppWidgetKeys.collectionsTab,
    AppShellTab.postman => AppWidgetKeys.postmanTab,
    AppShellTab.settings => AppWidgetKeys.settingsTab,
  };
}
