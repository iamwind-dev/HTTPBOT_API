import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/entities/requests_method.dart';
import '../bloc/request_send_bloc.dart';
import '../bloc/request_send_event.dart';
import '../bloc/request_send_state.dart';
import '../cubit/request_editor_cubit.dart';
import '../cubit/request_editor_state.dart';
import '../models/request_editor_response_badge_data.dart';
import '../models/request_editor_result.dart';
import 'request_modal_sheet.dart';
import 'request_response_sheet.dart';

/// Presents the request editor as a full-screen sheet backed by a real request draft.
Future<RequestEditorResult?> showRequestEditorSheet(
  BuildContext context, {
  required String title,
  required RequestDraft initialDraft,
  required RequestVariableStore variableStore,
  Future<void> Function(RequestEditorResult result)? onDraftChanged,
  Future<void> Function()? onDraftDiscarded,
}) async {
  final editorCubit = RequestEditorCubit(
    title: title,
    initialDraft: initialDraft,
  );
  final requestSendBloc = getIt<RequestSendBloc>();
  Timer? autosaveTimer;
  RequestEditorState? pendingAutosaveState;

  Future<void> saveEditorState(RequestEditorState state) async {
    await onDraftChanged?.call(
      RequestEditorResult(title: state.title, draft: state.draft),
    );
  }

  final editorSubscription = editorCubit.stream.listen((state) {
    if (onDraftChanged == null) {
      return;
    }

    pendingAutosaveState = state;
    autosaveTimer?.cancel();
    autosaveTimer = Timer(const Duration(milliseconds: 450), () {
      final autosaveState = pendingAutosaveState;
      if (autosaveState != null) {
        unawaited(saveEditorState(autosaveState));
      }
    });
  });

  try {
    final result = await showRequestModalSheet<RequestEditorResult?>(
      context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<RequestEditorCubit>.value(value: editorCubit),
          BlocProvider<RequestSendBloc>.value(value: requestSendBloc),
        ],
        child: _RequestEditorSheet(
          initialTitle: title,
          initialDraft: initialDraft,
          variableStore: variableStore,
          onDraftDiscarded: onDraftDiscarded,
        ),
      ),
    );

    autosaveTimer?.cancel();

    return result;
  } finally {
    autosaveTimer?.cancel();
    await editorSubscription.cancel();
    await editorCubit.close();
    await requestSendBloc.close();
  }
}

class _RequestEditorSheet extends StatefulWidget {
  const _RequestEditorSheet({
    required this.initialTitle,
    required this.initialDraft,
    required this.variableStore,
    this.onDraftDiscarded,
  });

  final String initialTitle;
  final RequestDraft initialDraft;
  final RequestVariableStore variableStore;
  final Future<void> Function()? onDraftDiscarded;

  @override
  State<_RequestEditorSheet> createState() => _RequestEditorSheetState();
}

class _RequestEditorSheetState extends State<_RequestEditorSheet> {
  RequestEditorResponseBadgeData? _lastResponseBadge;
  bool _isClosing = false;

