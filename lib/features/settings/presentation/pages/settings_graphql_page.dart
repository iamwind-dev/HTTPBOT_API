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
import '../../../request_builder/domain/entities/saved_graphql_query_entity.dart';
import '../../../request_builder/domain/entities/saved_graphql_variable_entity.dart';
import '../../../request_builder/domain/helpers/graphql_input_utils.dart';
import '../../../request_builder/domain/usecases/get_saved_graphql_queries_use_case.dart';
import '../../../request_builder/domain/usecases/get_saved_graphql_variables_use_case.dart';
import '../../../request_builder/domain/usecases/save_saved_graphql_queries_use_case.dart';
import '../../../request_builder/domain/usecases/save_saved_graphql_variables_use_case.dart';
import '../../../request_builder/presentation/widgets/request_modal_sheet.dart';
import '../cubit/graphql_settings_cubit.dart';
import '../cubit/graphql_settings_state.dart';

class SettingsGraphQlPage extends StatefulWidget {
  const SettingsGraphQlPage({super.key});

  @override
  State<SettingsGraphQlPage> createState() => _SettingsGraphQlPageState();
}

class _SettingsGraphQlPageState extends State<SettingsGraphQlPage> {
  late final GraphQlSettingsCubit _cubit = GraphQlSettingsCubit(
    getSavedGraphQlQueriesUseCase: getIt<GetSavedGraphQlQueriesUseCase>(),
    saveSavedGraphQlQueriesUseCase: getIt<SaveSavedGraphQlQueriesUseCase>(),
    getSavedGraphQlVariablesUseCase: getIt<GetSavedGraphQlVariablesUseCase>(),
    saveSavedGraphQlVariablesUseCase: getIt<SaveSavedGraphQlVariablesUseCase>(),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider<GraphQlSettingsCubit>.value(
        value: _cubit,
        child: BlocBuilder<GraphQlSettingsCubit, GraphQlSettingsState>(
          builder: (context, state) => Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GraphQlSettingsToolbar(
                  selectedTab: state.selectedTab,
                  onTabChanged: (tab) =>
                      context.read<GraphQlSettingsCubit>().switchTab(tab),
                  onAddPressed: () =>
                      _openCreateSheet(context, state.selectedTab),
                  onHelpPressed: () => _openHelp(context),
                ),
                const SizedBox(height: AppSpacing.large),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
        ),
      );

  Widget _buildBody(BuildContext context, GraphQlSettingsState state) {
    if (state.status == GraphQlSettingsStatus.loading &&
        state.queries.isEmpty &&
        state.variables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == GraphQlSettingsStatus.error &&
        (state.errorMessage?.trim().isNotEmpty ?? false)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return switch (state.selectedTab) {
      GraphQlSettingsTab.queries => _SavedGraphQlQueriesList(
        items: state.queries,
        onTap: (item) => _openEditQuery(context, item),
        onDelete: (item) => _deleteQuery(context, item),
      ),
      GraphQlSettingsTab.variables => _SavedGraphQlVariablesList(
        items: state.variables,
        onTap: (item) => _openEditVariables(context, item),
        onDelete: (item) => _deleteVariables(context, item),
      ),
    };
  }

  Future<void> _openCreateSheet(
    BuildContext context,
    GraphQlSettingsTab tab,
  ) async {
    if (tab == GraphQlSettingsTab.queries) {
      await _openEditQuery(context, null);
      return;
    }

    await _openEditVariables(context, null);
  }

  Future<void> _openEditQuery(
    BuildContext context,
    SavedGraphQlQueryEntity? item,
  ) async {
    final result = await showRequestModalSheet<_SavedGraphQlQueryDraft?>(
      context,
      builder: (context) => _SavedGraphQlQueryEditorSheet(initialItem: item),
    );
    if (result == null || !context.mounted) {
      return;
    }

    final now = DateTime.now();
    await context.read<GraphQlSettingsCubit>().saveQuery(
      SavedGraphQlQueryEntity(
        id: item?.id ?? now.microsecondsSinceEpoch.toString(),
        name: buildSavedGraphQlQueryName(
          proposedName: result.name,
          query: result.query,
        ),
        query: result.query,
        createdAt: item?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _openEditVariables(
    BuildContext context,
    SavedGraphQlVariableEntity? item,
  ) async {
    final result = await showRequestModalSheet<_SavedGraphQlVariablesDraft?>(
      context,
      builder: (context) =>
          _SavedGraphQlVariablesEditorSheet(initialItem: item),
    );
    if (result == null || !context.mounted) {
      return;
    }

    final now = DateTime.now();
    await context.read<GraphQlSettingsCubit>().saveVariables(
      SavedGraphQlVariableEntity(
        id: item?.id ?? now.microsecondsSinceEpoch.toString(),
        name: buildSavedGraphQlVariablesName(
          proposedName: result.name,
          variablesJson: result.variablesJson,
        ),
        variables: result.variablesJson,
        createdAt: item?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _deleteQuery(
    BuildContext context,
    SavedGraphQlQueryEntity item,
  ) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<GraphQlSettingsCubit>().deleteQuery(item.id);
  }

  Future<void> _deleteVariables(
    BuildContext context,
    SavedGraphQlVariableEntity item,
  ) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<GraphQlSettingsCubit>().deleteVariables(item.id);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Item?'),
          content: const Text(
            'Are you sure you would like to delete this item?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  Future<void> _openHelp(BuildContext context) async {
    await showRequestModalSheet<void>(
      context,
      builder: (context) => const _GraphQlHelpSheet(),
    );
  }
}

class _GraphQlSettingsToolbar extends StatelessWidget {
  const _GraphQlSettingsToolbar({
    required this.selectedTab,
    required this.onTabChanged,
    required this.onAddPressed,
    required this.onHelpPressed,
  });

  final GraphQlSettingsTab selectedTab;
  final ValueChanged<GraphQlSettingsTab> onTabChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onHelpPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xSmall),
            child: CupertinoSlidingSegmentedControl<GraphQlSettingsTab>(
              key: const ValueKey<String>(
                AppWidgetKeys.settingsGraphQlSegmentedControl,
              ),
              groupValue: selectedTab,
              children: const {
                GraphQlSettingsTab.queries: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
                  child: Text(AppStrings.settingsGraphqlQueries),
                ),
                GraphQlSettingsTab.variables: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
                  child: Text(AppStrings.settingsGraphqlVariables),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.small),
      IconButton(
        key: const ValueKey<String>(AppWidgetKeys.settingsGraphQlHelpButton),
        onPressed: onHelpPressed,
        icon: const Icon(Icons.help_outline_rounded),
      ),
      const SizedBox(width: AppSpacing.xSmall),
      DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.xxLarge),
          ),
        ),
        child: IconButton(
          key: const ValueKey<String>(AppWidgetKeys.settingsGraphQlAddButton),
          onPressed: onAddPressed,
          icon: const Icon(CupertinoIcons.add),
        ),
      ),
    ],
  );
}

