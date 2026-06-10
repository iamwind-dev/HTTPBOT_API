import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_context.dart';

typedef AppBottomNavigationIconBuilder = Widget Function(Color color);

class AppBottomNavigationItem<T> {
  const AppBottomNavigationItem({
    required this.value,
    required this.iconBuilder,
    required this.label,
    required this.widgetKey,
  });

  final T value;
  final AppBottomNavigationIconBuilder iconBuilder;
  final String label;
  final String widgetKey;
}

class AppBottomNavigation<T> extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onItemSelected,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
  });

  final List<AppBottomNavigationItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onItemSelected;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;

  // Render a generic bottom bar shell while leaving selection behavior to the caller.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xSmall),
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.navBackground,
        ),
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: _AppBottomNavigationTile<T>(
                    item: item,
                    isActive: item.value == selectedValue,
                    activeColor: activeColor ?? colors.navActive,
                    inactiveColor: inactiveColor ?? colors.navInactive,
                    onTap: () => onItemSelected(item.value),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _AppBottomNavigationTile<T> extends StatelessWidget {
  const _AppBottomNavigationTile({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final AppBottomNavigationItem<T> item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  // Keep icon and label aligned within a compact reusable bottom-nav item.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = isActive ? activeColor : inactiveColor;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 12,
      height: 1,
      fontWeight: FontWeight.w600,
      color: foregroundColor,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: ValueKey<String>(item.widgetKey),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxSmall,
            vertical: AppSpacing.small,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: AppSpacing.large,
                child: Center(child: item.iconBuilder(foregroundColor)),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              SizedBox(
                height: AppSpacing.large,
                child: Center(
                  child: Text(
                    item.label,
                    style: labelStyle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