  /// Lets the method badge in the header update the request method in place.
  Future<void> _openMethodPicker(HttpMethod currentMethod) async {
    final selectedMethod = await showModalBottomSheet<HttpMethod>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.appColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final method in HttpMethod.values)
              ListTile(
                title: Text(method.wireName),
                trailing: method == currentMethod
                    ? Icon(
                        CupertinoIcons.check_mark,
                        color: context.appColors.methodColor(method.label),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(method),
              ),
          ],
        ),
      ),
    );

    if (!mounted || selectedMethod == null) {
      return;
    }

    context.read<RequestEditorCubit>().updateMethod(selectedMethod);
  }

  /// Opens the temporary response viewer and stores the latest summary when it closes.
  Future<void> _openResponseSheet() async {
    final editorCubit = context.read<RequestEditorCubit>();
    final requestSendBloc = context.read<RequestSendBloc>();

    setState(() {
      _lastResponseBadge = null;
    });

    requestSendBloc.add(const RequestSendResetRequested());
    requestSendBloc.add(
      RequestSendRequested(
        draft: editorCubit.state.draft,
        variableStore: widget.variableStore,
      ),
    );

    final badgeData = await showRequestResponseSheet(
      context,
      requestEditorCubit: editorCubit,
      requestSendBloc: requestSendBloc,
      variableStore: widget.variableStore,
    );

    if (!mounted || badgeData == null) {
      return;
    }

    setState(() {
      _lastResponseBadge = badgeData;
    });
  }

  bool _hasUnsavedChanges(RequestEditorState state) =>
      state.title != widget.initialTitle || state.draft != widget.initialDraft;

  Future<void> _handleMoreAction(_RequestEditorMoreAction action) async {
    switch (action) {
      case _RequestEditorMoreAction.globalVariables:
        await _openGlobalVariables();
      case _RequestEditorMoreAction.manageEnvironment:
        await _openManageEnvironment();
      case _RequestEditorMoreAction.useGraphQl:
        _useGraphQlMode();
      case _RequestEditorMoreAction.viewCurl:
        await _viewCurl();
      case _RequestEditorMoreAction.exportHar:
        await _exportHar();
      case _RequestEditorMoreAction.cookies:
        await _openCookies();
      case _RequestEditorMoreAction.tests:
        await _openTests();
      case _RequestEditorMoreAction.settings:
        await _openRequestSettings();
    }
  }

  Future<void> _openGlobalVariables() async {
    // TODO: Open the global variables editor.
  }

  Future<void> _openManageEnvironment() async {
    // TODO: Open the environment management screen.
  }

  void _useGraphQlMode() {
    context.read<RequestEditorCubit>().updateBodyType(RequestBodyType.graphql);
  }

  Future<void> _viewCurl() async {
    // TODO: Generate and present the current request as a cURL command.
  }

  Future<void> _exportHar() async {
    // TODO: Export the current request draft as a HAR entry/file.
  }

  Future<void> _openCookies() async {
    // TODO: Open request cookie management for the current request.
  }

  Future<void> _openTests() async {
    // TODO: Open request test scripts for the current request.
  }

  Future<void> _openRequestSettings() async {
    // TODO: Open request-specific settings for the current request.
  }

  Future<bool> _confirmCloseIfNeeded(RequestEditorState state) async {
    if (_isClosing) {
      return false;
    }

    if (!_hasUnsavedChanges(state)) {
      _closeWithoutSaving();
      return true;
    }

    final action = await showDialog<_UnsavedChangesAction>(
      context: context,
      barrierColor: context.appColors.modalBarrier,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        ),
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save this request before closing?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChangesAction.cancel),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChangesAction.discard),
            child: Text(
              'Discard',
              style: TextStyle(color: context.appColors.methodDelete),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChangesAction.save),
            child: Text(
              'Save',
              style: TextStyle(
                color: context.appColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) {
      return false;
    }

    switch (action) {
      case _UnsavedChangesAction.save:
        _closeWithSave(state);
        return true;
      case _UnsavedChangesAction.discard:
        await widget.onDraftDiscarded?.call();
        if (mounted) {
          _closeWithoutSaving();
        }
        return true;
      case _UnsavedChangesAction.cancel:
      case null:
        return false;
    }
  }

  void _closeWithSave(RequestEditorState state) {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    Navigator.of(
      context,
    ).pop(RequestEditorResult(title: state.title, draft: state.draft));
  }

  void _closeWithoutSaving() {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    Navigator.of(context).pop();
  }

  /// Builds the request editor shell while binding the visible controls to cubit state.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsEditorSheet),
    child: BlocBuilder<RequestEditorCubit, RequestEditorState>(
      builder: (context, state) {
        final draft = state.draft;
        final responseBadge = _lastResponseBadge;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || _isClosing) {
              return;
            }

            unawaited(_confirmCloseIfNeeded(state));
          },
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.small),
              const _SheetHandle(),
              _EditorHeader(
                title: state.title,
                method: draft.method.label,
                onMethodPressed: () => _openMethodPicker(draft.method),
                onMoreActionSelected: _handleMoreAction,
                onClose: () => _confirmCloseIfNeeded(state),
              ),
              const SizedBox(height: AppSpacing.small),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.large,
                    0,
                    AppSpacing.large,
                    AppSpacing.large,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RequestBasicsSection(title: state.title, draft: draft),
                      const SizedBox(height: AppSpacing.large),
                      _KeyValueSection(
                        title: AppStrings.requestEditorQueryParams,
                        sectionId: 'query',
                        items: draft.queryParameters,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      _KeyValueSection(
                        title: AppStrings.requestEditorHeaders,
                        sectionId: 'headers',
                        items: draft.headers,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      _BodySection(draft: draft),
                      const SizedBox(height: AppSpacing.large),
                      _AuthSection(auth: draft.auth),
                      const SizedBox(height: AppSpacing.large),
                      _OptionsSection(draft: draft),
                      const SizedBox(height: AppSpacing.xxxLarge),
                    ],
                  ),
                ),
              ),
              BlocBuilder<RequestSendBloc, RequestSendState>(
                builder: (context, sendState) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.large,
                    0,
                    AppSpacing.large,
                    AppSpacing.large,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: responseBadge == null
                              ? const SizedBox.shrink()
                              : _ResponseBadge(data: responseBadge),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      _SendButton(
                        onPressed: _openResponseSheet,
                        isLoading:
                            sendState.status == RequestSendStatus.sending,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

enum _UnsavedChangesAction { save, discard, cancel }

enum _RequestEditorMoreAction {
  globalVariables,
  manageEnvironment,
  useGraphQl,
  viewCurl,
  exportHar,
  cookies,
  tests,
  settings,
}

extension _RequestEditorMoreActionLabel on _RequestEditorMoreAction {
  String get label => switch (this) {
    _RequestEditorMoreAction.globalVariables => 'Global Variables',
    _RequestEditorMoreAction.manageEnvironment => 'Manage Environment',
    _RequestEditorMoreAction.useGraphQl => 'Use GraphQL',
    _RequestEditorMoreAction.viewCurl => 'View curl',
    _RequestEditorMoreAction.exportHar => 'Export as HAR',
    _RequestEditorMoreAction.cookies => 'Cookies',
    _RequestEditorMoreAction.tests => 'Tests',
    _RequestEditorMoreAction.settings => 'Settings',
  };
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  /// Draws the compact drag handle shown at the top of the sheet.
  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.xxLarge,
    height: AppSpacing.xxSmall,
    decoration: BoxDecoration(
      color: context.appColors.sheetHandle,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
    ),
  );
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.title,
    required this.method,
    required this.onMethodPressed,
    required this.onMoreActionSelected,
    required this.onClose,
  });

  final String title;
  final String method;
  final VoidCallback onMethodPressed;
  final ValueChanged<_RequestEditorMoreAction> onMoreActionSelected;
  final VoidCallback onClose;

  /// Builds the editor toolbar with the current request identity and close action.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsEditorCloseButton,
            ),
            tooltip: AppStrings.requestEditorCloseTooltip,
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: colors.background,
              foregroundColor: colors.iconPrimary,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                _MethodBadge(method: method, onPressed: onMethodPressed),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _RequestEditorMoreButton(onSelected: onMoreActionSelected),
        ],
      ),
    );
  }
}

