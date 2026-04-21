import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_theme_context.dart';

class WebSocketShellActionButton extends StatelessWidget {
  const WebSocketShellActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FloatingActionButton(
      key: const ValueKey<String>(AppWidgetKeys.websocketsFab),
      heroTag: AppWidgetKeys.websocketsFab,
      tooltip: AppStrings.requestsAddTooltip,
      onPressed: () {},
      backgroundColor: colors.methodGet,
      foregroundColor: colors.textOnPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded),
    );
  }
}
