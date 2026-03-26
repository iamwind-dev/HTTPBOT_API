import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/settings_section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onItemSelected});

  final ValueChanged<String> onItemSelected;

  // Render the grouped settings overview from typed section descriptors.
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;

    return ListView.builder(
      key: const ValueKey<String>(AppWidgetKeys.settingsList),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.medium,
        bottom: AppSpacing.xxxLarge + AppSpacing.medium,
      ),
      itemCount: state.sections.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(
          bottom: index == state.sections.length - 1 ? 0 : AppSpacing.large,
        ),
        child: SettingsSectionCard(
          section: state.sections[index],
          onItemSelected: onItemSelected,
        ),
      ),
    );
  }
}
