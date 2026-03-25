import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_colors.dart';

class RequestShellActionButton extends StatelessWidget {
  const RequestShellActionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    key: const ValueKey<String>(AppWidgetKeys.requestsFab),
    tooltip: AppStrings.requestsAddTooltip,
    onPressed: () {},
    backgroundColor: AppColors.methodGet,
    foregroundColor: AppColors.textOnPrimary,
    shape: const CircleBorder(),
    child: const Icon(Icons.add_rounded),
  );
}
