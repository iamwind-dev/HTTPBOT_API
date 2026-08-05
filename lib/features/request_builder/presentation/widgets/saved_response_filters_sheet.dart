import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/app_popup_menu.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/response_filter.dart';
import '../../domain/helpers/response_filter_utils.dart';
import '../cubit/manage_response_filters_cubit.dart';
import '../cubit/manage_response_filters_state.dart';
import 'request_modal_sheet.dart';

enum SavedResponseFiltersMode { manage, select }

class ResponseFilterEditorDraft {
  const ResponseFilterEditorDraft({
    required this.name,
    required this.filterType,
    required this.query,
  });

  final String name;
  final ResponseFilterType filterType;
  final String query;
}

Future<ResponseFilter?> showSavedResponseFiltersSheet(BuildContext context) =>
    showRequestModalSheet<ResponseFilter?>(
      context,
      builder: (sheetContext) => BlocProvider<ManageResponseFiltersCubit>(
        create: (_) => getIt<ManageResponseFiltersCubit>()..load(),
        child: const _SavedResponseFiltersSheet(
          mode: SavedResponseFiltersMode.select,
        ),
      ),
    );

Future<ResponseFilterEditorDraft?> showResponseFilterEditorSheet(
  BuildContext context, {
  ResponseFilter? initialFilter,
  ResponseFilterType? initialFilterType,
  String initialName = '',
  String initialQuery = '',
}) => showRequestModalSheet<ResponseFilterEditorDraft?>(
  context,
  builder: (context) => _ResponseFilterEditorSheet(
    initialFilter: initialFilter,
    initialFilterType: initialFilterType,
    initialName: initialName,
    initialQuery: initialQuery,
  ),
);

class SavedResponseFiltersPage extends StatelessWidget {
  const SavedResponseFiltersPage({super.key, this.controller});

  final SavedResponseFiltersController? controller;

  @override
  Widget build(BuildContext context) =>
      BlocProvider<ManageResponseFiltersCubit>(
        create: (_) => getIt<ManageResponseFiltersCubit>()..load(),
        child: SavedResponseFiltersView(
          mode: SavedResponseFiltersMode.manage,
          controller: controller,
        ),
      );
}

class SavedResponseFiltersController {
  VoidCallback? openCreate;
  VoidCallback? deleteAll;
}

class _SavedResponseFiltersSheet extends StatelessWidget {
  const _SavedResponseFiltersSheet({required this.mode});

  final SavedResponseFiltersMode mode;

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.settingsResponseFiltersSheet),
    child: SavedResponseFiltersView(mode: mode, useSheetScaffold: true),
  );
}

class SavedResponseFiltersView extends StatelessWidget {
  const SavedResponseFiltersView({
    super.key,
    required this.mode,
    this.controller,
    this.useSheetScaffold = false,
  });

  final SavedResponseFiltersMode mode;
  final SavedResponseFiltersController? controller;
  final bool useSheetScaffold;

  @override
  Widget build(BuildContext context) {
    controller?.openCreate = () => _openCreateFilter(context);
    controller?.deleteAll = () =>
        context.read<ManageResponseFiltersCubit>().deleteAll();

    final list =
        BlocBuilder<ManageResponseFiltersCubit, ManageResponseFiltersState>(
          builder: (context, state) {
            if (state.status == ManageResponseFiltersStatus.loading &&
                state.filters.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ManageResponseFiltersStatus.failure &&
                state.filters.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: Text(
                    state.errorMessage.isEmpty
                        ? AppStrings.settingsResponseFilterUnableToLoad
                        : state.errorMessage,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state.filters.isEmpty) {
              return const _SavedResponseFiltersEmptyState();
            }

            return ListView.separated(
              padding: EdgeInsets.only(
                top: useSheetScaffold ? 0 : AppSpacing.medium,
                bottom: AppSpacing.xxxLarge,
              ),
              itemCount: state.filters.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.small),
              itemBuilder: (context, index) => _SavedResponseFilterTile(
                key: ValueKey<String>(
                  AppWidgetKeys.settingsResponseFilterListItemAt(index),
                ),
                filter: state.filters[index],
                mode: mode,
              ),
            );
          },
        );

    if (!useSheetScaffold) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
        child: list,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        children: [
          _SavedResponseFiltersHeader(
            onClose: () => Navigator.of(context).maybePop(),
            onDeleteAll:
                controller?.deleteAll ??
                () => context.read<ManageResponseFiltersCubit>().deleteAll(),
            onAdd: () => _openCreateFilter(context),
          ),
          const SizedBox(height: AppSpacing.large),
          Expanded(child: list),
        ],
      ),
    );
  }

  Future<void> _openCreateFilter(BuildContext context) async {
    final result = await showResponseFilterEditorSheet(context);
    if (result == null || !context.mounted) {
      return;
    }

    final now = DateTime.now();
    await context.read<ManageResponseFiltersCubit>().saveFilter(
      ResponseFilter(
        id: now.microsecondsSinceEpoch.toString(),
        name: buildResponseFilterName(
          proposedName: result.name,
          query: result.query,
        ),
        filterType: result.filterType,
        query: result.query,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _SavedResponseFiltersHeader extends StatelessWidget {
  const _SavedResponseFiltersHeader({
    required this.onClose,
    required this.onDeleteAll,
    required this.onAdd,
  });

  final VoidCallback onClose;
  final VoidCallback onDeleteAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        IconButton(onPressed: onClose, icon: const Icon(CupertinoIcons.back)),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            AppStrings.settingsResponseFilters,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
          ),
          child: PopupMenuButton<String>(
            key: const ValueKey<String>(
              AppWidgetKeys.settingsResponseFiltersMoreButton,
            ),
            onSelected: (_) => onDeleteAll(),
            icon: const Icon(CupertinoIcons.ellipsis),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'delete_all',
                child: AppPopupMenuRow(
                  icon: CupertinoIcons.trash,
                  label: AppStrings.settingsResponseFilterDeleteAll,
                  destructive: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
          ),
          child: IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.settingsResponseFiltersAddButton,
            ),
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add),
          ),
        ),
      ],
    );
  }
}