class _RequestEditorMoreButton extends StatelessWidget {
  const _RequestEditorMoreButton({required this.onSelected});

  final ValueChanged<_RequestEditorMoreAction> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_RequestEditorMoreAction>(
    key: const ValueKey<String>(AppWidgetKeys.requestsEditorMoreButton),
    tooltip: 'More request actions',
    icon: const Icon(CupertinoIcons.ellipsis),
    color: context.appColors.surface,
    elevation: 12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    constraints: const BoxConstraints(minWidth: 196),
    position: PopupMenuPosition.under,
    onSelected: onSelected,
    itemBuilder: (context) => [
      PopupMenuItem<_RequestEditorMoreAction>(
        value: _RequestEditorMoreAction.globalVariables,
        child: const _RequestEditorMoreMenuRow(label: 'Global Variables'),
      ),
      PopupMenuItem<_RequestEditorMoreAction>(
        value: _RequestEditorMoreAction.manageEnvironment,
        child: const _RequestEditorMoreMenuRow(label: 'Manage Environment'),
      ),
      for (final action in [
        _RequestEditorMoreAction.useGraphQl,
        _RequestEditorMoreAction.viewCurl,
        _RequestEditorMoreAction.exportHar,
        _RequestEditorMoreAction.cookies,
        _RequestEditorMoreAction.tests,
        _RequestEditorMoreAction.settings,
      ])
        PopupMenuItem<_RequestEditorMoreAction>(
          value: action,
          child: _RequestEditorMoreMenuRow(label: action.label),
        ),
    ],
  );
}

class _RequestEditorMoreMenuRow extends StatelessWidget {
  const _RequestEditorMoreMenuRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: context.appColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method, required this.onPressed});

  final String method;
  final VoidCallback onPressed;

  /// Shows the request method using the shared request-method palette.
  @override
  Widget build(BuildContext context) => Material(
    color: context.appColors.methodColor(method),
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
    child: InkWell(
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.xSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(method, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    ),
  );
}

class _EditorSectionTitle extends StatelessWidget {
  const _EditorSectionTitle({required this.title});

  final String title;

  /// Displays section labels with muted emphasis similar to native iOS forms.
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: context.appColors.textSecondary),
  );
}

class _RequestBasicsSection extends StatelessWidget {
  const _RequestBasicsSection({required this.title, required this.draft});

  final String title;
  final RequestDraft draft;

  /// Builds the method selector and URL editor for the current request draft.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _EditorSectionTitle(title: 'Request Name'),
      const SizedBox(height: AppSpacing.small),
      _EditorTextField(
        fieldKey: AppWidgetKeys.requestsEditorTitleField,
        value: title,
        label: 'Request Name',
        hintText: 'Untitled Request',
        onChanged: context.read<RequestEditorCubit>().updateTitle,
      ),
      const SizedBox(height: AppSpacing.large),
      _EditorTextField(
        fieldKey: AppWidgetKeys.requestsEditorUrlField,
        value: draft.url,
        label: 'URL',
        hintText: 'https://api.example.com/users/{{user_id}}',
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        onChanged: context.read<RequestEditorCubit>().updateUrl,
      ),
    ],
  );
}

class _KeyValueSection extends StatelessWidget {
  const _KeyValueSection({
    required this.title,
    required this.sectionId,
    required this.items,
    this.onItemsChanged,
  });

  final String title;
  final String sectionId;
  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>>? onItemsChanged;

  /// Builds an editable key-value collection for query params, headers, and body fields.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _EditorSectionTitle(title: title),
      const SizedBox(height: AppSpacing.small),
      _KeyValueCard(
        sectionId: sectionId,
        items: items,
        onItemChanged: (index, item) => _replace(context, index, item),
        onItemDeleted:
            sectionId == 'query' ? (index) => _remove(context, index) : null,
        onAddPressed: () => _appendEmptyItem(context),
      ),
    ],
  );

  /// Adds a new empty row to the key-value collection.
  void _appendEmptyItem(BuildContext context) {
    final updatedItems = [...items, const KeyValueItem(key: '', value: '')];
    _commit(context, updatedItems);
  }

  /// Replaces one row after the user edits a key-value item.
  void _replace(BuildContext context, int index, KeyValueItem item) {
    final updatedItems = [...items];
    updatedItems[index] = item;
    _commit(context, updatedItems);
  }

  /// Removes one row after the user confirms a delete action from the inline editor.
  void _remove(BuildContext context, int index) {
    final updatedItems = [...items]..removeAt(index);
    _commit(context, updatedItems);
  }

  /// Writes the latest key-value collection back into the editor cubit.
  void _commit(BuildContext context, List<KeyValueItem> updatedItems) {
    final sectionItemsChanged = onItemsChanged;

    if (sectionItemsChanged != null) {
      sectionItemsChanged(updatedItems);
      return;
    }

    final editorCubit = context.read<RequestEditorCubit>();

    if (sectionId == 'query') {
      editorCubit.updateQueryParameters(updatedItems);
      return;
    }

    editorCubit.updateHeaders(updatedItems);
  }
}

