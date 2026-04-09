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
      case _RequestEditorMoreAction.environment:
        await _openEnvironmentPicker();
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

  Future<void> _openEnvironmentPicker() async {
    // TODO: Open the request environment picker and persist the selected environment.
  }

  void _useGraphQlMode() {
    final editorCubit = context.read<RequestEditorCubit>();
    final body = editorCubit.state.draft.body;

    editorCubit.updateBody(body.copyWith(type: RequestBodyType.graphql));
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

    final action = await showCupertinoModalPopup<_UnsavedChangesAction>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Unsaved Changes'),
        message: const Text('Do you want to save this request before closing?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChangesAction.save),
            child: const Text('Save'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChangesAction.discard),
            child: const Text('Discard'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () =>
              Navigator.of(context).pop(_UnsavedChangesAction.cancel),
          child: const Text('Cancel'),
        ),
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
  environment,
  useGraphQl,
  viewCurl,
  exportHar,
  cookies,
  tests,
  settings,
}

extension _RequestEditorMoreActionLabel on _RequestEditorMoreAction {
  String get label => switch (this) {
    _RequestEditorMoreAction.environment => 'Environment',
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
  Widget build(BuildContext context) =>
      PopupMenuButton<_RequestEditorMoreAction>(
        tooltip: 'More request actions',
        icon: const Icon(CupertinoIcons.ellipsis),
        color: context.appColors.surface,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        constraints: const BoxConstraints(minWidth: 196),
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (context) => _RequestEditorMoreAction.values
            .map(
              (action) => PopupMenuItem<_RequestEditorMoreAction>(
                value: action,
                child: _RequestEditorMoreMenuRow(label: action.label),
              ),
            )
            .toList(growable: false),
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
  Widget build(BuildContext context) {
    return Column(
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
    required this.onAddPressed,
  });

  final String sectionId;
  final List<KeyValueItem> items;
  final void Function(int index, KeyValueItem item) onItemChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final rowCount = items.length + 1;

    return DecoratedBox(
      decoration: _buildCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Column(
          children: [
            for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              if (rowIndex < items.length)
                _KeyValueRow(
                  sectionId: sectionId,
                  index: rowIndex,
                  item: items[rowIndex],
                  onChanged: (item) => onItemChanged(rowIndex, item),
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
  });

  final String sectionId;
  final int index;
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
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
            onPressed: () =>
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
        ],
      ),
    ),
  );
}

class _EnabledIndicator extends StatelessWidget {
  const _EnabledIndicator({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

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
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;

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
      onChanged: widget.onChanged,
      textAlign: widget.textAlign,
      style: textStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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
        _EditorDropdownField<RequestBodyType>(
          fieldKey: AppWidgetKeys.requestsEditorBodyModeField,
          label: AppStrings.requestEditorType,
          value: body.type,
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
              editorCubit.updateBody(body.copyWith(type: type));
            }
          },
        ),
        const SizedBox(height: AppSpacing.small),
        if (!draft.method.supportsRequestBody) ...[
          const _InfoCard(
            message:
                'This HTTP method usually ignores bodies, but the editor still lets you configure one.',
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        switch (body.type) {
          RequestBodyType.none => const _InfoCard(
            message: AppStrings.requestEditorBodyEmptyMessage,
          ),
          RequestBodyType.raw => Column(
            children: [
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorRawContentTypeField,
                value: body.rawContentType,
                label: 'Content Type',
                hintText: 'text/plain',
                onChanged: (value) => editorCubit.updateBody(
                  body.copyWith(rawContentType: value),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorRawBodyField,
                value: body.raw,
                label: 'Raw Body',
                minLines: 6,
                maxLines: 10,
                onChanged: (value) =>
                    editorCubit.updateBody(body.copyWith(raw: value)),
              ),
            ],
          ),
          RequestBodyType.json => _EditorTextField(
            fieldKey: AppWidgetKeys.requestsEditorJsonBodyField,
            value: body.json,
            label: 'JSON Body',
            hintText: '{\n  "userId": "{{user_id}}"\n}',
            minLines: 8,
            maxLines: 12,
            onChanged: (value) =>
                editorCubit.updateBody(body.copyWith(json: value)),
          ),
          RequestBodyType.formData => _KeyValueSection(
            title: 'Form Data',
            sectionId: 'form_data',
            items: body.formData,
            onItemsChanged: (items) =>
                editorCubit.updateBody(body.copyWith(formData: items)),
          ),
          RequestBodyType.xWwwFormUrlEncoded => _KeyValueSection(
            title: 'x-www-form-urlencoded',
            sectionId: 'url_encoded',
            items: body.urlEncoded,
            onItemsChanged: (items) =>
                editorCubit.updateBody(body.copyWith(urlEncoded: items)),
          ),
          RequestBodyType.graphql => Column(
            children: [
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorGraphQlQueryField,
                value: body.graphQl.query,
                label: 'Query',
                minLines: 8,
                maxLines: 12,
                onChanged: (value) => editorCubit.updateBody(
                  body.copyWith(graphQl: body.graphQl.copyWith(query: value)),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorGraphQlOperationNameField,
                value: body.graphQl.operationName,
                label: 'Operation Name',
                onChanged: (value) => editorCubit.updateBody(
                  body.copyWith(
                    graphQl: body.graphQl.copyWith(operationName: value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorGraphQlVariablesField,
                value: body.graphQl.variables,
                label: 'Variables',
                minLines: 6,
                maxLines: 10,
                onChanged: (value) => editorCubit.updateBody(
                  body.copyWith(
                    graphQl: body.graphQl.copyWith(variables: value),
                  ),
                ),
              ),
            ],
          ),
        },
      ],
    );
  }
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
        _EditorDropdownField<AuthType>(
          fieldKey: AppWidgetKeys.requestsEditorAuthTypeField,
          label: AppStrings.requestEditorType,
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
        const SizedBox(height: AppSpacing.small),
        switch (auth.type) {
          AuthType.none => const _InfoCard(
            message: 'No authentication will be applied.',
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
          AuthType.apiKey => Column(
            children: [
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField('api_key_name'),
                value: auth.apiKey.name,
                label: 'Key Name',
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    apiKey: ApiKeyAuthDraft(
                      name: value,
                      value: auth.apiKey.value,
                      location: auth.apiKey.location,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'api_key_value',
                ),
                value: auth.apiKey.value,
                label: 'Key Value',
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    apiKey: ApiKeyAuthDraft(
                      name: auth.apiKey.name,
                      value: value,
                      location: auth.apiKey.location,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorDropdownField<ApiKeyLocation>(
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'api_key_location',
                ),
                label: 'Location',
                value: auth.apiKey.location,
                items: ApiKeyLocation.values
                    .map(
                      (location) => DropdownMenuItem<ApiKeyLocation>(
                        value: location,
                        child: Text(location.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (location) {
                  if (location != null) {
                    editorCubit.updateAuth(
                      auth.copyWith(
                        apiKey: ApiKeyAuthDraft(
                          name: auth.apiKey.name,
                          value: auth.apiKey.value,
                          location: location,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          AuthType.bearerToken => Column(
            children: [
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'bearer_prefix',
                ),
                value: auth.bearerToken.prefix,
                label: 'Prefix',
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    bearerToken: BearerTokenAuthDraft(
                      token: auth.bearerToken.token,
                      prefix: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _EditorTextField(
                fieldKey: AppWidgetKeys.requestsEditorAuthField('bearer_token'),
                value: auth.bearerToken.token,
                label: 'Token',
                onChanged: (value) => editorCubit.updateAuth(
                  auth.copyWith(
                    bearerToken: BearerTokenAuthDraft(
                      token: value,
                      prefix: auth.bearerToken.prefix,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _ => const _InfoCard(
            message: AppStrings.requestEditorUnsupportedAuthMessage,
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
