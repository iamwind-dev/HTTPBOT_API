import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/response_filter_entity.dart';
import '../../domain/helpers/filter_response_mode.dart';
import '../../domain/repositories/response_filter_repository.dart';
import '../cubit/response_filters_cubit.dart';
import '../cubit/response_filters_state.dart';
import 'request_modal_sheet.dart';
import 'response_filter_editor_sheet.dart';

/// Opens the saved Response Filters list.
///
/// When [pickMode] is true (opened from Filter Response), tapping a filter
/// applies it and the sheet pops with the selected entity. Otherwise tapping
/// opens the editor (opened from Settings).
Future<ResponseFilterEntity?> showResponseFiltersSheet(
  BuildContext context, {
  bool pickMode = false,
}) => showRequestModalSheet<ResponseFilterEntity>(
  context,
  builder: (context) => BlocProvider<ResponseFiltersCubit>(
    create: (_) =>
        ResponseFiltersCubit(getIt<ResponseFilterRepository>())..load(),
    child: _ResponseFiltersSheet(pickMode: pickMode),
  ),
);

/// Embedded (non-modal) Response Filters manager for the Settings detail page.
///
/// Reuses the same cubit and list as the sheet, but renders inline with only an
/// add action — tapping a filter opens the editor (manage mode).
class ResponseFiltersView extends StatelessWidget {
  const ResponseFiltersView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ResponseFiltersCubit>(
    create: (_) =>
        ResponseFiltersCubit(getIt<ResponseFilterRepository>())..load(),
    child: const _ResponseFiltersViewBody(),
  );
}

class _ResponseFiltersViewBody extends StatelessWidget {
  const _ResponseFiltersViewBody();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
          child: IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.responseFiltersAddButton,
            ),
            tooltip: AppStrings.responseFilterEditorAddTitle,
            onPressed: () => _addFilter(context),
            icon: const Icon(CupertinoIcons.add, size: AppSpacing.large),
          ),
        ),
      ),
      Expanded(
        child: BlocBuilder<ResponseFiltersCubit, ResponseFiltersState>(
          builder: (context, state) {
            if (state.status == ResponseFiltersStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.filters.isEmpty) {
              return const _EmptyState();
            }
            return _FiltersList(filters: state.filters, pickMode: false);
          },
        ),
      ),
    ],
  );

  Future<void> _addFilter(BuildContext context) async {
    final cubit = context.read<ResponseFiltersCubit>();
    final draft = await showResponseFilterEditorSheet(context);
    if (draft == null) {
      return;
    }
    await cubit.create(name: draft.name, query: draft.query, mode: draft.mode);
  }
}

class _ResponseFiltersSheet extends StatelessWidget {
  const _ResponseFiltersSheet({required this.pickMode});

  final bool pickMode;

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.responseFiltersSheet),
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.small),
        _header(context),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: BlocBuilder<ResponseFiltersCubit, ResponseFiltersState>(
            builder: (context, state) {
              if (state.status == ResponseFiltersStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.filters.isEmpty) {
                return const _EmptyState();
              }
              return _FiltersList(filters: state.filters, pickMode: pickMode);
            },
          ),
        ),
      ],
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
    child: Row(
      children: [
        IconButton(
          tooltip: AppStrings.requestResponseCloseTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
        ),
        Expanded(
          child: Text(
            AppStrings.responseFiltersTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          key: const ValueKey<String>(
            AppWidgetKeys.responseFiltersAddButton,
          ),
          tooltip: AppStrings.responseFilterEditorAddTitle,
          onPressed: () => _addFilter(context),
          icon: const Icon(CupertinoIcons.add, size: AppSpacing.large),
        ),
      ],
    ),
  );

  Future<void> _addFilter(BuildContext context) async {
    final cubit = context.read<ResponseFiltersCubit>();
    final draft = await showResponseFilterEditorSheet(context);
    if (draft == null) {
      return;
    }
    await cubit.create(
      name: draft.name,
      query: draft.query,
      mode: draft.mode,
    );
  }
}

class _FiltersList extends StatelessWidget {
  const _FiltersList({required this.filters, required this.pickMode});

  final List<ResponseFilterEntity> filters;
  final bool pickMode;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.large,
      0,
      AppSpacing.large,
      AppSpacing.large,
    ),
    itemCount: filters.length,
    itemBuilder: (context, index) {
      final filter = filters[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.small),
        child: _FilterTile(
          key: ValueKey<String>(
            AppWidgetKeys.responseFilterListItemAt(index),
          ),
          filter: filter,
          pickMode: pickMode,
        ),
      );
    },
  );
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    super.key,
    required this.filter,
    required this.pickMode,
  });

  final ResponseFilterEntity filter;
  final bool pickMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.background,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filter.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxSmall),
                    Text(
                      filter.query,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                filter.mode.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: AppStrings.responseFilterDelete,
                onPressed: () =>
                    context.read<ResponseFiltersCubit>().delete(filter.id),
                icon: const Icon(CupertinoIcons.delete, size: AppSpacing.large),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (pickMode) {
      Navigator.of(context).pop(filter);
      return;
    }

    final cubit = context.read<ResponseFiltersCubit>();
    final draft = await showResponseFilterEditorSheet(
      context,
      existing: filter,
    );
    if (draft == null) {
      return;
    }
    await cubit.update(
      filter.copyWith(name: draft.name, query: draft.query, mode: draft.mode),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.responseFiltersEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            AppStrings.responseFiltersEmptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