class _KeyValueCard extends StatelessWidget {
  const _KeyValueCard({
    required this.sectionId,
    required this.items,
    required this.onItemChanged,
    this.onItemDeleted,
    required this.onAddPressed,
  });

  final String sectionId;
  final List<KeyValueItem> items;
  final void Function(int index, KeyValueItem item) onItemChanged;
  final ValueChanged<int>? onItemDeleted;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final rowCount = items.length + 1;

    return DecoratedBox(
      decoration: _buildCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
        child: Column(
          children: [
            for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              if (rowIndex < items.length)
                _KeyValueRow(
                  sectionId: sectionId,
                  index: rowIndex,
                  item: items[rowIndex],
                  onChanged: (item) => onItemChanged(rowIndex, item),
                  onDelete:
                      onItemDeleted == null
                          ? null
                          : () => onItemDeleted!(rowIndex),
                )
              else
                _AddKeyValueRow(sectionId: sectionId, onPressed: onAddPressed),
              if (rowIndex < rowCount - 1) const _KeyValueDivider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.sectionId,
    required this.index,
    required this.item,
    required this.onChanged,
    this.onDelete,
  });

  final String sectionId;
  final int index;
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onChanged;
  final VoidCallback? onDelete;

  /// Returns true when the row is the Authorization header generated by the auth editor.
  bool get _isSystemGeneratedAuthHeader =>
      sectionId == 'headers' && item.isSystemGeneratedAuthorizationHeader;

  /// Returns the badge label for auth-generated Authorization rows.
  String get _systemGeneratedAuthLabel =>
      item.systemGeneratedAuthorizationLabel ?? 'Auth';

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress:
        onDelete == null || _isSystemGeneratedAuthHeader
            ? null
            : () => _showDeleteActionSheet(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.small,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxxLarge),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _EnabledIndicator(
              key: ValueKey<String>(
                AppWidgetKeys.requestsEditorKeyValueToggle(sectionId, index),
              ),
              isEnabled: item.isEnabled,
              onPressed:
                  _isSystemGeneratedAuthHeader
                      ? null
                      : () =>
                          onChanged(item.copyWith(isEnabled: !item.isEnabled)),
            ),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: _InlineKeyValueTextField(
                fieldKey: AppWidgetKeys.requestsEditorKeyValueKeyField(
                  sectionId,
                  index,
                ),
                value: item.key,
                hintText: 'Key',
                readOnly: _isSystemGeneratedAuthHeader,
                onChanged:
                    (value) => onChanged(item.copyWith(key: value)),
              ),
            ),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: _InlineKeyValueTextField(
                fieldKey: AppWidgetKeys.requestsEditorKeyValueValueField(
                  sectionId,
                  index,
                ),
                value: item.value,
                hintText: 'Value',
                textAlign: TextAlign.end,
                readOnly: _isSystemGeneratedAuthHeader,
                onChanged:
                    (value) => onChanged(item.copyWith(value: value)),
              ),
            ),
            if (_isSystemGeneratedAuthHeader) ...[
              const SizedBox(width: AppSpacing.medium),
              _SystemGeneratedBadge(label: _systemGeneratedAuthLabel),
            ],
          ],
        ),
      ),
    ),
  );

  /// Shows the minimal query-param row menu and keeps only the delete action.
  Future<void> _showDeleteActionSheet(BuildContext context) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          key: ValueKey<String>(
            AppWidgetKeys.requestsEditorKeyValueRemoveButton(sectionId, index),
          ),
          leading: const Icon(CupertinoIcons.delete),
          title: const Text('Delete'),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (shouldDelete == true) {
      onDelete?.call();
    }
  }
}

class _EnabledIndicator extends StatelessWidget {
  const _EnabledIndicator({
    super.key,
    required this.isEnabled,
    this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: AppSpacing.large,
        height: AppSpacing.large,
        decoration: BoxDecoration(
          color: isEnabled ? colors.methodGet : colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled ? colors.methodGet : colors.border,
            width: 1.5,
          ),
        ),
        child: isEnabled
            ? Icon(
                CupertinoIcons.check_mark,
                color: colors.textOnPrimary,
                size: AppSpacing.small,
              )
            : null,
      ),
    );
  }
}

class _InlineKeyValueTextField extends StatefulWidget {
  const _InlineKeyValueTextField({
    required this.fieldKey,
    required this.value,
    required this.hintText,
    required this.onChanged,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
  });

  final String fieldKey;
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final bool readOnly;

  @override
  State<_InlineKeyValueTextField> createState() =>
      _InlineKeyValueTextFieldState();
}

class _InlineKeyValueTextFieldState extends State<_InlineKeyValueTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _InlineKeyValueTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return TextFormField(
      key: ValueKey<String>(widget.fieldKey),
      controller: _controller,
      onChanged: widget.readOnly ? null : widget.onChanged,
      readOnly: widget.readOnly,
      textAlign: widget.textAlign,
      style: textStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.appColors.surface,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hintText,
        hintStyle: textStyle?.copyWith(color: context.appColors.textSecondary),
      ),
    );
  }
}

class _SystemGeneratedBadge extends StatelessWidget {
  const _SystemGeneratedBadge({required this.label});

  final String label;

  /// Marks a row as editor-generated without changing the surrounding card layout.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AddKeyValueRow extends StatelessWidget {
  const _AddKeyValueRow({required this.sectionId, required this.onPressed});

