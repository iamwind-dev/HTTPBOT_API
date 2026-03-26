import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';

class SettingsDetailPage extends StatelessWidget {
  const SettingsDetailPage({super.key});

  // Render a lightweight placeholder body for settings destinations that are not implemented yet.
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Text(
        AppStrings.settingsDetailUnavailableMessage,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