class _SavedResponseFiltersEmptyState extends StatelessWidget {
  const _SavedResponseFiltersEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      key: const ValueKey<String>(
        AppWidgetKeys.settingsResponseFiltersEmptyState,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.line_horizontal_3_decrease,
            size: AppSpacing.xxxLarge,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            AppStrings.settingsResponseFiltersEmpty,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedResponseFilterTile extends StatelessWidget {
  const _SavedResponseFilterTile({
    super.key,
    required this.filter,
    required this.mode,
  });

  final ResponseFilter filter;
  final SavedResponseFiltersMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
        onTap: () => _handleTap(context),
        onLongPress: () => _showActions(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xxxSmall),
                Text(
                  filter.filterType.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  filter.query,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (mode == SavedResponseFiltersMode.select) {
      Navigator.of(context).pop(filter);
      return;
    }

    unawaited(_edit(context));
  }

  Future<void> _edit(BuildContext context) async {
    final result = await showResponseFilterEditorSheet(
      context,
      initialFilter: filter,
      initialFilterType: filter.filterType,
      initialName: filter.name,
      initialQuery: filter.query,
    );
    if (result == null || !context.mounted) {
      return;
    }

    await context.read<ManageResponseFiltersCubit>().saveFilter(
      filter.copyWith(
        name: buildResponseFilterName(
          proposedName: result.name,
          query: result.query,
        ),
        filterType: result.filterType,
        query: result.query,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.xxLarge),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Edit'),
                  onTap: () => Navigator.of(sheetContext).pop('edit'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Delete'),
                  onTap: () => Navigator.of(sheetContext).pop('delete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (action == 'edit') {
      await _edit(context);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.settingsResponseFilterDeleteTitle),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.settingsResponseFilterDeleteMessage),
              SizedBox(height: AppSpacing.small),
              Text(AppStrings.settingsResponseFilterDeleteNote),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.settingsResponseFilterCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.settingsResponseFilterDelete),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await context.read<ManageResponseFiltersCubit>().delete(filter.id);
      }
    }
  }
}

class _ResponseFilterEditorSheet extends StatefulWidget {
  const _ResponseFilterEditorSheet({
    required this.initialFilter,
    required this.initialFilterType,
    required this.initialName,
    required this.initialQuery,
  });

  final ResponseFilter? initialFilter;
  final ResponseFilterType? initialFilterType;
  final String initialName;
  final String initialQuery;

  @override
  State<_ResponseFilterEditorSheet> createState() =>
      _ResponseFilterEditorSheetState();
}

class _ResponseFilterEditorSheetState
    extends State<_ResponseFilterEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late ResponseFilterType _filterType;
  String? _valueError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _valueController = TextEditingController(text: widget.initialQuery);
    _filterType = widget.initialFilterType ?? ResponseFilterType.jq;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _valueController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _valueError = AppStrings.settingsResponseFilterQueryRequired;
      });
      return;
    }

    Navigator.of(context).pop(
      ResponseFilterEditorDraft(
        name: _nameController.text,
        filterType: _filterType,
        query: _valueController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey<String>(
                    AppWidgetKeys.requestsEditorCloseButton,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark),
                ),
                Expanded(
                  child: Text(
                    AppStrings.settingsResponseFilterTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submit,
                  icon: const Icon(CupertinoIcons.check_mark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.xxLarge),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    TextField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.settingsResponseFilterNameField,
                      ),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.settingsResponseFilterNameHint,
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.settingsResponseFilterType,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        DropdownButton<ResponseFilterType>(
                          key: const ValueKey<String>(
                            AppWidgetKeys.settingsResponseFilterTypeField,
                          ),
                          value: _filterType,
                          underline: const SizedBox.shrink(),
                          items: ResponseFilterType.values
                              .map(
                                (type) => DropdownMenuItem<ResponseFilterType>(
                                  value: type,
                                  child: Text(type.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _filterType = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.settingsResponseFilterValueField,
                      ),
                      controller: _valueController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: AppStrings.settingsResponseFilterValue,
                        border: InputBorder.none,
                        errorText: _valueError,
                      ),
                      onChanged: (_) {
                        if (_valueError != null) {
                          setState(() {
                            _valueError = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