class _SavedGraphQlQueriesList extends StatelessWidget {
  const _SavedGraphQlQueriesList({
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  final List<SavedGraphQlQueryEntity> items;
  final ValueChanged<SavedGraphQlQueryEntity> onTap;
  final ValueChanged<SavedGraphQlQueryEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SavedGraphQlEmptyState(
        message: AppStrings.settingsGraphqlNoSavedQueries,
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
      itemBuilder: (context, index) => _SavedGraphQlListTile(
        key: ValueKey<String>(
          AppWidgetKeys.settingsGraphQlListItemAt('queries', index),
        ),
        title: items[index].name,
        preview: items[index].query,
        onTap: () => onTap(items[index]),
        onDelete: () => onDelete(items[index]),
      ),
    );
  }
}

class _SavedGraphQlVariablesList extends StatelessWidget {
  const _SavedGraphQlVariablesList({
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  final List<SavedGraphQlVariableEntity> items;
  final ValueChanged<SavedGraphQlVariableEntity> onTap;
  final ValueChanged<SavedGraphQlVariableEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SavedGraphQlEmptyState(
        message: AppStrings.settingsGraphqlNoSavedVariables,
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
      itemBuilder: (context, index) => _SavedGraphQlListTile(
        key: ValueKey<String>(
          AppWidgetKeys.settingsGraphQlListItemAt('variables', index),
        ),
        title: items[index].name,
        preview: items[index].variables,
        onTap: () => onTap(items[index]),
        onDelete: () => onDelete(items[index]),
      ),
    );
  }
}

class _SavedGraphQlListTile extends StatelessWidget {
  const _SavedGraphQlListTile({
    super.key,
    required this.title,
    required this.preview,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String preview;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.xxLarge),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      _truncatePreview(preview),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else {
                    onTap();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: AppPopupMenuRow(
                      icon: CupertinoIcons.pencil,
                      label: 'Edit',
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: AppPopupMenuRow(
                      icon: CupertinoIcons.trash,
                      label: 'Delete',
                      destructive: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _truncatePreview(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 80) {
      return compact;
    }

    return '${compact.substring(0, 77)}...';
  }
}

class _SavedGraphQlEmptyState extends StatelessWidget {
  const _SavedGraphQlEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey<String>(AppWidgetKeys.settingsGraphQlEmptyState),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.data_object_rounded,
          size: 72,
          color: context.appColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          message,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _SavedGraphQlQueryDraft {
  const _SavedGraphQlQueryDraft({required this.name, required this.query});

  final String name;
  final String query;
}

class _SavedGraphQlVariablesDraft {
  const _SavedGraphQlVariablesDraft({
    required this.name,
    required this.variablesJson,
  });

  final String name;
  final String variablesJson;
}

class _SavedGraphQlQueryEditorSheet extends StatefulWidget {
  const _SavedGraphQlQueryEditorSheet({this.initialItem});

  final SavedGraphQlQueryEntity? initialItem;

  @override
  State<_SavedGraphQlQueryEditorSheet> createState() =>
      _SavedGraphQlQueryEditorSheetState();
}

class _SavedGraphQlQueryEditorSheetState
    extends State<_SavedGraphQlQueryEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialItem?.name ?? '',
  );
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initialItem?.query ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_queryController.text.trim().isEmpty) {
      _showMessage(AppStrings.settingsGraphqlQueryRequired);
      return;
    }

    Navigator.of(context).pop(
      _SavedGraphQlQueryDraft(
        name: _nameController.text,
        query: _queryController.text,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            _EditorHeader(
              title: widget.initialItem == null
                  ? AppStrings.settingsGraphqlSaveQuery
                  : 'Edit Query',
              onSave: _save,
            ),
            const SizedBox(height: AppSpacing.large),
            DecoratedBox(
              decoration: _editorCardDecoration(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.settingsGraphQlEditorNameField,
                      ),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter a Name (Optional)',
                      ),
                    ),
                    Divider(color: context.appColors.border),
                    TextFormField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.settingsGraphQlEditorValueField,
                      ),
                      controller: _queryController,
                      maxLines: 12,
                      minLines: 8,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Value',
                      ),
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

class _SavedGraphQlVariablesEditorSheet extends StatefulWidget {
  const _SavedGraphQlVariablesEditorSheet({this.initialItem});

