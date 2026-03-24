import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/request_draft.dart';

class RequestSummaryCard extends StatelessWidget {
  const RequestSummaryCard({super.key, required this.draft});

  final RequestDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.requestSummaryTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.medium),
            _SummaryRow(label: AppStrings.methodLabel, value: draft.method),
            const SizedBox(height: AppSpacing.small),
            _SummaryRow(label: AppStrings.urlLabel, value: draft.url),
            const SizedBox(height: AppSpacing.small),
            _SummaryRow(label: AppStrings.authLabel, value: draft.authMode),
            const SizedBox(height: AppSpacing.small),
            _SummaryRow(label: AppStrings.bodyModeLabel, value: draft.bodyMode),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xSmall),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
