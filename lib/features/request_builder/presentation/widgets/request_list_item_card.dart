import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../models/request_list_item.dart';

class RequestListItemCard extends StatelessWidget {
  const RequestListItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RequestListItem item;
  final VoidCallback onTap;

  /// Builds a tappable request summary card for the requests list.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
        splashFactory: NoSplash.splashFactory,
        highlightColor: colors.primarySoft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xSmall),
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
        ),
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
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      width: AppSpacing.xxxLarge + AppSpacing.xSmall,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xxSmall,
      ),
      decoration: BoxDecoration(
        color: colors.methodColor(method),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(
        method,
        style: theme.textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
