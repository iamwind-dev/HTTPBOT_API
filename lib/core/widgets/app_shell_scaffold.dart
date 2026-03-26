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
    this.leading,
    this.trailing,
    this.bottomSlot,
    this.floatingActionButton,
    this.floatingActionButtonLocation = FloatingActionButtonLocation.endFloat,
    this.bodyHorizontalPadding = AppSpacing.medium,
  });

  final AppShellTab currentTab;
  final String title;
  final Widget body;
  final ValueChanged<AppShellTab> onTabSelected;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomSlot;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation floatingActionButtonLocation;
  final double bodyHorizontalPadding;

  // Compose the global app shell around a route-specific body.
  @override
  Widget build(BuildContext context) {
    final headerHeight = AppPageHeader.heightFor(
      hasBottomSlot: bottomSlot != null,
    );

    return Scaffold(
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: AppBottomNavigation<AppShellTab>(
        items: AppShellTab.values
            .map(
              (tab) => AppBottomNavigationItem<AppShellTab>(
                value: tab,
                iconBuilder: tab.buildIcon,
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
          padding: EdgeInsets.symmetric(horizontal: bodyHorizontalPadding),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: headerHeight),
                child: body,
              ),
              AppPageHeader(
                title: title,
                leading: leading,
                trailing: trailing,
                bottomSlot: bottomSlot,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
