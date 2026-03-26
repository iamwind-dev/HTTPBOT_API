import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_theme_context.dart';

class RequestShellActionButton extends StatelessWidget {
  const RequestShellActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FloatingActionButton(
      key: const ValueKey<String>(AppWidgetKeys.requestsFab),
      tooltip: AppStrings.requestsAddTooltip,
      onPressed: () {},
      backgroundColor: colors.methodGet,
      foregroundColor: colors.textOnPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded),
    );
  }
}
