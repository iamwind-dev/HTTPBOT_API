import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onItemSelected});

  final ValueChanged<String> onItemSelected;

  // Render the grouped settings overview from typed section descriptors.
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;

    return ColoredBox(
      color: context.appColors.background,
      child: SingleChildScrollView(
        key: const ValueKey<String>(AppWidgetKeys.settingsList),
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacing.medium,
          0,
          AppSpacing.xxxLarge + AppSpacing.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, section) in state.sections.indexed)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == state.sections.length - 1
                      ? 0
                      : AppSpacing.large,
                ),
                child: SettingsSection(
                  section: section,
                  onItemSelected: onItemSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
