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
import 'request_modal_sheet.dart';
import 'request_response_sheet.dart';

/// Presents the request editor as a full-screen sheet backed by a real request draft.
Future<void> showRequestEditorSheet(
  BuildContext context, {
  required String title,
  required RequestDraft initialDraft,
  required RequestVariableStore variableStore,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            RequestEditorCubit(title: title, initialDraft: initialDraft),
      ),
      BlocProvider(create: (_) => getIt<RequestSendBloc>()),
    ],
    child: _RequestEditorSheet(variableStore: variableStore),
  ),
);

class _RequestEditorSheet extends StatefulWidget {
  const _RequestEditorSheet({required this.variableStore});

  final RequestVariableStore variableStore;

  @override
  State<_RequestEditorSheet> createState() => _RequestEditorSheetState();
}

class _RequestEditorSheetState extends State<_RequestEditorSheet> {
  RequestEditorResponseBadgeData? _lastResponseBadge;

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

  /// Builds the request editor shell while binding the visible controls to cubit state.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsEditorSheet),
    child: BlocBuilder<RequestEditorCubit, RequestEditorState>(
      builder: (context, state) {
        final draft = state.draft;
        final responseBadge = _lastResponseBadge;

        return Column(
          children: [
            const SizedBox(height: AppSpacing.small),
            const _SheetHandle(),
            _EditorHeader(title: state.title, method: draft.method.label),
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
                    _RequestBasicsSection(draft: draft),
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
        );
      },
    ),
  );
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
  const _EditorHeader({required this.title, required this.method});

  final String title;
  final String method;

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
            key: const ValueKey<String>(AppWidgetKeys.requestsEditorCloseButton),
            tooltip: AppStrings.requestEditorCloseTooltip,
            onPressed: () => Navigator.of(context).pop(),
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
                _MethodBadge(method: method),
                Text(title, style: theme.textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  /// Shows the request method using the shared request-method palette.
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.medium,
      vertical: AppSpacing.xSmall,
    ),
    decoration: BoxDecoration(
      color: context.appColors.methodColor(method),
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
    ),
    child: Text(method, style: Theme.of(context).textTheme.labelMedium),
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
    ).textTheme.titleLarge?.copyWith(color: context.appColors.textSecondary),
  );
}

class _RequestBasicsSection extends StatelessWidget {
  const _RequestBasicsSection({required this.draft});

  final RequestDraft draft;

  /// Builds the method selector and URL editor for the current request draft.
  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<RequestEditorCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorSectionTitle(title: AppStrings.requestEditorMethod),
        const SizedBox(height: AppSpacing.small),
        _EditorDropdownField<HttpMethod>(
          fieldKey: AppWidgetKeys.requestsEditorMethodField,
          label: AppStrings.requestEditorMethod,
          value: draft.method,
          items: HttpMethod.values
              .map(
                (method) => DropdownMenuItem<HttpMethod>(
                  value: method,
                  child: Text(method.wireName),
                ),
              )
              .toList(growable: false),
          onChanged: (method) {
            if (method != null) {
              editorCubit.updateMethod(method);
            }
          },
        ),
        const SizedBox(height: AppSpacing.small),
        _EditorTextField(
          fieldKey: AppWidgetKeys.requestsEditorUrlField,
          value: draft.url,
          label: 'URL',
          hintText: 'https://api.example.com/users/{{user_id}}',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onChanged: editorCubit.updateUrl,
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
      for (var index = 0; index < items.length; index++) ...[
        _KeyValueRow(
          sectionId: sectionId,
          index: index,
          item: items[index],
          onChanged: (item) => _replace(context, index, item),
          onRemove: () => _remove(context, index),
        ),
        const SizedBox(height: AppSpacing.small),
      ],
      _AddRowCard(
        sectionId: sectionId,
        onPressed: () => _appendEmptyItem(context),
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

  /// Removes one row from the current key-value collection.
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

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.sectionId,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final String sectionId;
  final int index;
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onChanged;
  final VoidCallback onRemove;

  /// Renders one editable key-value row with enable, edit, and remove controls.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: Center(
              child: Checkbox.adaptive(
                key: ValueKey<String>(
                  AppWidgetKeys.requestsEditorKeyValueToggle(sectionId, index),
                ),
                value: item.isEnabled,
                onChanged: (value) =>
                    onChanged(item.copyWith(isEnabled: value ?? false)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xSmall),
          Expanded(
            child: _EditorTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueKeyField(
                sectionId,
                index,
              ),
              value: item.key,
              label: 'Key',
              onChanged: (value) => onChanged(item.copyWith(key: value)),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: _EditorTextField(
              fieldKey: AppWidgetKeys.requestsEditorKeyValueValueField(
                sectionId,
                index,
              ),
              value: item.value,
              label: 'Value',
              onChanged: (value) => onChanged(item.copyWith(value: value)),
            ),
          ),
          const SizedBox(width: AppSpacing.xSmall),
          IconButton(
            key: ValueKey<String>(
              AppWidgetKeys.requestsEditorKeyValueRemoveButton(
                sectionId,
                index,
              ),
            ),
            tooltip: 'Remove row',
            onPressed: onRemove,
            icon: const Icon(CupertinoIcons.delete_simple),
          ),
        ],
      ),
    ),
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
                  body.copyWith(
                    graphQl: body.graphQl.copyWith(query: value),
                  ),
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
                fieldKey: AppWidgetKeys.requestsEditorAuthField(
                  'bearer_token',
                ),
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
  const _SendButton({
    required this.onPressed,
    this.isLoading = false,
  });

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
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
    value: value,
    items: items,
    onChanged: onChanged,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    decoration: _buildFieldDecoration(
      context,
      label: label,
    ),
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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
      ),
    ),
  );
}

class _AddRowCard extends StatelessWidget {
  const _AddRowCard({
    required this.sectionId,
    required this.onPressed,
  });

  final String sectionId;
  final VoidCallback onPressed;

  /// Shows the compact add-row affordance used by dynamic key-value sections.
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
                Icon(
                  CupertinoIcons.add_circled_solid,
                  color: colors.navActive,
                  size: AppSpacing.large,
                ),
                const SizedBox(width: AppSpacing.medium),
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
      ),
    );
  }
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
