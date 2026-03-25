import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/request_list_item.dart';

class RequestListItemCard extends StatelessWidget {
  const RequestListItemCard({super.key, required this.item});

  final RequestListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xSmall),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequestMethodBadge(method: item.method),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xSmall),
                Text(item.url, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestMethodBadge extends StatelessWidget {
  const _RequestMethodBadge({required this.method});

  final String method;

  // Keep every method badge aligned to a shared four-character width.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: AppSpacing.xxxLarge + AppSpacing.xSmall,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xxSmall,
      ),
      decoration: BoxDecoration(
        color: _badgeColor(method),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(
        method,
        style: theme.textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _badgeColor(String value) => switch (value.toUpperCase()) {
    'GET' => AppColors.methodGet,
    'POST' => AppColors.methodPost,
    'PUT' => AppColors.methodPut,
    'DEL' => AppColors.methodDelete,
    'PAT' => AppColors.methodPatch,
    'HEAD' => AppColors.methodHead,
    'OPTI' => AppColors.methodOptions,
    'CON' => AppColors.methodConnect,
    _ => AppColors.chipNeutral,
  };
}