  final String sectionId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          AppWidgetKeys.requestsEditorSectionAddButton(sectionId),
        ),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.large,
                height: AppSpacing.large,
                decoration: BoxDecoration(
                  color: colors.methodGet,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.add,
                  color: colors.textOnPrimary,
                  size: AppSpacing.small,
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Text(
                AppStrings.requestEditorAdd,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValueDivider extends StatelessWidget {
  const _KeyValueDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: AppSpacing.xxxLarge + AppSpacing.xLarge,
      right: AppSpacing.large,
    ),
    child: Divider(height: 1, thickness: 1, color: context.appColors.divider),
  );
}

class _BodySection extends StatelessWidget {
  const _BodySection({required this.draft});

  final RequestDraft draft;

  /// Builds the body-mode selector and the inputs for the active body type.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();
    final body = draft.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorSectionTitle(title: AppStrings.requestEditorBody),
        const SizedBox(height: AppSpacing.small),
        if (!draft.method.supportsRequestBody) ...[
          const SizedBox(height: AppSpacing.small),
        ],
        _BodyModeCard(
          body: body,
          onTypeChanged: editorCubit.updateBodyType,
          onUrlEncodedChanged: editorCubit.updateUrlEncodedBodyItems,
          onFormDataChanged: editorCubit.updateFormDataBodyItems,
          onRawChanged: editorCubit.updateRawBody,
          onGraphQlChanged: editorCubit.updateGraphQlBody,
        ),
      ],
    );
  }
}

class _BodyModeCard extends StatelessWidget {
  const _BodyModeCard({
    required this.body,
    required this.onTypeChanged,
    required this.onUrlEncodedChanged,
    required this.onFormDataChanged,
    required this.onRawChanged,
    required this.onGraphQlChanged,
  });

  final RequestBodyDraft body;
  final ValueChanged<RequestBodyType> onTypeChanged;
  final ValueChanged<List<KeyValueItem>> onUrlEncodedChanged;
  final ValueChanged<List<KeyValueItem>> onFormDataChanged;
  final ValueChanged<RawBodyDraft> onRawChanged;
  final ValueChanged<GraphQlBodyDraft> onGraphQlChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Column(
        children: [
          _BodyTypeRow(
            value: body.type,
            onChanged: onTypeChanged,
          ),
          ...switch (body.type) {
            RequestBodyType.none => const <Widget>[],
            RequestBodyType.xWwwFormUrlEncoded => <Widget>[
              const _KeyValueDivider(),
              _BodyUrlEncodedList(
                items: body.urlEncoded,
                onChanged: onUrlEncodedChanged,
              ),
            ],
            RequestBodyType.formData => <Widget>[
              const _KeyValueDivider(),
              _BodyFormDataList(
                items: body.formData,
                onChanged: onFormDataChanged,
              ),
            ],
            RequestBodyType.raw => <Widget>[
              const _KeyValueDivider(),
              _BodyActionRow(
                fieldKey: AppWidgetKeys.requestsEditorRawBodyAction,
                label: 'Update Body',
                value: _rawBodySummary(body.raw),
                onTap: () => _openRawBodyEditor(context),
              ),
            ],
            RequestBodyType.graphql => <Widget>[
              const _KeyValueDivider(),
              _BodyActionRow(
                fieldKey: AppWidgetKeys.requestsEditorGraphQlQueryField,
                label: 'Query',
                value: _graphQlSummary(body.graphQl.query),
                onTap: () => _openGraphQlEditor(
                  context,
                  label: 'Query',
                  currentValue: body.graphQl.query,
                  onSaved: (value) => onGraphQlChanged(
                    body.graphQl.copyWith(query: value),
                  ),
                ),
              ),
              const _KeyValueDivider(),
              _BodyActionRow(
                fieldKey: AppWidgetKeys.requestsEditorGraphQlVariablesField,
                label: 'Variables',
                value: _graphQlSummary(body.graphQl.variables),
                onTap: () => _openGraphQlEditor(
                  context,
                  label: 'Variables',
                  currentValue: body.graphQl.variables,
                  onSaved: (value) => onGraphQlChanged(
                    body.graphQl.copyWith(variables: value),
                  ),
                ),
              ),
            ],
          },
        ],
      ),
    ),
  );

  /// Opens the raw editor sheet so content and subtype can change outside the compact card.
  Future<void> _openRawBodyEditor(BuildContext context) async {
    final result = await showRequestModalSheet<_RawBodyEditorResult?>(
      context,
      builder: (context) => _RawBodyEditorSheet(initialValue: body.raw),
    );

    if (result == null) {
      return;
    }

    onRawChanged(
      body.raw.copyWith(
        subtype: result.subtype,
        content: result.content,
      ),
    );
  }

  /// Opens the GraphQL text editor sheet for either the query or variables field.
  Future<void> _openGraphQlEditor(
    BuildContext context, {
    required String label,
    required String currentValue,
    required ValueChanged<String> onSaved,
  }) async {
    final result = await showRequestModalSheet<String?>(
      context,
      builder: (context) => _BodyTextEditorSheet(
        title: label,
        fieldKey:
            label == 'Query'
                ? AppWidgetKeys.requestsEditorGraphQlQueryField
                : AppWidgetKeys.requestsEditorGraphQlVariablesField,
        initialValue: currentValue,
        hintText: label == 'Query' ? 'query GetUsers { users { id } }' : '{\n  "id": "1"\n}',
      ),
    );

    if (result == null) {
      return;
    }

    onSaved(result);
  }

  String _rawBodySummary(RawBodyDraft raw) {
    final trimmed = raw.content.trim();
    if (trimmed.isEmpty) {
      return '${raw.subtype.label} • Empty';
    }

    return '${raw.subtype.label} • ${_truncateSingleLine(trimmed)}';
  }

  String _graphQlSummary(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Empty';
    }

    return _truncateSingleLine(trimmed);
  }

  String _truncateSingleLine(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 42) {
      return compact;
    }

    return '${compact.substring(0, 39)}...';
  }
}

