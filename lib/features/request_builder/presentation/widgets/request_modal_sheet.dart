import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';

/// Opens a request-related modal sheet using the shared full-screen slide-up presentation.
Future<T?> showRequestModalSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  enableDrag: true,
  isDismissible: true,
  backgroundColor: Colors.transparent,
  barrierColor: context.appColors.modalBarrier,
  builder: builder,
);

class RequestModalSheetCard extends StatelessWidget {
  const RequestModalSheetCard({super.key, required this.child});

  final Widget child;

  /// Wraps content in the shared rounded-top request sheet shell.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FractionallySizedBox(
      heightFactor: 1,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.modalShadow,
                blurRadius: AppSpacing.large,
                offset: const Offset(0, -AppSpacing.xxSmall),
              ),
            ],
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
