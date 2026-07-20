import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_context.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.bottomSlot,
    this.height,
    this.horizontalPadding = AppSpacing.xSmall,
    this.centerTitle = true,
  });

  static const defaultHeight =
      AppSpacing.xxxLarge + AppSpacing.xxLarge + AppSpacing.xSmall;
  static const compactHeight = AppSpacing.xxLarge + AppSpacing.large;
  static const _actionExtent = AppSpacing.xxLarge + AppSpacing.xSmall;
  static const _topInset = AppSpacing.xxSmall;
  static const _titleBottomInset = AppSpacing.xxSmall;
  static const _bottomSlotSpacing = AppSpacing.xSmall;
  static const tightHeight = _topInset + _actionExtent + _titleBottomInset;

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomSlot;
  final double? height;
  final double horizontalPadding;
  final bool centerTitle;

  /// Resolves the fixed shell header height for pages with and without a bottom slot.
  static double heightFor({
    required bool hasBottomSlot,
    double? customHeight,
  }) => customHeight ?? (hasBottomSlot ? defaultHeight : compactHeight);

  // Render a reusable frosted shell that keeps the title visually centered.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            colors.headerOverlayTop,
            colors.headerOverlayMid,
            colors.headerOverlayBottom,
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
            child: centerTitle
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      if (leading != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _HeaderAction(child: leading!),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _actionExtent,
                        ),
                        child: _HeaderTitle(title: title, centered: true),
                      ),
                      if (trailing != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _HeaderAction(child: trailing!),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      if (leading != null) _HeaderAction(child: leading!),
                      if (leading != null)
                        const SizedBox(width: AppSpacing.xxxSmall),
                      Expanded(child: _HeaderTitle(title: title)),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.xxxSmall),
                        _HeaderAction(child: trailing!),
                      ],
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

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title, this.centered = false});

  final String title;
  final bool centered;

  @override
  Widget build(BuildContext context) => Align(
    alignment: centered ? Alignment.center : Alignment.centerLeft,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
        maxLines: 1,
        softWrap: false,
        textAlign: centered ? TextAlign.center : TextAlign.left,
      ),
    ),
  );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.headerActionSurface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
    ),
    child: child,
  );
}