class _BodyTypeRow extends StatelessWidget {
  const _BodyTypeRow({
    required this.value,
    required this.onChanged,
  });

  final RequestBodyType value;
  final ValueChanged<RequestBodyType> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.large,
      vertical: AppSpacing.medium,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.requestEditorType,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<RequestBodyType>(
            key: const ValueKey<String>(AppWidgetKeys.requestsEditorBodyModeField),
            value: value,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
            items: RequestBodyType.values
                .map(
                  (type) => DropdownMenuItem<RequestBodyType>(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (type) {
              if (type != null) {
                onChanged(type);
              }
            },
          ),
        ),
      ],
    ),
  );
}

class _BodyActionRow extends StatelessWidget {
  const _BodyActionRow({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String fieldKey;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(fieldKey),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.bodyLarge),
              ),
              const SizedBox(width: AppSpacing.medium),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Icon(
                CupertinoIcons.chevron_forward,
                size: AppSpacing.medium,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyUrlEncodedList extends StatelessWidget {
  const _BodyUrlEncodedList({
    required this.items,
    required this.onChanged,
  });

  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < items.length; index++) ...[
        _BodyUrlEncodedRow(
          index: index,
          item: items[index],
          onChanged: (item) => _replace(index, item),
          onDelete: () => _remove(index),
        ),
        const _KeyValueDivider(),
      ],
      _AddKeyValueRow(
        sectionId: 'body_url_encoded',
        onPressed: () => onChanged([
          ...items,
          const KeyValueItem(key: '', value: ''),
        ]),
      ),
    ],
  );

  void _replace(int index, KeyValueItem item) {
    final updatedItems = [...items];
    updatedItems[index] = item;
    onChanged(updatedItems);
  }

  void _remove(int index) {
    final updatedItems = [...items]..removeAt(index);
    onChanged(updatedItems);
  }
}

class _BodyUrlEncodedRow extends StatelessWidget {
  const _BodyUrlEncodedRow({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => _showDeleteActionSheet(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          _EnabledIndicator(
            key: ValueKey<String>(
              AppWidgetKeys.requestsEditorKeyValueToggle(
                'body_url_encoded',
                index,
              ),
            ),
            isEnabled: item.isEnabled,
            onPressed: () =>
                onChanged(item.copyWith(isEnabled: !item.isEnabled)),
          ),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: _InlineKeyValueTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueKeyField(
                'body_url_encoded',
                index,
              ),
              value: item.key,
              hintText: 'Key',
              onChanged: (value) => onChanged(item.copyWith(key: value)),
            ),
          ),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: _InlineKeyValueTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueValueField(
                'body_url_encoded',
                index,
              ),
              value: item.value,
              hintText: 'Value',
              textAlign: TextAlign.end,
              onChanged: (value) => onChanged(item.copyWith(value: value)),
            ),
          ),
        ],
      ),
    ),
  );

  /// Shows the minimal row menu used for delete-only long-press actions.
  Future<void> _showDeleteActionSheet(BuildContext context) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          key: ValueKey<String>(
            AppWidgetKeys.requestsEditorKeyValueRemoveButton(
              'body_url_encoded',
              index,
            ),
          ),
          leading: const Icon(CupertinoIcons.delete),
          title: const Text('Delete'),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (shouldDelete == true) {
      onDelete();
    }
  }
}

class _BodyFormDataList extends StatelessWidget {
  const _BodyFormDataList({
    required this.items,
    required this.onChanged,
  });

  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < items.length; index++) ...[
        _BodyFormDataRow(
          index: index,
          item: items[index],
          onChanged: (item) => _replace(index, item),
          onDelete: () => _remove(index),
        ),
        const _KeyValueDivider(),
      ],
      _AddKeyValueRow(
        sectionId: 'body_form_data',
        onPressed: () => onChanged([
          ...items,
          const KeyValueItem(key: '', value: ''),
        ]),
      ),
    ],
  );

  void _replace(int index, KeyValueItem item) {
    final updatedItems = [...items];
    updatedItems[index] = item;
    onChanged(updatedItems);
  }

  void _remove(int index) {
    final updatedItems = [...items]..removeAt(index);
    onChanged(updatedItems);
  }
}

