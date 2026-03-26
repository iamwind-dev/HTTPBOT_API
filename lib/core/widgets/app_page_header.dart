import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.bottomSlot,
    this.height,
    this.horizontalPadding = AppSpacing.xSmall,
  });

  static const defaultHeight =
      AppSpacing.xxxLarge + AppSpacing.xxLarge + AppSpacing.xSmall;
  static const compactHeight = AppSpacing.xxLarge + AppSpacing.large;
  static const _actionExtent = AppSpacing.xxLarge + AppSpacing.xSmall;
  static const _topInset = AppSpacing.xxSmall;
  static const _titleBottomInset = AppSpacing.xxSmall;
  static const _bottomSlotSpacing = AppSpacing.xSmall;

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomSlot;
  final double? height;
  final double horizontalPadding;

  /// Resolves the fixed shell header height for pages with and without a bottom slot.
  static double heightFor({
    required bool hasBottomSlot,
    double? customHeight,
  }) => customHeight ?? (hasBottomSlot ? defaultHeight : compactHeight);

  // Render a reusable frosted shell that keeps the title visually centered.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedHeight =
        height ?? heightFor(hasBottomSlot: bottomSlot != null);
    final titleBottomSpacing = bottomSlot == null
        ? _titleBottomInset
        : _bottomSlotSpacing;

    return Container(
      height: resolvedHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withValues(alpha: 0.9),
            AppColors.surface.withValues(alpha: 0.65),
            AppColors.surface.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: _topInset),
          SizedBox(
            width: double.infinity,
            height: _actionExtent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (leading != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.72),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.large),
                        ),
                      ),
                      child: leading,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _actionExtent,
                  ),
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (trailing != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.72),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.large),
                        ),
                      ),
                      child: trailing,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: titleBottomSpacing),
          if (bottomSlot != null) ...[bottomSlot!],
        ],
      ),
    );
  }
}
