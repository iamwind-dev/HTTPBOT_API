import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../generated/assets.gen.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/disk_usage_models.dart';
import '../../domain/services/disk_usage_service.dart';
import '../../domain/services/disk_usage_size_formatter.dart';
import '../cubit/disk_usage_cubit.dart';
import '../cubit/disk_usage_state.dart';
import '../cubit/history_disk_usage_cubit.dart';
import '../cubit/history_disk_usage_state.dart';

class SettingsDiskUsagePage extends StatelessWidget {
  const SettingsDiskUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiskUsageCubit, DiskUsageState>(
      listenWhen: (previous, current) => current.message.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
      },
      builder: (context, state) {
        if (state.status == DiskUsageStatus.loading ||
            state.status == DiskUsageStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == DiskUsageStatus.error &&
            state.requestUsages.isEmpty &&
            state.fileUsages.isEmpty) {
          return const _CenteredMessage('Unable to load disk usage.');
        }

        return _DiskUsageContent(state: state);
      },
    );
  }
}

class DiskUsageTabPicker extends StatelessWidget {
  const DiskUsageTabPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiskUsageCubit, DiskUsageState>(
      builder: (context, state) => PopupMenuButton<DiskUsageTab>(
        tooltip: 'Disk usage type',
        color: context.appColors.card,
        initialValue: state.selectedTab,
        onSelected: context.read<DiskUsageCubit>().switchTab,
        itemBuilder: (context) => const [
          PopupMenuItem(value: DiskUsageTab.requests, child: Text('Requests')),
          PopupMenuItem(value: DiskUsageTab.files, child: Text('Files')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.headerActionSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.appColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.selectedTab == DiskUsageTab.requests
                    ? 'Requests'
                    : 'Files',
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 18,
                color: context.appColors.iconPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiskUsageContent extends StatelessWidget {
  const _DiskUsageContent({required this.state});

  final DiskUsageState state;

  @override
  Widget build(BuildContext context) {
    final isRequests = state.selectedTab == DiskUsageTab.requests;
    final isEmpty = isRequests
        ? state.requestUsages.isEmpty
        : state.fileUsages.isEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: isEmpty
              ? _DiskUsageEmptyState(tab: state.selectedTab)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.medium,
                    0,
                    128,
                  ),
                  children: [
                    if (isRequests)
                      for (final item in state.requestUsages)
                        _RequestUsageTile(item: item, state: state)
                    else
                      for (final item in state.fileUsages)
                        _FileUsageTile(item: item, state: state),
                  ],
                ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _UsageBottomBar(
            count: state.selectionMode
                ? state.selectedCount
                : state.visibleCount,
            bytes: state.selectionMode
                ? state.selectedBytes
                : state.visibleBytes,
            noun: isRequests ? 'request' : 'file',
            hasSelection: state.selectionMode,
            isBusy: state.status == DiskUsageStatus.deleting,
            onSelectButtonPressed: () {
              state.selectionMode
                  ? context.read<DiskUsageCubit>().clearSelection()
                  : context.read<DiskUsageCubit>().selectAll();
            },
            onDeletePressed: state.selectionMode
                ? () => _confirmDelete(
                    context,
                    context.read<DiskUsageCubit>().deleteSelected,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _RequestUsageTile extends StatelessWidget {
  const _RequestUsageTile({required this.item, required this.state});

  final DiskUsageRequestItem item;
  final DiskUsageState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedRequestIds.contains(item.requestId);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFF00131F) : colors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (state.selectionMode) {
              context.read<DiskUsageCubit>().toggleRequest(item.requestId);
              return;
            }

            final cubit = context.read<DiskUsageCubit>();
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => HistoryDiskUsageCubit(
                        service: getIt<DiskUsageService>(),
                        requestId: item.requestId,
                      )..load(),
                      child: const RequestHistoryDiskUsagePage(),
                    ),
                  ),
                )
                .then((_) => cubit.load());
          },
          onLongPress: () =>
              context.read<DiskUsageCubit>().toggleRequest(item.requestId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                if (state.selectionMode) ...[
                  _SelectionCircle(selected: selected),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!state.selectionMode)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.iconSecondary,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileUsageTile extends StatelessWidget {
  const _FileUsageTile({required this.item, required this.state});

  final DiskUsageFileItem item;
  final DiskUsageState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedFileIds.contains(item.fileId);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFF00131F) : colors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.read<DiskUsageCubit>().toggleFile(item.fileId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                if (state.selectionMode) ...[
                  _SelectionCircle(selected: selected),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  DiskUsageSizeFormatter.format(item.totalBytes),
                  style: TextStyle(color: colors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RequestHistoryDiskUsagePage extends StatelessWidget {
  const RequestHistoryDiskUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HistoryDiskUsageCubit, HistoryDiskUsageState>(
      listenWhen: (previous, current) => current.message.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
      },
      builder: (context, state) {
        final colors = context.appColors;

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            foregroundColor: colors.textPrimary,
            elevation: 0,
            centerTitle: true,
            title: Text(
              state.selectionMode
                  ? '${state.selectedCount} Selected'
                  : 'History',
            ),
          ),
          body: Stack(
            children: [
              if (state.status == HistoryDiskUsageStatus.loading ||
                  state.status == HistoryDiskUsageStatus.initial)
                const Center(child: CircularProgressIndicator())
              else if (state.histories.isEmpty)
                const _RequestHistoryEmptyState()
              else
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                  children: [
                    for (final item in state.histories)
                      _HistoryUsageTile(item: item, state: state),
                  ],
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _UsageBottomBar(
                  count: state.selectionMode ? state.selectedCount : 0,
                  bytes: state.selectionMode ? state.selectedBytes : 0,
                  noun: 'request',
                  hasSelection: state.selectionMode,
                  isBusy: state.status == HistoryDiskUsageStatus.deleting,
                  onSelectButtonPressed: () {
                    state.selectionMode
                        ? context.read<HistoryDiskUsageCubit>().clearSelection()
                        : context.read<HistoryDiskUsageCubit>().selectAll();
                  },
                  onDeletePressed: state.selectionMode
                      ? () => _confirmDelete(
                          context,
                          context.read<HistoryDiskUsageCubit>().deleteSelected,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryUsageTile extends StatelessWidget {
  const _HistoryUsageTile({required this.item, required this.state});

  final DiskUsageHistoryItem item;
  final HistoryDiskUsageState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedHistoryIds.contains(item.historyId);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFF00131F) : colors.card,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.read<HistoryDiskUsageCubit>().toggleHistory(
            item.historyId,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                _SelectionCircle(selected: selected),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    DateFormat('d MMMM yyyy at HH:mm').format(item.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textPrimary, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DiskUsageSizeFormatter.format(item.totalBytes),
                  style: TextStyle(color: colors.textSecondary, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiskUsageEmptyState extends StatelessWidget {
  const _DiskUsageEmptyState({required this.tab});

  final DiskUsageTab tab;

  @override
  Widget build(BuildContext context) {
    if (tab == DiskUsageTab.files) {
      return const _FilesEmptyState();
    }

    return const _CenteredMessage(
      'No Request History\n\nResponse history from sent requests will appear here.',
    );
  }
}

class _FilesEmptyState extends StatelessWidget {
  const _FilesEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.icons.diskIc.svg(
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(
                colors.iconSecondary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Files',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Files uploaded from HTTPBot, or downloaded as response will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestHistoryEmptyState extends StatelessWidget {
  const _RequestHistoryEmptyState();

  @override
  Widget build(BuildContext context) => const _CenteredMessage(
    'No Request History\n\nResponse history from sent requests will appear here.',
  );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.appColors.textSecondary, fontSize: 18),
      ),
    ),
  );
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Icon(
        Icons.radio_button_unchecked_rounded,
        color: context.appColors.iconSecondary,
        size: 26,
      );
    }

    return const Icon(
      Icons.check_circle_rounded,
      color: Color(0xFF16A8FF),
      size: 26,
    );
  }
}

class _UsageBottomBar extends StatelessWidget {
  const _UsageBottomBar({
    required this.count,
    required this.bytes,
    required this.noun,
    required this.hasSelection,
    required this.isBusy,
    required this.onSelectButtonPressed,
    required this.onDeletePressed,
  });

  final int count;
  final int bytes;
  final String noun;
  final bool hasSelection;
  final bool isBusy;
  final VoidCallback onSelectButtonPressed;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label =
        '$count ${count == 1 ? noun : '${noun}s'} | '
        '${DiskUsageSizeFormatter.format(bytes)}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundActionButton(
              onPressed: onSelectButtonPressed,
              icon: hasSelection
                  ? Icons.close_rounded
                  : Icons.checklist_rounded,
              backgroundColor: colors.headerActionSurface,
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 150),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: colors.headerActionSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textPrimary, fontSize: 18),
              ),
            ),
            _RoundActionButton(
              onPressed: isBusy ? null : onDeletePressed,
              icon: Icons.delete_outline_rounded,
              backgroundColor: hasSelection
                  ? const Color(0xFFFF3B3F)
                  : colors.headerActionSurface,
              foregroundColor: hasSelection
                  ? Colors.black
                  : colors.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor,
    this.onPressed,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            icon,
            color: onPressed == null
                ? context.appColors.iconSecondary
                : foregroundColor ?? context.appColors.iconPrimary,
            size: 34,
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  Future<void> Function() delete,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Selected?'),
      content: const Text(
        'This will remove stored response history and files from this device. Requests themselves will not be deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await delete();
  }
}
