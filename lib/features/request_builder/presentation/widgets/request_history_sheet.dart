import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../../request_history/domain/entities/request_history_entry.dart';
import '../../../request_history/presentation/cubit/request_history_cubit.dart';
import '../../../request_history/presentation/cubit/request_history_state.dart';
import 'request_modal_sheet.dart';

/// Opens the request History sheet; returns the entry the user selected, if any.
Future<RequestHistoryEntry?> showRequestHistorySheet(BuildContext context) =>
    showRequestModalSheet<RequestHistoryEntry>(
      context,
      builder: (context) => BlocProvider<RequestHistoryCubit>(
        create: (_) => getIt<RequestHistoryCubit>()..load(),
        child: const _RequestHistorySheet(),
      ),
    );

class _RequestHistorySheet extends StatelessWidget {
  const _RequestHistorySheet();

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestHistorySheet),
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.small),
        _header(context),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: BlocBuilder<RequestHistoryCubit, RequestHistoryState>(
            builder: (context, state) {
              if (state.status == RequestHistoryStatus.loading ||
                  state.status == RequestHistoryStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.isEmpty) {
                return const _EmptyState();
              }
              return _HistoryList(entries: state.entries);
            },
          ),
        ),
        const _HistoryFooter(),
      ],
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey<String>(
            AppWidgetKeys.requestHistoryCloseButton,
          ),
          tooltip: AppStrings.historyCloseTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
        ),
        Expanded(
          child: Text(
            AppStrings.historyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<RequestHistoryEntry> entries;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.large,
      0,
      AppSpacing.large,
      AppSpacing.large,
    ),
    itemCount: entries.length,
    separatorBuilder: (_, __) => const Divider(height: AppSpacing.large),
    itemBuilder: (context, index) {
      final entry = entries[index];
      return _HistoryTile(
        key: ValueKey<String>(AppWidgetKeys.requestHistoryItemAt(index)),
        entry: entry,
        onTap: () => Navigator.of(context).pop(entry),
      );
    },
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final RequestHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusCode = entry.response.statusCode;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatTimestamp(entry.sentAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              statusCode?.toString() ?? '—',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _statusColor(context, statusCode, entry.response.hasError),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.small,
        AppSpacing.large,
        AppSpacing.medium,
      ),
      child: Text(
        AppStrings.historyFooter,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      AppStrings.historyEmptyTitle,
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

Color _statusColor(BuildContext context, int? statusCode, bool hasError) {
  final colors = context.appColors;
  if (statusCode == null || hasError) {
    return colors.methodDelete;
  }
  if (statusCode >= 500) {
    return colors.methodDelete;
  }
  if (statusCode >= 300) {
    return colors.methodPost;
  }
  return colors.methodGet;
}

String _formatTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day} ${months[local.month - 1]} ${local.year} '
      'at $hour12:$minute $period';
}