class _BodyFormDataRow extends StatelessWidget {
  const _BodyFormDataRow({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => _showDeleteActionSheet(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.small,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _EnabledIndicator(
                key: ValueKey<String>(
                  AppWidgetKeys.requestsEditorKeyValueToggle(
                    'body_form_data',
                    index,
                  ),
                ),
                isEnabled: item.isEnabled,
                onPressed: () =>
                    onChanged(item.copyWith(isEnabled: !item.isEnabled)),
              ),
              const SizedBox(width: AppSpacing.large),
              DropdownButtonHideUnderline(
                child: DropdownButton<KeyValueItemType>(
                  key: ValueKey<String>(
                    AppWidgetKeys.requestsEditorKeyValueOptionField(
                      'body_form_data',
                      index,
                    ),
                  ),
                  value: item.type,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.xxLarge),
                  ),
                  items: KeyValueItemType.values
                      .map(
                        (type) => DropdownMenuItem<KeyValueItemType>(
                          value: type,
                          child: Text(type == KeyValueItemType.text ? 'Text' : 'File'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (type) {
                    if (type == null) {
                      return;
                    }

                    onChanged(item.copyWith(type: type, value: ''));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Expanded(
                child: _InlineKeyValueTextField(
                  fieldKey: AppWidgetKeys.requestsEditorKeyValueKeyField(
                    'body_form_data',
                    index,
                  ),
                  value: item.key,
                  hintText: 'Key',
                  onChanged: (value) => onChanged(item.copyWith(key: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          if (item.type == KeyValueItemType.text)
            _InlineKeyValueTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueValueField(
                'body_form_data',
                index,
              ),
              value: item.value,
              hintText: 'Value',
              onChanged: (value) => onChanged(item.copyWith(value: value)),
            )
          else
            _BodyFileSelectorRow(
              index: index,
              value: item.value,
              onSelected: (value) => onChanged(item.copyWith(value: value)),
            ),
        ],
      ),
    ),
  );

  /// Shows the minimal row menu used for delete-only long-press actions.
  Future<void> _showDeleteActionSheet(BuildContext context) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          key: ValueKey<String>(
            AppWidgetKeys.requestsEditorKeyValueRemoveButton(
              'body_form_data',
              index,
            ),
          ),
          leading: const Icon(CupertinoIcons.delete),
          title: const Text('Delete'),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (shouldDelete == true) {
      onDelete();
    }
  }
}

class _BodyFileSelectorRow extends StatelessWidget {
  const _BodyFileSelectorRow({
    required this.index,
    required this.value,
    required this.onSelected,
  });

  final int index;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          AppWidgetKeys.requestsEditorKeyValueActionButton(
            'body_form_data',
            index,
          ),
        ),
        onTap: () => _selectFilePath(context),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.small,
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.doc, size: AppSpacing.large),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? 'Select File' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: value.trim().isEmpty
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Icon(
                CupertinoIcons.chevron_forward,
                size: AppSpacing.medium,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a lightweight path-entry sheet so file body items can store a selected local file path.
  Future<void> _selectFilePath(BuildContext context) async {
    final result = await showRequestModalSheet<String?>(
      context,
      builder: (context) => _BodyTextEditorSheet(
        title: 'Select File',
        fieldKey: '${AppWidgetKeys.requestsEditorFormDataFileSelector}_$index',
        initialValue: value,
        hintText: 'C:\\\\path\\\\to\\\\file.json',
        expands: false,
        minLines: 1,
        maxLines: 3,
      ),
    );

    if (result != null) {
      onSelected(result);
    }
  }
}

class _RawBodyEditorResult {
  const _RawBodyEditorResult({
    required this.subtype,
    required this.content,
  });

  final RawBodySubtype subtype;
  final String content;
}

class _RawBodyEditorSheet extends StatefulWidget {
  const _RawBodyEditorSheet({required this.initialValue});

  final RawBodyDraft initialValue;

  @override
  State<_RawBodyEditorSheet> createState() => _RawBodyEditorSheetState();
}

class _RawBodyEditorSheetState extends State<_RawBodyEditorSheet> {
  late final TextEditingController _controller;
  late RawBodySubtype _selectedSubtype;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.content);
    _selectedSubtype = widget.initialValue.subtype;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                Text('Raw Body', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    _RawBodyEditorResult(
                      subtype: _selectedSubtype,
                      content: _controller.text,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<RawBodySubtype>(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsEditorRawSubtypeField,
              ),
              initialValue: _selectedSubtype,
              decoration: _buildFieldDecoration(context, label: 'Subtype'),
              items: RawBodySubtype.values
                  .map(
                    (subtype) => DropdownMenuItem<RawBodySubtype>(
                      value: subtype,
                      child: Text(subtype.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (subtype) {
                if (subtype != null) {
                  setState(() {
                    _selectedSubtype = subtype;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: TextFormField(
                key: const ValueKey<String>(
                  AppWidgetKeys.requestsEditorRawBodyEditor,
                ),
                controller: _controller,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: _buildFieldDecoration(
                  context,
                  label: 'Body',
                  hintText: _selectedSubtype == RawBodySubtype.json
                      ? '{\n  "userId": "{{user_id}}"\n}'
                      : 'Enter request body',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BodyTextEditorSheet extends StatefulWidget {
  const _BodyTextEditorSheet({
    required this.title,
    required this.fieldKey,
    required this.initialValue,
    this.hintText,
    this.minLines,
    this.maxLines,
    this.expands = true,
  });

  final String title;
  final String fieldKey;
  final String initialValue;
  final String? hintText;
  final int? minLines;
  final int? maxLines;
  final bool expands;

  @override
  State<_BodyTextEditorSheet> createState() => _BodyTextEditorSheetState();
}

class _BodyTextEditorSheetState extends State<_BodyTextEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: TextFormField(
                key: ValueKey<String>(widget.fieldKey),
                controller: _controller,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                expands: widget.expands,
                textAlignVertical: TextAlignVertical.top,
                decoration: _buildFieldDecoration(
                  context,
                  label: widget.title,
                  hintText: widget.hintText,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AuthSection extends StatelessWidget {
  const _AuthSection({required this.auth});

  final RequestAuthDraft auth;

  /// Builds the auth-mode selector and the visible credential fields.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorSectionTitle(title: AppStrings.requestEditorAuth),
        const SizedBox(height: AppSpacing.small),
        DecoratedBox(
          decoration: _buildCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: _EditorDropdownField<AuthType>(
              fieldKey: AppWidgetKeys.requestsEditorAuthTypeField,
              label: AppStrings.requestEditorAuth,
              value: auth.type,
              items: AuthType.values
                  .map(
                    (type) => DropdownMenuItem<AuthType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (type) {
                if (type != null) {
                  editorCubit.updateAuth(auth.copyWith(type: type));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        switch (auth.type) {
          AuthType.none => const _InfoCard(
            message: 'No authentication will be applied.',
          ),
          AuthType.bearerToken => Column(
            children: [
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField('bearer_token'),
                value: auth.bearerToken.token,
                label: 'Token',
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    bearerToken: BearerTokenAuthDraft(token: value),
                  ),
                ),
              ),
            ],
          ),
          AuthType.basic => Column(
            children: [
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'basic_username',
                ),
                value: auth.basic.username,
                label: 'Username',
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    basic: BasicAuthDraft(
                      username: value,
                      password: auth.basic.password,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'basic_password',
                ),
                value: auth.basic.password,
                label: 'Password',
                obscureText: true,
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    basic: BasicAuthDraft(
                      username: auth.basic.username,
                      password: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _ => const _InfoCard(
            message: 'This auth mode is not supported in the request editor yet.',
          ),
        },
      ],
    );
  }
}

class _OptionsSection extends StatelessWidget {
  const _OptionsSection({required this.draft});

  final RequestDraft draft;

  /// Builds the timeout and SSL verification controls for the current request.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorSectionTitle(title: AppStrings.requestEditorOptions),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorTimeoutField,
          value: draft.timeout.inSeconds.toString(),
          label: AppStrings.requestEditorTimeout,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final timeoutSeconds = int.tryParse(value.trim());

            if (timeoutSeconds != null) {
              editorCubit.updateTimeoutSeconds(timeoutSeconds);
            }
          },
        ),
        const SizedBox(height: AppSpacing.small),
        DecoratedBox(
          decoration: _buildCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.medium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.requestEditorVerifySsl,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch.adaptive(
                  key: const ValueKey<String>(
                    AppWidgetKeys.requestsEditorVerifySslSwitch,
                  ),
                  value: draft.verifySsl,
                  onChanged: editorCubit.updateVerifySsl,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed, this.isLoading = false});

  final VoidCallback onPressed;
  final bool isLoading;

  /// Draws the floating send affordance at the bottom of the editor.
  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey<String>(AppWidgetKeys.requestsEditorSendButton),
    color: context.appColors.methodGet,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    child: InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: AppSpacing.medium,
                height: AppSpacing.medium,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
            ],
            Text(
              AppStrings.requestEditorSend,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResponseBadge extends StatelessWidget {
  const _ResponseBadge({required this.data});

  final RequestEditorResponseBadgeData data;

  /// Shows the latest response summary in the editor footer after a send completes.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey<String>(AppWidgetKeys.requestsEditorResponseBadge),
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.small,
            height: AppSpacing.small,
            decoration: BoxDecoration(
              color: context.appColors.methodPost,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            data.displayLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

class _EditorDropdownField<T> extends StatelessWidget {
  const _EditorDropdownField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String fieldKey;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  /// Renders a dropdown field using the shared editor input styling.
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    key: ValueKey<String>(fieldKey),
    initialValue: value,
    items: items,
    onChanged: onChanged,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    decoration: _buildFieldDecoration(context, label: label),
    icon: const Icon(CupertinoIcons.chevron_down),
  );
}

class _EditorTextField extends StatefulWidget {
  const _EditorTextField({
    required this.fieldKey,
    required this.value,
    required this.label,
    required this.onChanged,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.obscureText = false,
  });

  final String fieldKey;
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final bool obscureText;

  @override
  State<_EditorTextField> createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends State<_EditorTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _EditorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Renders a controlled text field that stays synchronized with immutable cubit state.
  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey<String>(widget.fieldKey),
    controller: _controller,
    onChanged: widget.onChanged,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    obscureText: widget.obscureText,
    decoration: _buildFieldDecoration(
      context,
      label: widget.label,
      hintText: widget.hintText,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  /// Shows passive guidance for modes that do not need active form inputs yet.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    ),
  );
}

/// Returns the shared editor card decoration used by row groups and hint surfaces.
BoxDecoration _buildCardDecoration(BuildContext context) => BoxDecoration(
  color: context.appColors.surface,
  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
);

/// Returns the shared field decoration used by request-editor text fields and dropdowns.
InputDecoration _buildFieldDecoration(
  BuildContext context, {
  required String label,
  String? hintText,
}) => InputDecoration(
  labelText: label,
  hintText: hintText,
  filled: true,
  fillColor: context.appColors.surface,
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.large,
    vertical: AppSpacing.medium,
  ),
  border: OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    borderSide: BorderSide(color: context.appColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    borderSide: BorderSide(color: context.appColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    borderSide: BorderSide(color: context.appColors.primary),
  ),
);
