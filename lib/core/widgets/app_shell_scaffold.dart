import 'package:flutter/material.dart';

import '../router/app_shell_tab.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_navigation.dart';
import 'app_page_header.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    required this.currentTab,
    required this.title,
    required this.body,
    required this.onTabSelected,
    this.trailing,
    this.bottomSlot,
    this.floatingActionButton,
    this.floatingActionButtonLocation =
        FloatingActionButtonLocation.endFloat,
  });

  static const _headerTopInset = AppSpacing.xxSmall;

  final AppShellTab currentTab;
  final String title;
  final Widget body;
  final ValueChanged<AppShellTab> onTabSelected;
  final Widget? trailing;
  final Widget? bottomSlot;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation floatingActionButtonLocation;

  // Compose the global app shell around a route-specific body.
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: floatingActionButton,
    floatingActionButtonLocation: floatingActionButtonLocation,
    bottomNavigationBar: AppBottomNavigation<AppShellTab>(
      items: AppShellTab.values
          .map(
            (tab) => AppBottomNavigationItem<AppShellTab>(
              value: tab,
              icon: tab.icon,
              label: tab.label,
              widgetKey: tab.widgetKey,
            ),
          )
          .toList(growable: false),
      selectedValue: currentTab,
      onItemSelected: onTabSelected,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: _headerTopInset + AppPageHeader.defaultHeight,
              ),
              child: body,
            ),
            Padding(
              padding: const EdgeInsets.only(top: _headerTopInset),
              child: AppPageHeader(
                title: title,
                trailing: trailing,
                bottomSlot: bottomSlot,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
