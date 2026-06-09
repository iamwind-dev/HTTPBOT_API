import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/services/external_uri_launcher.dart';
import '../../../../core/services/oauth2_callback_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/oauth2_token_details_entity.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/helpers/oauth2_authorization_url_builder.dart';
import '../../domain/helpers/oauth2_callback_parser.dart';
import '../../domain/helpers/oauth2_pkce.dart';
import '../../domain/usecases/exchange_oauth2_authorization_code_use_case.dart';
import '../bloc/request_send_bloc.dart';
import '../bloc/request_send_event.dart';
import '../bloc/request_send_state.dart';
import '../cubit/request_editor_cubit.dart';
import '../cubit/request_editor_state.dart';
import '../models/request_editor_response_badge_data.dart';
import '../models/request_editor_result.dart';
import 'api_key_presets.dart';
import 'method_notes/method_header_note.dart';
import 'oauth2_token_details_sheet.dart';
import 'request_modal_sheet.dart';
import 'request_response_sheet.dart';
import 'saved_credentials_sheet.dart';

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

  final Future<void> Function()? onDraftDiscarded;
  final RequestDraft initialDraft;
  final String initialTitle;
  final RequestVariableStore variableStore;

  @override
  State<_RequestEditorSheet> createState() => _RequestEditorSheetState();
}

class _RequestEditorSheetState extends State<_RequestEditorSheet> {
  bool _isClosing = false;
  RequestEditorResponseBadgeData? _lastResponseBadge;

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
                      _AuthSection(
                        auth: draft.auth,
                        queryParameters: draft.queryParameters,
                        headers: draft.headers,
                      ),
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

  final String method;
  final VoidCallback onClose;
  final VoidCallback onMethodPressed;
  final ValueChanged<_RequestEditorMoreAction> onMoreActionSelected;
  final String title;

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
  Widget build(BuildContext context) =>
      PopupMenuButton<_RequestEditorMoreAction>(
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

  final RequestDraft draft;
  final String title;

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
  });

  final List<KeyValueItem> items;
  final String sectionId;
  final String title;

  /// Adds a new empty row to the key-value collection.
  void _appendEmptyItem(BuildContext context) {
    final updatedItems = [...items, const KeyValueItem(key: '', value: '')];
    _commit(context, updatedItems);
  }

  /// Replaces one row after the user edits a key-value item.
  void _replace(BuildContext context, int index, KeyValueItem item) {
    final updatedItems = [...items];
    final existingItem = updatedItems[index];
    updatedItems[index] =
        sectionId == 'query' &&
            (existingItem.isSystemGeneratedApiKeyQueryParameter ||
                existingItem.isSystemGeneratedOAuth2QueryParameter) &&
            (existingItem.key != item.key ||
                existingItem.value != item.value ||
                existingItem.isEnabled != item.isEnabled)
        ? item.copyWith(description: '')
        : item;
    _commit(context, updatedItems);
  }

  /// Removes one row after the user confirms a delete action from the inline editor.
  void _remove(BuildContext context, int index) {
    final updatedItems = [...items]..removeAt(index);
    _commit(context, updatedItems);
  }

  /// Writes the latest key-value collection back into the editor cubit.
  void _commit(BuildContext context, List<KeyValueItem> updatedItems) {
    final editorCubit = context.read<RequestEditorCubit>();

    if (sectionId == 'query') {
      editorCubit.updateQueryParameters(updatedItems);
      return;
    }

    editorCubit.updateHeaders(updatedItems);
  }

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
        onItemDeleted: sectionId == 'query' || sectionId == 'headers'
            ? (index) => _remove(context, index)
            : null,
        onAddPressed: () => _appendEmptyItem(context),
      ),
      if (sectionId == 'headers')
        MethodHeaderNote(
          method: context.read<RequestEditorCubit>().state.draft.method,
          body: context.read<RequestEditorCubit>().state.draft.body,
          headers: items,
        ),
    ],
  );
}

class _KeyValueCard extends StatelessWidget {
  const _KeyValueCard({
    required this.sectionId,
    required this.items,
    required this.onItemChanged,
    this.onItemDeleted,
    required this.onAddPressed,
  });

  final List<KeyValueItem> items;
  final VoidCallback onAddPressed;
  final void Function(int index, KeyValueItem item) onItemChanged;
  final ValueChanged<int>? onItemDeleted;
  final String sectionId;

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
                  onDelete: onItemDeleted == null
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

  final int index;
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onChanged;
  final VoidCallback? onDelete;
  final String sectionId;

  /// Returns true when the row is managed by auth automation and should keep its structure.
  bool get _locksSystemManagedHeader =>
      sectionId == 'headers' &&
      (item.isSystemGeneratedAuthorizationHeader ||
          item.isSystemGeneratedAwsHeader);

  /// Returns the badge label for supported system-generated header rows.
  String? get _systemGeneratedHeaderLabel =>
      sectionId == 'headers' ? item.systemGeneratedHeaderLabel : null;

  /// Returns true when this row should expose the dedicated long-press action menu.
  bool get _supportsLongPressActionMenu =>
      sectionId == 'query' || sectionId == 'headers';

  /// Shows the long-press menu for one editable row and routes actions to edit or delete flows.
  Future<void> _showKeyValueActionSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_KeyValueRowAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.xxLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.modalBarrier.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: AppSpacing.large,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _KeyValueActionTile(
                    action: _KeyValueRowAction.edit,
                    rowKey: ValueKey<String>(
                      AppWidgetKeys.requestsEditorKeyValueActionButton(
                        sectionId,
                        index,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_KeyValueRowAction.edit),
                  ),
                  const _KeyValueDivider(),
                  _KeyValueActionTile(
                    action: _KeyValueRowAction.delete,
                    rowKey: ValueKey<String>(
                      AppWidgetKeys.requestsEditorKeyValueRemoveButton(
                        sectionId,
                        index,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_KeyValueRowAction.delete),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    switch (action) {
      case _KeyValueRowAction.edit:
        await _showEditSheet(context);
      case _KeyValueRowAction.delete:
        onDelete?.call();
      case null:
        return;
    }
  }

  /// Opens a focused editor sheet for the selected key-value row and saves the updated pair.
  Future<void> _showEditSheet(BuildContext context) async {
    final result = await showRequestModalSheet<_KeyValueEditorResult?>(
      context,
      builder: (context) => _KeyValueEditorSheet(
        title: sectionId == 'headers' ? 'Edit Header' : 'Edit Query Param',
        sectionId: sectionId,
        index: index,
        initialItem: item,
        valueLabel: 'Value',
      ),
    );

    if (result == null) {
      return;
    }

    onChanged(item.copyWith(key: result.key, value: result.value));
  }

  /// Builds one inline key-value row and exposes a dedicated action menu on long press.
  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress:
        !_supportsLongPressActionMenu ||
            onDelete == null ||
            _locksSystemManagedHeader
        ? null
        : () => _showKeyValueActionSheet(context),
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
              onPressed: _locksSystemManagedHeader
                  ? null
                  : () => onChanged(item.copyWith(isEnabled: !item.isEnabled)),
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
                onChanged: (value) => onChanged(item.copyWith(key: value)),
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
                onChanged: (value) => onChanged(item.copyWith(value: value)),
              ),
            ),
            if (_systemGeneratedHeaderLabel != null) ...[
              const SizedBox(width: AppSpacing.medium),
              _SystemGeneratedBadge(label: _systemGeneratedHeaderLabel!),
            ],
          ],
        ),
      ),
    ),
  );
}

