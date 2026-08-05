import 'package:flutter/widgets.dart';

/// Shared breakpoints and size limits used by the application shell and sheets.
abstract final class AppResponsive {
  /// A rail is useful only when both dimensions can comfortably fit it.
  static const double navigationRailWidth = 700;
  static const double navigationRailHeight = 500;

  /// Prevent list-oriented screens from becoming difficult to scan on tablets.
  static const double maxContentWidth = 1120;
  static const double maxSheetWidth = 960;

  /// Keeps very large system fonts usable on compact layouts while allowing
  /// more scaling when the screen has enough room.
  static double maxTextScale(Size size) {
    if (size.width < 600 || size.height < 600) return 1.3;
    if (size.width < 1024) return 1.5;
    return 1.75;
  }

  static bool usesNavigationRail(BoxConstraints constraints) =>
      constraints.maxWidth >= navigationRailWidth &&
      constraints.maxHeight >= navigationRailHeight;

  static double pageGutter(double width) {
    if (width >= 1024) return 32;
    if (width >= 600) return 24;
    return 16;
  }
}

/// Applies the user's system font preference up to the amount the current
/// screen can safely accommodate.
class ResponsiveTextScale extends StatelessWidget {
  const ResponsiveTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxScaleFactor = AppResponsive.maxTextScale(
      MediaQuery.sizeOf(context),
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxScaleFactor,
      child: child,
    );
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
  Widget build(BuildContext context) => SizedBox.expand(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox.expand(child: child),
      ),
    ),
  );
}
