import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../../postman/domain/usecases/load_postman_api_key_usecase.dart';
import '../../domain/entities/request_environment.dart';
import '../../domain/entities/request_variable.dart';
import '../../domain/helpers/environment_draft_validator.dart';
import '../../domain/helpers/environment_import_parser.dart';
import '../cubit/environment_menu_cubit.dart';
import '../cubit/environment_menu_state.dart';
import 'variable_rows_editor.dart';

enum _ManageEnvironmentsPlusAction { newEnvironment, importFile, importPostman }

enum _EnvironmentRowAction { edit, setActive, export, share, delete }

/// Opens the Manage Environments screen as a tall modal sheet.
///
/// When [cubit] is provided the caller keeps ownership and sees every change
/// live; otherwise the sheet creates and disposes its own cubit.
Future<void> showManageEnvironmentsSheet(
  BuildContext context, {
  EnvironmentMenuCubit? cubit,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: context.appColors.surface,
  builder: (sheetContext) => SizedBox(
    height: MediaQuery.of(sheetContext).size.height * 0.85,
    child: ManageEnvironmentsView(
      cubit: cubit,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  ),
);

/// Environment management screen reused by the request editor sheet and Settings.
class ManageEnvironmentsView extends StatefulWidget {
  const ManageEnvironmentsView({super.key, this.cubit, this.onClose});

  final EnvironmentMenuCubit? cubit;
  final VoidCallback? onClose;

  @override
  State<ManageEnvironmentsView> createState() => _ManageEnvironmentsViewState();
}

class _ManageEnvironmentsViewState extends State<ManageEnvironmentsView> {
  late final EnvironmentMenuCubit _cubit =
      widget.cubit ?? EnvironmentMenuCubit(getIt(), getIt());

  bool get _ownsCubit => widget.cubit == null;

  RequestEnvironmentSource _source = RequestEnvironmentSource.local;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.loadAvailableEnvironments());
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      unawaited(_cubit.close());
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _newEnvironmentId() => 'env_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _handlePlusAction(_ManageEnvironmentsPlusAction action) async {
    switch (action) {
      case _ManageEnvironmentsPlusAction.newEnvironment:
        await _createEnvironment();
      case _ManageEnvironmentsPlusAction.importFile:
        await _importFile();
      case _ManageEnvironmentsPlusAction.importPostman:
        await _importFromPostman();
    }
  }

  Future<void> _createEnvironment() async {
    final created = await showEnvironmentEditorSheet(
      context,
      environment: RequestEnvironment(id: _newEnvironmentId(), name: ''),
    );
    final environment = created?.environment;
    if (environment == null || !mounted) {
      return;
    }

    final hadActiveEnvironment =
        _cubit.state.store.selectedEnvironmentId.isNotEmpty;
    await _cubit.saveEnvironments([
      ..._cubit.state.store.environments,
      environment,
    ]);
    if (!hadActiveEnvironment) {
      await _cubit.selectEnvironment(environment.id);
    }

    if (mounted) {
      setState(() => _source = RequestEnvironmentSource.local);
    }
  }

  Future<void> _editEnvironment(RequestEnvironment environment) async {
    final result = await showEnvironmentEditorSheet(
      context,
      environment: environment,
      allowDelete: true,
    );
    if (result == null || !mounted) {
      return;
    }

    final environments = result.deleted
        ? _cubit.state.store.environments
              .where((item) => item.id != environment.id)
              .toList(growable: false)
        : _cubit.state.store.environments
              .map(
                (item) =>
                    item.id == environment.id ? result.environment! : item,
              )
              .toList(growable: false);
    await _cubit.saveEnvironments(environments);
  }

  Future<void> _confirmDelete(RequestEnvironment environment) async {
    final colors = context.appColors;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: colors.modalBarrier,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        ),
        title: const Text('Delete Environment?'),
        content: const Text(
          'Are you sure you would like to delete this environment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: Theme.of(
                dialogContext,
              ).textTheme.labelLarge?.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: Theme.of(
                dialogContext,
              ).textTheme.labelLarge?.copyWith(color: colors.methodDelete),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _cubit.saveEnvironments(
      _cubit.state.store.environments
          .where((item) => item.id != environment.id)
          .toList(growable: false),
    );
  }

  Future<void> _showRowActions(RequestEnvironment environment) async {
    final action = await showModalBottomSheet<_EnvironmentRowAction>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.appColors.surface,
      builder: (actionContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            if (environment.source == RequestEnvironmentSource.local)
              ListTile(
                leading: Icon(
                  CupertinoIcons.pencil,
                  color: actionContext.appColors.iconPrimary,
                ),
                title: const Text('Edit'),
                onTap: () =>
                    Navigator.of(actionContext).pop(_EnvironmentRowAction.edit),
              ),
            ListTile(
              leading: Icon(
                CupertinoIcons.check_mark_circled,
                color: actionContext.appColors.primary,
              ),
              title: const Text('Set Active'),
              onTap: () => Navigator.of(
                actionContext,
              ).pop(_EnvironmentRowAction.setActive),
            ),
            if (environment.source == RequestEnvironmentSource.local) ...[
              ListTile(
                leading: Icon(
                  CupertinoIcons.square_arrow_up,
                  color: actionContext.appColors.iconPrimary,
                ),
                title: const Text('Export...'),
                onTap: () => Navigator.of(
                  actionContext,
                ).pop(_EnvironmentRowAction.export),
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.share,
                  color: actionContext.appColors.iconPrimary,
                ),
                title: const Text('Share...'),
                onTap: () => Navigator.of(
                  actionContext,
                ).pop(_EnvironmentRowAction.share),
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.trash,
                  color: actionContext.appColors.methodDelete,
                ),
                title: Text(
                  'Delete',
                  style: Theme.of(actionContext).textTheme.bodyLarge?.copyWith(
                    color: actionContext.appColors.methodDelete,
                  ),
                ),
                onTap: () => Navigator.of(
                  actionContext,
                ).pop(_EnvironmentRowAction.delete),
              ),
            ],
          ],
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _EnvironmentRowAction.edit:
        await _editEnvironment(environment);
      case _EnvironmentRowAction.setActive:
        await _selectEnvironment(environment);
      case _EnvironmentRowAction.export:
        _showMessage('Export is not implemented yet.');
      case _EnvironmentRowAction.share:
        _showMessage('Share is not implemented yet.');
      case _EnvironmentRowAction.delete:
        await _confirmDelete(environment);
    }
  }

  Future<void> _importFile() async {
    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null || !mounted) {
      return;
    }

    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      _showMessage('Invalid environment file.');
      return;
    }

    final fileName = file.name.endsWith('.json')
        ? file.name.substring(0, file.name.length - 5)
        : file.name;
    final result = EnvironmentImportParser.parse(
      content,
      environmentId: _newEnvironmentId(),
      fallbackName: fileName,
    );

    if (!mounted) {
      return;
    }

    final environment = result.environment;
    if (environment == null) {
      _showMessage(result.errorMessage ?? 'Invalid environment file.');
      return;
    }

    final uniqueName = EnvironmentImportParser.resolveUniqueName(
      environment.name,
      _cubit.state.store.environments.map((item) => item.displayName),
    );
    await _cubit.saveEnvironments([
      ..._cubit.state.store.environments,
      environment.copyWith(name: uniqueName),
    ]);

    if (mounted) {
      setState(() => _source = RequestEnvironmentSource.local);
    }
  }

  Future<void> _importFromPostman() async {
    String? apiKey;
    try {
      apiKey = await getIt<LoadPostmanApiKeyUseCase>()();
    } catch (_) {
      apiKey = null;
    }

    if (!mounted) {
      return;
    }

    _showMessage(
      apiKey == null || apiKey.trim().isEmpty
          ? 'Postman integration is not connected.'
          : 'Importing environments from Postman is not supported yet. '
                'Import a Postman environment JSON file instead.',
    );
  }

  Future<void> _selectEnvironment(RequestEnvironment environment) =>
      _cubit.selectEnvironment(environment.id);

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EnvironmentMenuCubit, EnvironmentMenuState>(
        bloc: _cubit,
        builder: (context, state) {
          final environments = _source == RequestEnvironmentSource.local
              ? state.localEnvironments
              : state.postmanEnvironments;

          return Column(
            key: const ValueKey<String>(AppWidgetKeys.manageEnvironmentsSheet),
            children: [
              _TopBar(
                source: _source,
                onClose: widget.onClose,
                onSourceChanged: (source) => setState(() => _source = source),
                onPlusAction: _handlePlusAction,
                onDeactivate: state.store.selectedEnvironmentId.isEmpty
                    ? null
                    : _cubit.deactivateEnvironment,
              ),
              Expanded(
                child: environments.isEmpty
                    ? _EnvironmentEmptyState(source: _source)
                    : ListView(
                        children: [
                          for (final environment in environments)
                            _EnvironmentListItem(
                              environment: environment,
                              isActive:
                                  environment.id ==
                                  state.store.selectedEnvironmentId,
                              onTap: () => _selectEnvironment(environment),
                              onLongPress: () => _showRowActions(environment),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.source,
    required this.onSourceChanged,
    required this.onPlusAction,
    this.onClose,
    this.onDeactivate,
  });

  final RequestEnvironmentSource source;
  final VoidCallback? onClose;
  final ValueChanged<RequestEnvironmentSource> onSourceChanged;
  final ValueChanged<_ManageEnvironmentsPlusAction> onPlusAction;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        onClose == null ? 0 : AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      child: Row(
        children: [
          if (onClose != null) ...[
            IconButton(
              key: const ValueKey<String>(
                AppWidgetKeys.manageEnvironmentsCloseButton,
              ),
              tooltip: 'Close',
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: colors.background,
                foregroundColor: colors.iconPrimary,
              ),
              icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          Expanded(
            child: Text(
              'Environments',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _SourcePill(source: source, onChanged: onSourceChanged),
          const SizedBox(width: AppSpacing.small),
          _ActionsPill(
            source: source,
            onPlusAction: onPlusAction,
            onDeactivate: onDeactivate,
          ),
        ],
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.source, required this.onChanged});

  final RequestEnvironmentSource source;
  final ValueChanged<RequestEnvironmentSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopupMenuButton<RequestEnvironmentSource>(
      key: const ValueKey<String>(AppWidgetKeys.manageEnvironmentsSourcePill),
      tooltip: 'Environment source',
      color: colors.surface,
      position: PopupMenuPosition.under,
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<RequestEnvironmentSource>(
          value: RequestEnvironmentSource.local,
          child: Text('Local'),
        ),
        const PopupMenuItem<RequestEnvironmentSource>(
          value: RequestEnvironmentSource.postman,
          child: Text('Postman'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.xSmall,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              source == RequestEnvironmentSource.local ? 'Local' : 'Postman',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: AppSpacing.xSmall),
            Icon(
              CupertinoIcons.chevron_down,
              size: AppSpacing.medium,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsPill extends StatelessWidget {
  const _ActionsPill({
    required this.source,
    required this.onPlusAction,
    this.onDeactivate,
  });

  final RequestEnvironmentSource source;
  final ValueChanged<_ManageEnvironmentsPlusAction> onPlusAction;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<void>(
            key: const ValueKey<String>(
              AppWidgetKeys.manageEnvironmentsMoreButton,
            ),
            tooltip: 'More actions',
            icon: const Icon(CupertinoIcons.ellipsis),
            color: colors.surface,
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: onDeactivate != null,
                onTap: onDeactivate,
                child: const Text('Deactivate Environment'),
              ),
            ],
          ),
          PopupMenuButton<_ManageEnvironmentsPlusAction>(
            key: const ValueKey<String>(
              AppWidgetKeys.manageEnvironmentsAddButton,
            ),
            tooltip: 'Add environment',
            icon: const Icon(CupertinoIcons.add),
            color: colors.surface,
            position: PopupMenuPosition.under,
            onSelected: onPlusAction,
            itemBuilder: (context) => [
              if (source == RequestEnvironmentSource.local)
                const PopupMenuItem<_ManageEnvironmentsPlusAction>(
                  value: _ManageEnvironmentsPlusAction.newEnvironment,
                  child: _PlusMenuRow(
                    icon: CupertinoIcons.add,
                    label: 'New Environment',
                  ),
                ),
              const PopupMenuItem<_ManageEnvironmentsPlusAction>(
                value: _ManageEnvironmentsPlusAction.importFile,
                child: _PlusMenuRow(
                  icon: CupertinoIcons.arrow_down_doc,
                  label: 'Import File...',
                ),
              ),
              const PopupMenuItem<_ManageEnvironmentsPlusAction>(
                value: _ManageEnvironmentsPlusAction.importPostman,
                child: _PlusMenuRow(
                  icon: CupertinoIcons.cloud_download,
                  label: 'Import from Postman...',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlusMenuRow extends StatelessWidget {
  const _PlusMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: AppSpacing.large, color: context.appColors.iconPrimary),
      const SizedBox(width: AppSpacing.small),
      Expanded(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

class _EnvironmentEmptyState extends StatelessWidget {
  const _EnvironmentEmptyState({required this.source});

  final RequestEnvironmentSource source;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      key: const ValueKey<String>(AppWidgetKeys.manageEnvironmentsEmptyState),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: colors.textSecondary),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.large),
                ),
              ),
              child: Text(
                'E',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              'No Environments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              source == RequestEnvironmentSource.postman
                  ? 'There are no Postman environments available. '
                        'Please import from Postman.'
                  : 'There are no environments available. '
                        'Please create or import a new one.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentListItem extends StatelessWidget {
  const _EnvironmentListItem({
    required this.environment,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  final RequestEnvironment environment;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final variableCount = environment.variables.length;

    return ListTile(
      key: ValueKey<String>('manage_environments_item_${environment.id}'),
      title: Text(
        environment.displayName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isActive ? colors.primary : colors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ValueCountPill(count: variableCount),
          if (isActive) ...[
            const SizedBox(width: AppSpacing.small),
            Icon(CupertinoIcons.check_mark, color: colors.primary),
          ],
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _ValueCountPill extends StatelessWidget {
  const _ValueCountPill({required this.count});

  final int count;

  /// Shows how many values belong to one environment row.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.background,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      child: Text(
        count == 1 ? '1 value' : '$count values',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    ),
  );
}

class EnvironmentEditorResult {
  const EnvironmentEditorResult({this.environment, this.deleted = false});

  final RequestEnvironment? environment;
  final bool deleted;
}

/// Opens the editor for one environment and returns the saved/deleted outcome.
Future<EnvironmentEditorResult?> showEnvironmentEditorSheet(
  BuildContext context, {
  required RequestEnvironment environment,
  bool allowDelete = false,
}) => showModalBottomSheet<EnvironmentEditorResult>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: context.appColors.surface,
  builder: (context) => _EnvironmentEditorSheet(
    environment: environment,
    allowDelete: allowDelete,
  ),
);

class _EnvironmentEditorSheet extends StatefulWidget {
  const _EnvironmentEditorSheet({
    required this.environment,
    required this.allowDelete,
  });

  final RequestEnvironment environment;
  final bool allowDelete;

  @override
  State<_EnvironmentEditorSheet> createState() =>
      _EnvironmentEditorSheetState();
}

class _EnvironmentEditorSheetState extends State<_EnvironmentEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.environment.name,
  );
  late final List<VariableRowData> _rows = widget.environment.variables
      .map(
        (variable) => VariableRowData(
          variable: variable,
          scope: RequestVariableScope.environment,
        ),
      )
      .toList();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_rows.isEmpty) {
      _rows.add(VariableRowData(scope: RequestVariableScope.environment));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _save() {
    final error = EnvironmentDraftValidator.validate(
      name: _nameController.text,
      rows: _rows
          .map(
            (row) =>
                (key: row.keyController.text, value: row.valueController.text),
          )
          .toList(growable: false),
    );
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    final variables = _rows
        .map((row) => row.toVariable())
        .where((variable) => variable.hasKey)
        .toList(growable: false);

    Navigator.of(context).pop(
      EnvironmentEditorResult(
        environment: widget.environment.copyWith(
          name: _nameController.text.trim(),
          variables: variables,
        ),
      ),
    );
  }

  void _delete() {
    Navigator.of(context).pop(const EnvironmentEditorResult(deleted: true));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.large,
        right: AppSpacing.large,
        top: AppSpacing.large,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.large,
      ),
      child: SingleChildScrollView(
        key: const ValueKey<String>(AppWidgetKeys.environmentEditorSheet),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _EnvironmentEditorHeader(
              title: widget.allowDelete
                  ? 'Edit Environment'
                  : 'New Environment',
              onClose: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              key: const ValueKey<String>(
                AppWidgetKeys.environmentEditorNameField,
              ),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Environment name',
                hintText: 'Enter Environment Name',
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text('VALUES', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.small),
            VariableRowsEditor(
              rows: _rows,
              onAddRow: () => setState(
                () => _rows.add(
                  VariableRowData(scope: RequestVariableScope.environment),
                ),
              ),
              onRemoveRow: (index) =>
                  setState(() => _rows.removeAt(index).dispose()),
              onChanged: () => setState(() {}),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appColors.methodDelete,
                ),
              ),
            ],
            if (widget.allowDelete) ...[
              const SizedBox(height: AppSpacing.small),
              TextButton(
                key: const ValueKey<String>(
                  AppWidgetKeys.environmentEditorDeleteButton,
                ),
                onPressed: _delete,
                child: Text(
                  'Delete Environment',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.appColors.methodDelete,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _EnvironmentEditorHeader extends StatelessWidget {
  const _EnvironmentEditorHeader({
    required this.title,
    required this.onClose,
    required this.onSave,
  });

  final VoidCallback onClose;
  final VoidCallback onSave;
  final String title;

  /// Builds the editor toolbar with close, centered title, and save check.
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(onPressed: onClose, icon: const Icon(CupertinoIcons.xmark)),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        key: const ValueKey<String>(AppWidgetKeys.environmentEditorSaveButton),
        onPressed: onSave,
        color: context.appColors.primary,
        icon: const Icon(CupertinoIcons.check_mark),
      ),
    ],
  );
}