enum _KeyValueRowAction { edit, delete }

extension _KeyValueRowActionPresentation on _KeyValueRowAction {
  /// Returns the visible label for one key-value action row.
  String get label => switch (this) {
    _KeyValueRowAction.edit => 'Edit',
    _KeyValueRowAction.delete => 'Delete',
  };

  /// Returns the action icon used by the long-press menu.
  IconData get icon => switch (this) {
    _KeyValueRowAction.edit => CupertinoIcons.pencil,
    _KeyValueRowAction.delete => CupertinoIcons.delete,
  };
}

class _KeyValueActionTile extends StatelessWidget {
  const _KeyValueActionTile({
    required this.action,
    required this.rowKey,
    required this.onTap,
  });

  final _KeyValueRowAction action;
  final VoidCallback onTap;
  final Key rowKey;

  /// Builds one action row inside the query-param long-press menu.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDelete = action == _KeyValueRowAction.delete;
    final foregroundColor = isDelete ? colors.methodDelete : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Text(
                action.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(action.icon, color: foregroundColor, size: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValueEditorResult {
  const _KeyValueEditorResult({required this.key, required this.value});

  final String key;
  final String value;
}

class _KeyValueEditorSheet extends StatefulWidget {
  const _KeyValueEditorSheet({
    required this.title,
    required this.sectionId,
    required this.index,
    required this.initialItem,
    this.valueLabel = 'Value',
    this.valueHintText,
  });

  final int index;
  final KeyValueItem initialItem;
  final String sectionId;
  final String title;
  final String? valueHintText;
  final String valueLabel;

  @override
  State<_KeyValueEditorSheet> createState() => _KeyValueEditorSheetState();
}

class _KeyValueEditorSheetState extends State<_KeyValueEditorSheet> {
  late final TextEditingController _keyController;
  late final TextEditingController _valueController;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialItem.key);
    _valueController = TextEditingController(text: widget.initialItem.value);
  }

  /// Builds the key-value editor sheet used by long-press Edit actions.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    _KeyValueEditorResult(
                      key: _keyController.text,
                      value: _valueController.text,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            _EditorTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueKeyField(
                widget.sectionId,
                widget.index,
              ),
              value: widget.initialItem.key,
              label: 'Key',
              onChanged: (value) => _keyController.text = value,
            ),
            const SizedBox(height: AppSpacing.small),
            _EditorTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueValueField(
                widget.sectionId,
                widget.index,
              ),
              value: widget.initialItem.value,
              label: widget.valueLabel,
              hintText: widget.valueHintText,
              onChanged: (value) => _valueController.text = value,
            ),
          ],
        ),
      ),
    ),
  );
}

class _EnabledIndicator extends StatelessWidget {
  const _EnabledIndicator({super.key, required this.isEnabled, this.onPressed});

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
  });

  final String fieldKey;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final String value;

  @override
  State<_InlineKeyValueTextField> createState() =>
      _InlineKeyValueTextFieldState();
}

class _InlineKeyValueTextFieldState extends State<_InlineKeyValueTextField> {
  late final TextEditingController _controller;

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
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return TextFormField(
      key: ValueKey<String>(widget.fieldKey),
      controller: _controller,
      onChanged: widget.onChanged,
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

  final VoidCallback onPressed;
  final String sectionId;

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
        if (!methodSupportsRequestBody(draft.method)) ...[
          _InfoCard(
            message:
                'Body will not be sent for ${draft.method.wireName} in this version.',
          ),
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
  final ValueChanged<List<KeyValueItem>> onFormDataChanged;
  final ValueChanged<GraphQlBodyDraft> onGraphQlChanged;
  final ValueChanged<RawBodyDraft> onRawChanged;
  final ValueChanged<RequestBodyType> onTypeChanged;
  final ValueChanged<List<KeyValueItem>> onUrlEncodedChanged;

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
      body.raw.copyWith(subtype: result.subtype, content: result.content),
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
        fieldKey: label == 'Query'
            ? AppWidgetKeys.requestsEditorGraphQlQueryField
            : AppWidgetKeys.requestsEditorGraphQlVariablesField,
        initialValue: currentValue,
        hintText: label == 'Query'
            ? 'query GetUsers { users { id } }'
            : '{\n  "id": "1"\n}',
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

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Column(
        children: [
          _BodyTypeRow(value: body.type, onChanged: onTypeChanged),
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
                  onSaved: (value) =>
                      onGraphQlChanged(body.graphQl.copyWith(query: value)),
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
                  onSaved: (value) =>
                      onGraphQlChanged(body.graphQl.copyWith(variables: value)),
                ),
              ),
            ],
          },
        ],
      ),
    ),
  );
}

class _BodyTypeRow extends StatelessWidget {
  const _BodyTypeRow({required this.value, required this.onChanged});

  final ValueChanged<RequestBodyType> onChanged;
  final RequestBodyType value;

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
            key: const ValueKey<String>(
              AppWidgetKeys.requestsEditorBodyModeField,
            ),
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
  final VoidCallback onTap;
  final String value;

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
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
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
  const _BodyUrlEncodedList({required this.items, required this.onChanged});

  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>> onChanged;

  void _replace(int index, KeyValueItem item) {
    final updatedItems = [...items];
    updatedItems[index] = item;
    onChanged(updatedItems);
  }

