import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/request_builder_cubit.dart';
import '../cubit/request_builder_state.dart';
import '../widgets/request_summary_card.dart';

class RequestBuilderPage extends StatelessWidget {
  const RequestBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: SafeArea(
        child: BlocBuilder<RequestBuilderCubit, RequestBuilderState>(
          builder: (context, state) {
            final draft = state.draft;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                Text(
                  AppStrings.requestBuilderTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  AppStrings.requestBuilderSubtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.large),
                RequestSummaryCard(draft: draft),
              ],
            );
          },
        ),
      ),
    );
  }
}
