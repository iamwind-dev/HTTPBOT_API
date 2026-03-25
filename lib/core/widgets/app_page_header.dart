import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.bottomSlot,
    this.height = defaultHeight,
    this.horizontalPadding = AppSpacing.small,
  });

  static const defaultHeight =
      AppSpacing.xxxLarge + AppSpacing.xxxLarge + AppSpacing.small;
  static const _actionExtent = AppSpacing.xxLarge + AppSpacing.xSmall;

  final String title;
  final Widget? trailing;
  final Widget? bottomSlot;
  final double height;
  final double horizontalPadding;

  // Render a reusable frosted shell that keeps the title visually centered.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: height,
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
            children: [
              Expanded(
                child: SizedBox(
                  height: _actionExtent,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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
              ),
              ...?bottomSlot == null ? null : <Widget>[bottomSlot!],
              const SizedBox(height: AppSpacing.small),
            ],
          ),
        ),
      ),
    );
  }
}