  void _remove(int index) {
    final updatedItems = [...items]..removeAt(index);
    onChanged(updatedItems);
  }

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
        onPressed: () =>
            onChanged([...items, const KeyValueItem(key: '', value: '')]),
      ),
    ],
  );
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

  /// Shows the long-press menu for one URL-encoded row and routes actions to edit or delete flows.
  Future<void> _showActionSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_KeyValueRowAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Align(
            alignment: Alignment.bottomCenter,
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
                  _KeyValueActionTile(
                    action: _KeyValueRowAction.edit,
                    rowKey: ValueKey<String>(
                      AppWidgetKeys.requestsEditorKeyValueActionButton(
                        'body_url_encoded',
                        index,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_KeyValueRowAction.edit),
                  ),
                  const _KeyValueDivider(),
                  _KeyValueActionTile(
                    action: _KeyValueRowAction.delete,
                    rowKey: ValueKey<String>(
                      AppWidgetKeys.requestsEditorKeyValueRemoveButton(
                        'body_url_encoded',
                        index,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_KeyValueRowAction.delete),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    switch (action) {
      case _KeyValueRowAction.edit:
        await _showEditSheet(context);
      case _KeyValueRowAction.delete:
        onDelete();
      case null:
        return;
    }
  }

  /// Opens the focused editor sheet for the selected URL-encoded row.
  Future<void> _showEditSheet(BuildContext context) async {
    final result = await showRequestModalSheet<_KeyValueEditorResult?>(
      context,
      builder: (context) => _KeyValueEditorSheet(
        title: 'Edit URL Encoded Field',
        sectionId: 'body_url_encoded',
        index: index,
        initialItem: item,
        valueLabel: 'Value',
      ),
    );

    if (result == null) {
      return;
    }

    onChanged(item.copyWith(key: result.key, value: result.value));
  }

  /// Builds one URL-encoded body row and exposes edit/delete actions on long press.
  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => _showActionSheet(context),
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
}

class _BodyFormDataList extends StatelessWidget {
  const _BodyFormDataList({required this.items, required this.onChanged});

  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>> onChanged;

  void _replace(int index, KeyValueItem item) {
    final updatedItems = [...items];
    updatedItems[index] = item;
    onChanged(updatedItems);
  }

  void _remove(int index) {
    final updatedItems = [...items]..removeAt(index);
    onChanged(updatedItems);
  }

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
        onPressed: () =>
            onChanged([...items, const KeyValueItem(key: '', value: '')]),
      ),
    ],
  );
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

  /// Shows the long-press menu for one form-data row and routes actions to edit or delete flows.
  Future<void> _showActionSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_KeyValueRowAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Align(
            alignment: Alignment.bottomCenter,
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
                  _KeyValueActionTile(
                    action: _KeyValueRowAction.edit,
                    rowKey: ValueKey<String>(
                      AppWidgetKeys.requestsEditorKeyValueActionButton(
                        'body_form_data',
                        index,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_KeyValueRowAction.edit),
                  ),
                  const _KeyValueDivider(),
                  _KeyValueActionTile(
                    action: _KeyValueRowAction.delete,
                    rowKey: ValueKey<String>(
                      AppWidgetKeys.requestsEditorKeyValueRemoveButton(
                        'body_form_data',
                        index,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_KeyValueRowAction.delete),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    switch (action) {
      case _KeyValueRowAction.edit:
        await _showEditSheet(context);
      case _KeyValueRowAction.delete:
        onDelete();
      case null:
        return;
    }
  }

  /// Opens the focused editor sheet for the selected form-data row.
  Future<void> _showEditSheet(BuildContext context) async {
    final isFileItem = item.type == KeyValueItemType.file;
    final result = await showRequestModalSheet<_KeyValueEditorResult?>(
      context,
      builder: (context) => _KeyValueEditorSheet(
        title: isFileItem ? 'Edit Form Data File' : 'Edit Form Data Field',
        sectionId: 'body_form_data',
        index: index,
        initialItem: item,
        valueLabel: isFileItem ? 'File Path' : 'Value',
        valueHintText: isFileItem ? 'C:\\path\\to\\file.json' : null,
      ),
    );

    if (result == null) {
      return;
    }

    onChanged(item.copyWith(key: result.key, value: result.value));
  }

  /// Builds one form-data row and exposes edit/delete actions on long press.
  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => _showActionSheet(context),
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
                          child: Text(
                            type == KeyValueItemType.text ? 'Text' : 'File',
                          ),
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
}

class _BodyFileSelectorRow extends StatelessWidget {
  const _BodyFileSelectorRow({
    required this.index,
    required this.value,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<String> onSelected;
  final String value;

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
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
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
}

class _RawBodyEditorResult {
  const _RawBodyEditorResult({required this.subtype, required this.content});

  final String content;
  final RawBodySubtype subtype;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.content);
    _selectedSubtype = widget.initialValue.subtype;
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

  final bool expands;
  final String fieldKey;
  final String? hintText;
  final String initialValue;
  final int? maxLines;
  final int? minLines;
  final String title;

  @override
  State<_BodyTextEditorSheet> createState() => _BodyTextEditorSheetState();
}

class _BodyTextEditorSheetState extends State<_BodyTextEditorSheet> {
  late final TextEditingController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
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
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
  const _AuthSection({
    required this.auth,
    required this.queryParameters,
    required this.headers,
  });

  final RequestAuthDraft auth;
  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;

  /// Builds the auth-mode selector and the visible credential fields.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _EditorSectionTitle(title: AppStrings.requestEditorAuth),
            const Spacer(),
            PopupMenuButton<String>(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsEditorManageCredentialsButton,
              ),
              tooltip: 'Auth actions',
              icon: const Icon(CupertinoIcons.ellipsis),
              color: context.appColors.surface,
              position: PopupMenuPosition.under,
              onSelected: (_) => showSavedCredentialsSheet(
                context,
                editorCubit: context.read<RequestEditorCubit>(),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'manage_credentials',
                  child: Text(AppStrings.requestEditorApiKeyManageCredentials),
                ),
              ],
            ),
          ],
        ),
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
          AuthType.jwt => _JwtAuthFields(jwt: auth.jwt),
          AuthType.awsSignature => _AwsAuthFields(aws: auth.aws),
          AuthType.apiKey => _ApiKeyAuthFields(apiKey: auth.apiKey),
          AuthType.oauth2 => _OAuth2AuthFields(oauth2: auth.oauth2),
          AuthType.ntlm => _NtlmAuthFields(ntlm: auth.ntlm),
          _ => const _InfoCard(
            message:
                'This auth mode is not supported in the request editor yet.',
          ),
        },
        if (auth.type != AuthType.none) ...[
          const SizedBox(height: AppSpacing.small),
          _GeneratedAuthFieldsCard(
            auth: auth,
            queryParameters: queryParameters,
            headers: headers,
          ),
        ],
      ],
    );
  }
}

class _GeneratedAuthFieldsCard extends StatelessWidget {
  const _GeneratedAuthFieldsCard({
    required this.auth,
    required this.queryParameters,
    required this.headers,
  });

  final RequestAuthDraft auth;
  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;

  /// Returns the generated Authorization header currently synchronized into Headers.
  KeyValueItem? get _generatedAuthorizationHeader {
    for (final header in headers) {
      if (header.key.trim().toLowerCase() == 'authorization' &&
          header.isSystemGeneratedAuthorizationHeader) {
        return header;
      }
    }

    return null;
  }

  /// Returns the generated AWS headers currently synchronized into Headers.
  List<KeyValueItem> get _generatedAwsHeaders => headers
      .where((header) => header.isSystemGeneratedAwsHeader)
      .toList(growable: false);

  /// Returns the generated API Key header currently synchronized into Headers.
  KeyValueItem? get _generatedApiKeyHeader {
    for (final header in headers) {
      if (header.isSystemGeneratedApiKeyHeader) {
        return header;
      }
    }

    return null;
  }