  final SavedGraphQlVariableEntity? initialItem;

  @override
  State<_SavedGraphQlVariablesEditorSheet> createState() =>
      _SavedGraphQlVariablesEditorSheetState();
}

class _SavedGraphQlVariablesEditorSheetState
    extends State<_SavedGraphQlVariablesEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialItem?.name ?? '',
  );
  late final TextEditingController _valueController = TextEditingController(
    text: widget.initialItem?.variables ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _valueController.text.trim();
    if (trimmed.isEmpty) {
      _showMessage(AppStrings.settingsGraphqlVariablesJsonInvalid);
      return;
    }

    final error = validateGraphQlVariablesInput(trimmed);
    if (error != null) {
      _showMessage(
        error == 'GraphQL variables must be a valid JSON object.'
            ? AppStrings.settingsGraphqlVariablesJsonInvalid
            : AppStrings.settingsGraphqlVariablesJsonObject,
      );
      return;
    }

    Navigator.of(context).pop(
      _SavedGraphQlVariablesDraft(
        name: _nameController.text,
        variablesJson: _valueController.text,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            _EditorHeader(title: 'GraphQL Variables', onSave: _save),
            const SizedBox(height: AppSpacing.large),
            DecoratedBox(
              decoration: _editorCardDecoration(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.settingsGraphQlEditorNameField,
                      ),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter a Name (Optional)',
                      ),
                    ),
                    Divider(color: context.appColors.border),
                    TextFormField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.settingsGraphQlEditorValueField,
                      ),
                      controller: _valueController,
                      maxLines: 12,
                      minLines: 8,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Value',
                      ),
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

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.title, required this.onSave});

  final String title;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark),
        ),
      ),
      const SizedBox(width: AppSpacing.small),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onSave,
          icon: const Icon(CupertinoIcons.check_mark),
        ),
      ),
    ],
  );
}

class _GraphQlHelpSheet extends StatelessWidget {
  const _GraphQlHelpSheet();

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.settingsGraphqlHelp,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpSection(
                      title: 'GraphQL',
                      body:
                          'GraphQL is available as a request body type in the Body section.',
                    ),
                    _HelpSection(
                      title: 'Enabling GraphQL',
                      body:
                          'Enable it from the request menu with Use GraphQL or by choosing GraphQL in the body type picker. If the current method is GET, HEAD, or DELETE, the app switches it to POST.',
                    ),
                    _HelpSection(
                      title: 'The query editor',
                      body:
                          'The Body section shows Query and Variables rows. Query is used for both queries and mutations. Variables accepts a JSON object whose keys match the variables declared in the query.',
                    ),
                    _HelpSection(
                      title: 'How it\'s sent',
                      body:
                          'Before sending, the app serializes query, variables, and operationName into a JSON body and sends it as application/json.',
                    ),
                    _HelpSection(
                      title: 'Schema-aware autocomplete',
                      body:
                          'This project does not yet include editor autocomplete infrastructure. Schema fetching is still wired so editor upgrades can reuse it later.',
                    ),
                    _HelpSection(
                      title: 'Browsing the schema',
                      body:
                          'View Schema runs a standard introspection query against the current request URL. If introspection fails, the editor still works as a plain code editor.',
                    ),
                    _HelpSection(
                      title: 'Saving and reusing queries',
                      body:
                          'Saved Queries and Saved Variables are stored separately, so you can mix and match them across requests.',
                    ),
                    _HelpSection(
                      title: 'Mutations',
                      body:
                          'Mutations use the same query editor flow and are intended for APIs that allow writes.',
                    ),
                    _HelpSection(
                      title: 'Variable substitution',
                      body:
                          'Query, variables, and operationName all support {{variable}} substitution from the active environment and global variables before send.',
                    ),
                    _HelpSection(
                      title: 'Related pages',
                      body:
                          'Request Body\nBuilding a Request\nEnvironments & Variables',
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

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.large),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xSmall),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

BoxDecoration _editorCardDecoration(BuildContext context) => BoxDecoration(
  color: context.appColors.surface,
  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
);
