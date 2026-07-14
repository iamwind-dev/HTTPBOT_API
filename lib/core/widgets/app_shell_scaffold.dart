import 'package:flutter/material.dart';

import '../layout/app_responsive.dart';
import '../router/app_shell_tab.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_context.dart';
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
    this.centerTitle = true,
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
  final bool centerTitle;

  // Compose the global app shell around a route-specific body.
  @override
  Widget build(BuildContext context) {
    final headerHeight = AppPageHeader.heightFor(
      hasBottomSlot: bottomSlot != null,
    );
    final navigationItems = AppShellTab.values
        .map(
          (tab) => AppBottomNavigationItem<AppShellTab>(
            value: tab,
            iconBuilder: tab.buildIcon,
            label: tab.label,
            widgetKey: tab.widgetKey,
          ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final usesRail = AppResponsive.usesNavigationRail(constraints);
        final shellBody = _ShellBody(
          headerHeight: headerHeight,
          bodyHorizontalPadding: bodyHorizontalPadding,
          title: title,
          leading: leading,
          trailing: trailing,
          bottomSlot: bottomSlot,
          centerTitle: centerTitle,
          body: body,
        );

        return Scaffold(
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: usesRail
              ? null
              : AppBottomNavigation<AppShellTab>(
                  items: navigationItems,
                  selectedValue: currentTab,
                  onItemSelected: onTabSelected,
                ),
          body: usesRail
              ? SafeArea(
                  child: Row(
                    children: [
                      _AppNavigationRail(
                        items: navigationItems,
                        selectedValue: currentTab,
                        onItemSelected: onTabSelected,
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: context.appColors.divider,
                      ),
                      Expanded(child: shellBody),
                    ],
                  ),
                )
              : SafeArea(child: shellBody),
        );
      },
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({
    required this.headerHeight,
    required this.bodyHorizontalPadding,
    required this.title,
    required this.leading,
    required this.trailing,
    required this.bottomSlot,
    required this.centerTitle,
    required this.body,
  });

  final double headerHeight;
  final double bodyHorizontalPadding;
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomSlot;
  final bool centerTitle;
  final Widget body;

  @override
  Widget build(BuildContext context) => ResponsiveContent(
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
            centerTitle: centerTitle,
          ),
        ],
      ),
    ),
  );
}

class _AppNavigationRail extends StatelessWidget {
  const _AppNavigationRail({
    required this.items,
    required this.selectedValue,
    required this.onItemSelected,
  });

  final List<AppBottomNavigationItem<AppShellTab>> items;
  final AppShellTab selectedValue;
  final ValueChanged<AppShellTab> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selectedIndex = items.indexWhere(
      (item) => item.value == selectedValue,
    );

    return NavigationRail(
      backgroundColor: colors.navBackground,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => onItemSelected(items[index].value),
      labelType: NavigationRailLabelType.all,
      groupAlignment: 0,
      selectedIconTheme: IconThemeData(color: colors.navActive),
      unselectedIconTheme: IconThemeData(color: colors.navInactive),
      selectedLabelTextStyle: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: colors.navActive),
      unselectedLabelTextStyle: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: colors.navInactive),
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: KeyedSubtree(
                key: ValueKey<String>(item.widgetKey),
                child: item.iconBuilder(colors.navInactive),
              ),
              selectedIcon: KeyedSubtree(
                key: ValueKey<String>(item.widgetKey),
                child: item.iconBuilder(colors.navActive),
              ),
              label: Text(item.label, maxLines: 1),
            ),
          )
          .toList(growable: false),
    );
  }
}