  /// Returns the generated API Key query parameter currently synchronized into Query Params.
  KeyValueItem? get _generatedApiKeyQueryParameter {
    for (final queryParameter in queryParameters) {
      if (queryParameter.isSystemGeneratedApiKeyQueryParameter) {
        return queryParameter;
      }
    }

    return null;
  }

  /// Returns the generated OAuth2 query parameter currently synchronized into Query Params.
  KeyValueItem? get _generatedOAuth2QueryParameter {
    for (final queryParameter in queryParameters) {
      if (queryParameter.isSystemGeneratedOAuth2QueryParameter) {
        return queryParameter;
      }
    }

    return null;
  }

  /// Builds a compact status card so auth-driven header sync is visible without scrolling back to Headers.
  @override
  Widget build(BuildContext context) {
    final authorizationHeader = _generatedAuthorizationHeader;
    final awsHeaders = _generatedAwsHeaders;
    final apiKeyHeader = _generatedApiKeyHeader;
    final apiKeyQueryParameter = _generatedApiKeyQueryParameter;
    final oauth2QueryParameter = _generatedOAuth2QueryParameter;

    final message = switch (auth.type) {
      AuthType.basic =>
        authorizationHeader != null
            ? 'Authorization is synced to Headers as ${authorizationHeader.value}.'
            : 'Enter username or password to auto-add Authorization in Headers.',
      AuthType.bearerToken =>
        authorizationHeader != null
            ? 'Authorization is synced to Headers as ${authorizationHeader.value}.'
            : 'Enter a token to auto-add Authorization in Headers.',
      AuthType.jwt =>
        authorizationHeader != null
            ? 'Authorization is synced to Headers as ${authorizationHeader.value}.'
            : 'Enter a JWT token to auto-add Authorization in Headers.',
      AuthType.awsSignature =>
        awsHeaders.isNotEmpty
            ? 'AWS Signature headers are synced to Headers automatically.'
            : 'Enter access key, secret key, region, service, and a valid URL to auto-add AWS headers.',
      AuthType.apiKey =>
        apiKeyHeader != null
            ? 'API Key is synced to Headers as ${apiKeyHeader.key}.'
            : apiKeyQueryParameter != null
            ? 'API Key is synced to Query Params as ${apiKeyQueryParameter.key}.'
            : 'Enter an API key name and value to sync it into Headers or Query Params.',
      AuthType.oauth2 =>
        authorizationHeader != null
            ? 'OAuth 2.0 is synced to Headers as ${authorizationHeader.value}.'
            : oauth2QueryParameter != null
            ? 'OAuth 2.0 is synced to Query Params as ${oauth2QueryParameter.key}.'
            : auth.oauth2.isManual
            ? 'Enter a token to sync OAuth 2.0 into Headers or Query Params.'
            : AppStrings.requestEditorOAuth2ImplementedLater,
      AuthType.ntlm =>
        'NTLM authenticates the connection during send; no Authorization header is added here.',
      _ => 'This auth mode does not generate editor-managed headers yet.',
    };

    return _InfoCard(message: message);
  }
}

class _JwtAuthFields extends StatelessWidget {
  const _JwtAuthFields({required this.jwt});

  final JwtAuthDraft jwt;

  /// Builds the JWT token field used to drive the generated Bearer header.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    return _EditorTextField(
      fieldKey: AppWidgetKeys.requestsEditorAuthField('jwt_token'),
      value: jwt.token,
      label: 'Token',
      onChanged: (value) => editorCubit.updateAuth(
        editorCubit.state.draft.auth.copyWith(
          jwt: JwtAuthDraft(
            token: value,
            header: jwt.header,
            payload: jwt.payload,
            secret: jwt.secret,
            algorithm: jwt.algorithm,
            prefix: jwt.prefix,
          ),
        ),
      ),
    );
  }
}

class _AwsAuthFields extends StatelessWidget {
  const _AwsAuthFields({required this.aws});

  final AwsAuthDraft aws;

