import 'package:flutter/widgets.dart';

/// Shared breakpoints and size limits used by the application shell and sheets.
abstract final class AppResponsive {
  /// A rail is useful only when both dimensions can comfortably fit it.
  static const double navigationRailWidth = 700;
  static const double navigationRailHeight = 500;

  /// Prevent list-oriented screens from becoming difficult to scan on tablets.
  static const double maxContentWidth = 1120;
  static const double maxSheetWidth = 960;

  static bool usesNavigationRail(BoxConstraints constraints) =>
      constraints.maxWidth >= navigationRailWidth &&
      constraints.maxHeight >= navigationRailHeight;

  static double pageGutter(double width) {
    if (width >= 1024) return 32;
    if (width >= 600) return 24;
    return 16;
  }
}

/// Centers content and caps its line length without affecting compact screens.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppResponsive.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