  /// Builds the AWS credential fields used to derive SigV4 headers.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    void updateAws(AwsAuthDraft next) {
      editorCubit.updateAuth(editorCubit.state.draft.auth.copyWith(aws: next));
    }

    return Column(
      children: [
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('aws_access_key'),
          value: aws.accessKey,
          label: 'Access Key',
          onChanged: (value) => updateAws(
            AwsAuthDraft(
              accessKey: value,
              secretKey: aws.secretKey,
              region: aws.region,
              service: aws.service,
              sessionToken: aws.sessionToken,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('aws_secret_key'),
          value: aws.secretKey,
          label: 'Secret Key',
          obscureText: true,
          onChanged: (value) => updateAws(
            AwsAuthDraft(
              accessKey: aws.accessKey,
              secretKey: value,
              region: aws.region,
              service: aws.service,
              sessionToken: aws.sessionToken,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('aws_region'),
          value: aws.region,
          label: 'Region',
          onChanged: (value) => updateAws(
            AwsAuthDraft(
              accessKey: aws.accessKey,
              secretKey: aws.secretKey,
              region: value,
              service: aws.service,
              sessionToken: aws.sessionToken,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('aws_service'),
          value: aws.service,
          label: 'Service',
          onChanged: (value) => updateAws(
            AwsAuthDraft(
              accessKey: aws.accessKey,
              secretKey: aws.secretKey,
              region: aws.region,
              service: value,
              sessionToken: aws.sessionToken,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('aws_session_token'),
          value: aws.sessionToken,
          label: 'Session Token',
          onChanged: (value) => updateAws(
            AwsAuthDraft(
              accessKey: aws.accessKey,
              secretKey: aws.secretKey,
              region: aws.region,
              service: aws.service,
              sessionToken: value,
            ),
          ),
        ),
      ],
    );
  }
}

class _NtlmAuthFields extends StatelessWidget {
  const _NtlmAuthFields({required this.ntlm});

  final NtlmAuthDraft ntlm;

  /// Builds the NTLM credential fields used to authenticate the connection.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    void updateNtlm(NtlmAuthDraft next) {
      editorCubit.updateAuth(editorCubit.state.draft.auth.copyWith(ntlm: next));
    }

    return Column(
      children: [
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('ntlm_username'),
          value: ntlm.username,
          label: 'Username',
          onChanged: (value) => updateNtlm(ntlm.copyWith(username: value)),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('ntlm_password'),
          value: ntlm.password,
          label: 'Password',
          obscureText: true,
          onChanged: (value) => updateNtlm(ntlm.copyWith(password: value)),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('ntlm_domain'),
          value: ntlm.domain,
          label: 'Domain',
          onChanged: (value) => updateNtlm(ntlm.copyWith(domain: value)),
        ),
      ],
    );
  }
}

class _ApiKeyAuthFields extends StatelessWidget {
  const _ApiKeyAuthFields({required this.apiKey});

  final ApiKeyAuthDraft apiKey;

  /// Whether the configured key name uses the custom entry instead of a preset.
  bool get _isCustom => !apiKeyNamePresets.contains(apiKey.name);

  /// Builds the key-name selector, value field, location switch, and manage-credentials action.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    void updateApiKey(ApiKeyAuthDraft next) {
      editorCubit.updateAuth(
        editorCubit.state.draft.auth.copyWith(apiKey: next),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: _buildCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: _EditorDropdownField<String>(
              fieldKey: AppWidgetKeys.requestsEditorAuthField('api_key_name'),
              label: AppStrings.requestEditorApiKeyName,
              value: _isCustom ? apiKeyCustomNameSentinel : apiKey.name,
              items: <DropdownMenuItem<String>>[
                ...apiKeyNamePresets.map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                ),
                const DropdownMenuItem<String>(
                  value: apiKeyCustomNameSentinel,
                  child: Text(AppStrings.requestEditorApiKeyCustomOption),
                ),
              ],
              onChanged: (selected) {
                if (selected == null) {
                  return;
                }
                final nextName = selected == apiKeyCustomNameSentinel
                    ? ''
                    : selected;
                updateApiKey(
                  ApiKeyAuthDraft(
                    name: nextName,
                    value: apiKey.value,
                    location: apiKey.location,
                  ),
                );
              },
            ),
          ),
        ),
        if (_isCustom) ...[
          const SizedBox(height: AppSpacing.small),
          _EditorTextField(
            fieldKey: AppWidgetKeys.requestsEditorAuthField(
              'api_key_custom_name',
            ),
            value: apiKey.name,
            label: AppStrings.requestEditorApiKeyCustomName,
            onChanged: (value) => updateApiKey(
              ApiKeyAuthDraft(
                name: value,
                value: apiKey.value,
                location: apiKey.location,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('api_key_value'),
          value: apiKey.value,
          label: AppStrings.requestEditorApiKeyValue,
          onChanged: (value) => updateApiKey(
            ApiKeyAuthDraft(
              name: apiKey.name,
              value: value,
              location: apiKey.location,
            ),
          ),
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
                    AppStrings.requestEditorApiKeySendAsHeader,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch.adaptive(
                  key: const ValueKey<String>(
                    'requests_editor_auth_api_key_send_as_header_switch',
                  ),
                  value: apiKey.location == ApiKeyLocation.header,
                  onChanged: (sendAsHeader) => updateApiKey(
                    ApiKeyAuthDraft(
                      name: apiKey.name,
                      value: apiKey.value,
                      location: sendAsHeader
                          ? ApiKeyLocation.header
                          : ApiKeyLocation.query,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showSavedCredentialsSheet(
              context,
              editorCubit: context.read<RequestEditorCubit>(),
            ),
            icon: const Icon(CupertinoIcons.lock),
            label: const Text(AppStrings.requestEditorApiKeyManageCredentials),
          ),
        ),
      ],
    );
  }
}

class _OAuth2AuthFields extends StatelessWidget {
  const _OAuth2AuthFields({required this.oauth2});

  final OAuth2AuthDraft oauth2;

  /// Opens the OAuth2 configuration sheet and persists the returned configuration.
  Future<void> _openConfigurationSheet(BuildContext context) async {
    final configurationResult =
        await showRequestModalSheet<_OAuth2ConfigurationResult?>(
          context,
          builder: (context) =>
              _OAuth2ConfigurationSheet(initialOauth2: oauth2),
        );

    if (!context.mounted || configurationResult == null) {
      return;
    }

    final editorCubit = context.read<RequestEditorCubit>();
    editorCubit.updateAuth(
      editorCubit.state.draft.auth.copyWith(oauth2: configurationResult.oauth2),
    );

    if (configurationResult.tokenDetails != null) {
      await showOAuth2TokenDetailsSheet(
        context,
        tokenDetails: configurationResult.tokenDetails!,
      );
    }
  }

  /// Builds the inline OAuth2 controls for manual token entry and sync mode selection.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    void updateOauth2(OAuth2AuthDraft next) {
      editorCubit.updateAuth(
        editorCubit.state.draft.auth.copyWith(oauth2: next),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_access_token',
          ),
          value: oauth2.accessToken,
          label: AppStrings.requestEditorOAuth2Token,
          hintText: 'Enter Value',
          onChanged: (value) =>
              updateOauth2(oauth2.copyWith(accessToken: value)),
        ),
        if (oauth2.accessToken.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          _EditorSummaryRow(
            label: AppStrings.requestEditorOAuth2Validity,
            value: AppStrings.requestEditorOAuth2NoExpiry,
          ),
        ],
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
                    AppStrings.requestEditorOAuth2AsHeader,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch.adaptive(
                  key: const ValueKey<String>(
                    AppWidgetKeys.requestsEditorOAuth2AsHeaderSwitch,
                  ),
                  value: oauth2.addTokenToHeader,
                  onChanged: (value) =>
                      updateOauth2(oauth2.copyWith(addTokenToHeader: value)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_header_prefix',
          ),
          value: oauth2.headerPrefix,
          label: AppStrings.requestEditorOAuth2HeaderPrefix,
          onChanged: (value) =>
              updateOauth2(oauth2.copyWith(headerPrefix: value)),
        ),
        const SizedBox(height: AppSpacing.small),
        InkWell(
          key: const ValueKey<String>(
            AppWidgetKeys.requestsEditorOAuth2ConfigureButton,
          ),
          onTap: () => _openConfigurationSheet(context),
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.xxLarge),
          ),
          child: DecoratedBox(
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
                      AppStrings.requestEditorOAuth2Configure,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    oauth2.grantType.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  const Icon(CupertinoIcons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        if (!oauth2.isManual) ...[
          const SizedBox(height: AppSpacing.small),
          const _InfoCard(
            message: AppStrings.requestEditorOAuth2ImplementedLater,
          ),
        ],
      ],
    );
  }
}

class _OAuth2ConfigurationSheet extends StatefulWidget {
  const _OAuth2ConfigurationSheet({required this.initialOauth2});

  final OAuth2AuthDraft initialOauth2;

  @override
  State<_OAuth2ConfigurationSheet> createState() =>
      _OAuth2ConfigurationSheetState();
}

class _OAuth2ConfigurationResult {
  const _OAuth2ConfigurationResult({required this.oauth2, this.tokenDetails});

  final OAuth2AuthDraft oauth2;
  final OAuth2TokenDetailsEntity? tokenDetails;
}

class _OAuth2ConfigurationSheetState extends State<_OAuth2ConfigurationSheet> {
  late OAuth2AuthDraft _oauth2;
  bool _isAuthorizing = false;

  /// Returns the number label shown for enabled key/value params in summary rows.
  String _countLabel(List<KeyValueItem> items) {
    final enabledCount = items
        .where((item) => item.isEnabled && item.hasKey)
        .length;
    if (enabledCount == 0) {
      return 'None';
    }

    return enabledCount == 1 ? '1 Param' : '$enabledCount Params';
  }

  /// Returns a generated state when the current OAuth2 config has not set one yet.
  String _ensureStateValue(String state) {
    if (state.trim().isNotEmpty) {
      return state;
    }

    return 'state-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Returns a generated PKCE verifier when the current OAuth2 config needs one.
  String _ensureCodeVerifier(OAuth2AuthDraft oauth2) {
    if (!oauth2.usePkce) {
      return '';
    }

    if (oauth2.codeVerifier.trim().isNotEmpty) {
      return oauth2.codeVerifier;
    }

    return generateOAuth2CodeVerifier();
  }

  /// Returns the first blocking validation error for the authorization code flow.
  String? _authorizationCodeValidationError(OAuth2AuthDraft oauth2) {
    if (oauth2.authorizationUrl.trim().isEmpty) {
      return 'Missing Auth URL.';
    }
    if (oauth2.resolvedAccessTokenUrl.trim().isEmpty) {
      return 'Missing Access Token URL.';
    }
    if (oauth2.clientId.trim().isEmpty) {
      return 'Missing Client ID.';
    }
    if (oauth2.redirectUri.trim().isEmpty) {
      return 'Missing Redirect URI.';
    }
    if (oauth2.redirectUri.trim() != defaultOAuth2MobileRedirectUri) {
      return AppStrings.requestEditorOAuth2RedirectUriInvalid;
    }

    return null;
  }

  /// Builds the auth draft used for the authorize URL and later token exchange.
  OAuth2AuthDraft _prepareAuthorizationCodeDraft() {
    final nextState = _ensureStateValue(_oauth2.state);
    final nextCodeVerifier = _ensureCodeVerifier(_oauth2);

    return _oauth2.copyWith(state: nextState, codeVerifier: nextCodeVerifier);
  }

  /// Shows the standard OAuth2 flow-failure sheet without crashing the editor.
  Future<void> _showFlowFailedSheet(String detail) {
    return showRequestModalSheet<void>(
      context,
      builder: (context) => _OAuth2FlowFailedSheet(detail: detail),
    );
  }

  /// Opens the shared key/value editor used for Auth URL Params and Token Request Params.
  Future<List<KeyValueItem>?> _openParamsSheet({
    required String title,
    required List<KeyValueItem> initialItems,
  }) => showRequestModalSheet<List<KeyValueItem>?>(
    context,
    builder: (context) =>
        _OAuth2ParamsSheet(title: title, initialItems: initialItems),
  );

  /// Waits for the next matching OAuth callback, including one that may have arrived just before listening.
  Future<Uri> _waitForOAuthCallback() async {
    final callbackService = getIt<OAuth2CallbackService>();
    final pendingCallback = callbackService.takePendingCallback();
    if (pendingCallback != null) {
      return pendingCallback;
    }

    return callbackService.callbackStream.first;
  }

  /// Exchanges the callback code and closes the configuration sheet with the resolved token values.
  Future<void> _completeAuthorizationCodeFlow({
    required OAuth2AuthDraft preparedOauth2,
    required String authorizationCode,
    required Uri authorizationUrl,
  }) async {
    final tokenDetails = await getIt<ExchangeOAuth2AuthorizationCodeUseCase>()(
      auth: preparedOauth2,
      code: authorizationCode,
    );

    if (!mounted) {
      return;
    }

    final resolvedTokenDetails = tokenDetails.copyWith(
      resolvedAuthUrl: authorizationUrl.toString(),
    );
    final tokenType = resolvedTokenDetails.tokenType.trim();
    final nextPrefix = tokenType.isEmpty
        ? preparedOauth2.headerPrefix
        : tokenType;

    Navigator.of(context).pop(
      _OAuth2ConfigurationResult(
        oauth2: preparedOauth2.copyWith(
          accessToken: resolvedTokenDetails.accessToken,
          refreshToken:
              resolvedTokenDetails.refreshToken ?? preparedOauth2.refreshToken,
          headerPrefix: nextPrefix,
          authorizationCode: authorizationCode,
        ),
        tokenDetails: resolvedTokenDetails,
      ),
    );
  }

  /// Runs the Authorization Code flow by launching the browser and waiting for the app deep link callback.
  Future<void> _handleGetAccessToken() async {
    final validationError = _authorizationCodeValidationError(_oauth2);
    if (validationError != null) {
      await _showFlowFailedSheet(validationError);
      return;
    }

    final preparedOauth2 = _prepareAuthorizationCodeDraft();
    final authorizationUrl = buildOAuth2AuthorizationUrl(preparedOauth2);
    if (authorizationUrl == null) {
      await _showFlowFailedSheet(AppStrings.requestEditorOAuth2BuildUrlFailed);
      return;
    }

    final callbackService = getIt<OAuth2CallbackService>();
    callbackService.clearPendingCallback();

    setState(() {
      _oauth2 = preparedOauth2;
      _isAuthorizing = true;
    });

    try {
      final launched = await getIt<ExternalUriLauncher>().launchExternal(
        authorizationUrl,
      );
      if (!launched) {
        if (!mounted) {
          return;
        }

        final exchangeResult =
            await showRequestModalSheet<_OAuth2ExchangeResult?>(
              context,
              builder: (context) => _OAuth2AuthorizationAssistSheet(
                authorizationUrl: authorizationUrl,
                initialOauth2: preparedOauth2,
              ),
            );
        if (!mounted || exchangeResult == null) {
          return;
        }

        await _completeAuthorizationCodeFlow(
          preparedOauth2: preparedOauth2,
          authorizationCode: exchangeResult.authorizationCode,
          authorizationUrl: authorizationUrl,
        );
        return;
      }

      final callbackUri = await _waitForOAuthCallback();
      final callbackData = parseOAuth2CallbackUri(
        callbackUri: callbackUri,
        expectedState: preparedOauth2.state,
      );
      await _completeAuthorizationCodeFlow(
        preparedOauth2: preparedOauth2,
        authorizationCode: callbackData.code,
        authorizationUrl: authorizationUrl,
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      await _showFlowFailedSheet(error.message);
    } on Object {
      if (!mounted) {
        return;
      }

      await _showFlowFailedSheet('Token exchange failed.');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthorizing = false;
        });
      }
    }
  }

  /// Builds the updated OAuth2 draft and closes the configuration sheet.
  void _handleDone() {
    Navigator.of(context).pop(_OAuth2ConfigurationResult(oauth2: _oauth2));
  }

  @override
  void initState() {
    super.initState();
    _oauth2 = widget.initialOauth2;
  }

  /// Builds the dedicated OAuth2 configuration sheet used to select grant type and token.
  @override
  Widget build(BuildContext context) {
    final grantTypeFields = switch (_oauth2.grantType) {
      OAuth2GrantType.manual => [
        const _EditorSectionTitle(title: AppStrings.requestEditorOAuth2Token),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_sheet_access_token',
          ),
          value: _oauth2.accessToken,
          label: AppStrings.requestEditorOAuth2Token,
          hintText: 'Enter Value',
          onChanged: (value) {
            setState(() {
              _oauth2 = _oauth2.copyWith(accessToken: value);
            });
          },
        ),
      ],
      OAuth2GrantType.authorizationCode => [
        const _EditorSectionTitle(
          title: AppStrings.requestEditorOAuth2Configuration,
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_authorization_url',
          ),
          value: _oauth2.authorizationUrl,
          label: AppStrings.requestEditorOAuth2AuthUrl,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(authorizationUrl: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_access_token_url',
          ),
          value: _oauth2.accessTokenUrl,
          label: AppStrings.requestEditorOAuth2AccessTokenUrl,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(accessTokenUrl: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('oauth2_client_id'),
          value: _oauth2.clientId,
          label: AppStrings.requestEditorOAuth2ClientId,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(clientId: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_client_secret',
          ),
          value: _oauth2.clientSecret,
          label: AppStrings.requestEditorOAuth2ClientSecret,
          obscureText: true,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(clientSecret: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_redirect_uri',
          ),
          value: _oauth2.redirectUri,
          label: AppStrings.requestEditorOAuth2RedirectUri,
          hintText: defaultOAuth2MobileRedirectUri,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(redirectUri: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('oauth2_scope'),
          value: _oauth2.scope,
          label: AppStrings.requestEditorOAuth2Scope,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(scope: value);
          }),
        ),
        const SizedBox(height: AppSpacing.large),
        const _EditorSectionTitle(
          title: AppStrings.requestEditorOAuth2Advanced,
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
                    AppStrings.requestEditorOAuth2UsePkce,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch.adaptive(
                  value: _oauth2.usePkce,
                  onChanged: (value) => setState(() {
                    _oauth2 = _oauth2.copyWith(
                      usePkce: value,
                      codeVerifier: value ? _oauth2.codeVerifier : '',
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        if (_oauth2.usePkce) ...[
          const SizedBox(height: AppSpacing.small),
          DecoratedBox(
            decoration: _buildCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: _EditorDropdownField<OAuth2PkceMethod>(
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'oauth2_pkce_method',
                ),
                label: AppStrings.requestEditorOAuth2PkceMethod,
                value: _oauth2.pkceMethod,
                items: OAuth2PkceMethod.values
                    .map(
                      (method) => DropdownMenuItem<OAuth2PkceMethod>(
                        value: method,
                        child: Text(method.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _oauth2 = _oauth2.copyWith(pkceMethod: value);
                  });
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField('oauth2_state'),
          value: _oauth2.state,
          label: AppStrings.requestEditorOAuth2State,
          hintText: 'Auto-generated',
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(state: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        DecoratedBox(
          decoration: _buildCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: _EditorDropdownField<OAuth2ClientAuthentication>(
              fieldKey: AppWidgetKeys.requestsEditorAuthField(
                'oauth2_client_authentication',
              ),
              label: AppStrings.requestEditorOAuth2ClientAuthentication,
              value: _oauth2.clientAuthentication,
              items: OAuth2ClientAuthentication.values
                  .map(
                    (authentication) =>
                        DropdownMenuItem<OAuth2ClientAuthentication>(
                          value: authentication,
                          child: Text(authentication.label),
                        ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _oauth2 = _oauth2.copyWith(clientAuthentication: value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _OAuth2NavigationRow(
          label: AppStrings.requestEditorOAuth2AuthUrlParams,
          value: _countLabel(_oauth2.authUrlParams),
          onTap: () async {
            final updatedItems = await _openParamsSheet(
              title: AppStrings.requestEditorOAuth2AuthUrlParamsTitle,
              initialItems: _oauth2.authUrlParams,
            );
            if (!mounted || updatedItems == null) {
              return;
            }

            setState(() {
              _oauth2 = _oauth2.copyWith(authUrlParams: updatedItems);
            });
          },
        ),
        const SizedBox(height: AppSpacing.small),
        _OAuth2NavigationRow(
          label: AppStrings.requestEditorOAuth2TokenRequestParams,
          value: _countLabel(_oauth2.tokenRequestParams),
          onTap: () async {
            final updatedItems = await _openParamsSheet(
              title: AppStrings.requestEditorOAuth2TokenRequestParamsTitle,
              initialItems: _oauth2.tokenRequestParams,
            );
            if (!mounted || updatedItems == null) {
              return;
            }

            setState(() {
              _oauth2 = _oauth2.copyWith(tokenRequestParams: updatedItems);
            });
          },
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_refresh_token_url',
          ),
          value: _oauth2.refreshTokenUrl,
          label: AppStrings.requestEditorOAuth2RefreshTokenUrl,
          hintText: AppStrings.requestEditorOAuth2RefreshTokenUrlHint,
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(refreshTokenUrl: value);
          }),
        ),
        const SizedBox(height: AppSpacing.large),
        const _EditorSectionTitle(title: AppStrings.requestEditorOAuth2Token),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorAuthField(
            'oauth2_sheet_access_token',
          ),
          value: _oauth2.accessToken,
          label: AppStrings.requestEditorOAuth2Token,
          hintText: 'Enter Value',
          onChanged: (value) => setState(() {
            _oauth2 = _oauth2.copyWith(accessToken: value);
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsEditorOAuth2GetAccessTokenButton,
            ),
            onPressed: _isAuthorizing ? null : _handleGetAccessToken,
            child: Text(
              _isAuthorizing
                  ? AppStrings.requestEditorOAuth2WaitingForCallback
                  : AppStrings.requestEditorOAuth2GetAccessToken,
            ),
          ),
        ),
      ],
      _ => [
        const _InfoCard(
          message: AppStrings.requestEditorOAuth2ImplementedLater,
        ),
      ],
    };

    return RequestModalSheetCard(
      key: const ValueKey<String>(
        AppWidgetKeys.requestsEditorOAuth2ConfigSheet,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.large,
          AppSpacing.large,
          AppSpacing.large,
          AppSpacing.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'OAuth 2.0',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  key: const ValueKey<String>(
                    AppWidgetKeys.requestsEditorOAuth2ConfigDoneButton,
                  ),
                  onPressed: _handleDone,
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _EditorSectionTitle(
                      title: AppStrings.requestEditorOAuth2Configuration,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    DecoratedBox(
                      decoration: _buildCardDecoration(context),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        child: _EditorDropdownField<OAuth2GrantType>(
                          fieldKey: AppWidgetKeys.requestsEditorAuthField(
                            'oauth2_grant_type',
                          ),
                          label: AppStrings.requestEditorOAuth2GrantType,
                          value: _oauth2.grantType,
                          items: OAuth2GrantType.values
                              .map(
                                (grantType) =>
                                    DropdownMenuItem<OAuth2GrantType>(
                                      value: grantType,
                                      child: Text(grantType.label),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _oauth2 = _oauth2.copyWith(grantType: value);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    ...grantTypeFields,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OAuth2NavigationRow extends StatelessWidget {
  const _OAuth2NavigationRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;
  final String value;

  /// Builds a tappable summary row used to open nested OAuth2 configuration sheets.
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    child: DecoratedBox(
      decoration: _buildCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            const Icon(CupertinoIcons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _OAuth2ParamsSheet extends StatefulWidget {
  const _OAuth2ParamsSheet({required this.title, required this.initialItems});

  final List<KeyValueItem> initialItems;
  final String title;

  @override
  State<_OAuth2ParamsSheet> createState() => _OAuth2ParamsSheetState();
}

class _OAuth2ParamsSheetState extends State<_OAuth2ParamsSheet> {
  late List<KeyValueItem> _items;

  /// Adds a new empty param row to the local OAuth2 params sheet state.
  void _addItem() {
    setState(() {
      _items = <KeyValueItem>[
        ..._items,
        const KeyValueItem(key: '', value: ''),
      ];
    });
  }

  /// Closes the params sheet and returns the edited param collection.
  void _done() {
    Navigator.of(context).pop(List<KeyValueItem>.unmodifiable(_items));
  }

  @override
  void initState() {
    super.initState();
    _items = List<KeyValueItem>.from(widget.initialItems);
  }

  /// Builds the Auth URL Params or Token Request Params editor sheet.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.back),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: _done, child: const Text('Done')),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _items.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.small),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(CupertinoIcons.add),
                      label: const Text(AppStrings.requestEditorAdd),
                    ),
                  );
                }

                final item = _items[index];
                return DecoratedBox(
                  decoration: _buildCardDecoration(context),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Param ${index + 1}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Switch.adaptive(
                              value: item.isEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _items[index] = item.copyWith(
                                    isEnabled: value,
                                  );
                                });
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(index);
                                });
                              },
                              icon: const Icon(CupertinoIcons.delete),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.small),
                        _EditorTextField(
                          fieldKey: 'oauth2_params_${widget.title}_key_$index',
                          value: item.key,
                          label: 'Key',
                          onChanged: (value) {
                            setState(() {
                              _items[index] = item.copyWith(key: value);
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.small),
                        _EditorTextField(
                          fieldKey:
                              'oauth2_params_${widget.title}_value_$index',
                          value: item.value,
                          label: 'Value',
                          onChanged: (value) {
                            setState(() {
                              _items[index] = item.copyWith(value: value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _OAuth2ExchangeResult {
  const _OAuth2ExchangeResult({required this.authorizationCode});

  final String authorizationCode;
}

class _OAuth2AuthorizationAssistSheet extends StatefulWidget {
  const _OAuth2AuthorizationAssistSheet({
    required this.authorizationUrl,
    required this.initialOauth2,
  });

  final Uri authorizationUrl;
  final OAuth2AuthDraft initialOauth2;

  @override
  State<_OAuth2AuthorizationAssistSheet> createState() =>
      _OAuth2AuthorizationAssistSheetState();
}

class _OAuth2AuthorizationAssistSheetState
    extends State<_OAuth2AuthorizationAssistSheet> {
  late final TextEditingController _codeController;
  bool _isSubmitting = false;

  /// Copies the generated authorize URL to the clipboard for the manual browser step.
  Future<void> _copyUrl() async {
    await Clipboard.setData(
      ClipboardData(text: widget.authorizationUrl.toString()),
    );
  }

  /// Exchanges the manually pasted authorization code through the OAuth2 use case.
  Future<void> _exchangeCode() async {
    final authorizationCode = _codeController.text.trim();
    if (authorizationCode.isEmpty) {
      await showRequestModalSheet<void>(
        context,
        builder: (context) => const _OAuth2FlowFailedSheet(
          detail: 'OAuth callback did not include code.',
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(_OAuth2ExchangeResult(authorizationCode: authorizationCode));
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      await showRequestModalSheet<void>(
        context,
        builder: (context) => _OAuth2FlowFailedSheet(detail: error.message),
      );
    } on Object {
      if (!mounted) {
        return;
      }

      await showRequestModalSheet<void>(
        context,
        builder: (context) =>
            const _OAuth2FlowFailedSheet(detail: 'Token exchange failed.'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.initialOauth2.authorizationCode,
    );
  }

  /// Builds the authorize-link fallback sheet used when no in-app callback/browser integration exists.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(
      AppWidgetKeys.requestsEditorOAuth2AuthorizeAssistSheet,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OAuth 2.0', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.large),
          const _InfoCard(
            message: AppStrings.requestEditorOAuth2ManualAuthorization,
          ),
          const SizedBox(height: AppSpacing.small),
          const _InfoCard(
            message: AppStrings.requestEditorOAuth2OpenAuthorizeUrl,
          ),
          const SizedBox(height: AppSpacing.small),
          DecoratedBox(
            decoration: _buildCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: SelectableText(widget.authorizationUrl.toString()),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _copyUrl,
              icon: const Icon(CupertinoIcons.doc_on_doc),
              label: const Text(AppStrings.requestEditorOAuth2CopyAuthorizeUrl),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          _EditorTextField(
            fieldKey: AppWidgetKeys.requestsEditorAuthField(
              'oauth2_authorization_code',
            ),
            value: _codeController.text,
            label: AppStrings.requestEditorOAuth2AuthorizationCode,
            onChanged: (value) {
              _codeController.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            },
          ),
          const SizedBox(height: AppSpacing.small),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _exchangeCode,
              child: Text(
                _isSubmitting
                    ? 'Loading...'
                    : AppStrings.requestEditorOAuth2ExchangeCode,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OAuth2FlowFailedSheet extends StatelessWidget {
  const _OAuth2FlowFailedSheet({required this.detail});

  final String detail;

  /// Builds the standard OAuth2 flow-failure sheet for malformed responses and validation failures.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(
      AppWidgetKeys.requestsEditorOAuth2FlowFailedSheet,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.requestEditorOAuth2FlowFailed,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          const _EditorSectionTitle(
            title: AppStrings.requestEditorOAuth2Status,
          ),
          const SizedBox(height: AppSpacing.small),
          DecoratedBox(
            decoration: _buildCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: context.appColors.methodDelete,
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.requestEditorOAuth2MalformedResponse,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          detail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EditorSummaryRow extends StatelessWidget {
  const _EditorSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  /// Builds a compact label-value row for passive auth metadata like token validity.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
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

  final bool isLoading;
  final VoidCallback onPressed;

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
  final List<DropdownMenuItem<T>> items;
  final String label;
  final ValueChanged<T?> onChanged;
  final T value;

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
    this.obscureText = false,
  });

  final String fieldKey;
  final String? hintText;
  final TextInputType? keyboardType;
  final String label;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final TextInputAction? textInputAction;
  final String value;

  @override
  State<_EditorTextField> createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends State<_EditorTextField> {
  late final TextEditingController _controller;

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  /// Renders a controlled text field that stays synchronized with immutable cubit state.
  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey<String>(widget.fieldKey),
    controller: _controller,
    onChanged: widget.onChanged,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
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
