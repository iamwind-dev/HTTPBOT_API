import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/app_popup_menu.dart';
import '../../../../injection/injection.dart';
import '../../../request_builder/domain/entities/api_key_auth_options.dart';
import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_body_draft.dart';
import '../../../request_builder/domain/entities/request_environment.dart';
import '../../../request_builder/domain/entities/request_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../../request_builder/domain/entities/request_variable_store.dart';
import '../../../request_builder/domain/entities/saved_credential.dart';
import '../../../request_builder/domain/helpers/auth_headers_updater.dart';
import '../../../request_builder/domain/helpers/api_key_auth_ui_sync.dart';
import '../../../request_builder/domain/helpers/aws_headers_updater.dart';
import '../../../request_builder/domain/helpers/oauth1_auth_ui_sync.dart';
import '../../../request_builder/domain/helpers/oauth2_auth_ui_sync.dart';
import '../../../request_builder/domain/helpers/jwt_auth_ui_sync.dart';
import '../../../request_builder/domain/helpers/request_auth_validator.dart';
import '../../../request_builder/domain/entities/requests_method.dart';
import '../../../request_builder/domain/usecases/apply_api_key_credential_to_auth_use_case.dart';
import '../../../request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import '../../../request_builder/domain/usecases/resolve_request_use_case.dart';
import '../../../request_builder/domain/usecases/save_request_variable_store_use_case.dart';
import '../../../request_builder/presentation/cubit/environment_menu_cubit.dart';
import '../../../request_builder/presentation/cubit/manage_credentials_cubit.dart';
import '../../../request_builder/presentation/cubit/manage_credentials_state.dart';
import '../../../request_builder/presentation/widgets/global_variables_sheet.dart';
import '../../../request_builder/presentation/widgets/manage_environments_sheet.dart';
import '../../../request_builder/presentation/widgets/oauth2_token_details_sheet.dart';
import '../../../request_builder/presentation/widgets/request_environment_menu.dart';
import '../../../request_builder/presentation/widgets/request_editor_sheet.dart';
import '../../../request_builder/presentation/widgets/request_modal_sheet.dart';
import '../../domain/entities/web_socket_request_entity.dart';
import '../../domain/entities/web_socket_settings_entity.dart';
import '../../domain/entities/web_socket_state_entity.dart';
import '../../domain/repositories/web_socket_client.dart';
import '../cubits/web_socket_cubit.dart';
import '../cubits/web_socket_list_cubit.dart';
import 'websocket_session_sheet.dart';

/// Opens the WebSocket editor sheet for a specific request.
Future<void> showWebSocketEditorSheet(
  BuildContext context, {
  required WebSocketRequestEntity request,
}) async {
  final websocketCubit = WebSocketCubit(
    client: getIt<WebSocketClient>(),
    loadVariableStore: getIt<GetRequestVariableStoreUseCase>().call,
  )..updateRequest(request);

  // Auto-update request in list cubit when it changes in editor
  final listCubit = context.read<WebSocketListCubit>();
  final subscription = websocketCubit.stream.listen((state) {
    listCubit.updateRequest(state.request);
  });

  await showRequestModalSheet<void>(
    context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider<WebSocketCubit>.value(value: websocketCubit),
        BlocProvider<WebSocketListCubit>.value(value: listCubit),
      ],
      child: const _WebSocketEditorSheet(),
    ),
  );

  await subscription.cancel();
  await websocketCubit.close();
}

class _WebSocketEditorSheet extends StatefulWidget {
  const _WebSocketEditorSheet();

  @override
  State<_WebSocketEditorSheet> createState() => _WebSocketEditorSheetState();
}

class _WebSocketEditorSheetState extends State<_WebSocketEditorSheet> {
  late final TextEditingController _urlController;
  late final EnvironmentMenuCubit _environmentMenuCubit = EnvironmentMenuCubit(
    getIt<GetRequestVariableStoreUseCase>(),
    getIt<SaveRequestVariableStoreUseCase>(),
  );

  RequestVariableStore get _variableStore => _environmentMenuCubit.state.store;

  @override
  void initState() {
    super.initState();
    final request = context.read<WebSocketCubit>().state.request;
    _urlController = TextEditingController(text: request.url);
  }

  @override
  void dispose() {
    unawaited(_environmentMenuCubit.close());
    _urlController.dispose();
    super.dispose();
  }

  /// Renders the editor from the current Cubit state and derived auth previews.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return BlocBuilder<WebSocketCubit, WebSocketStateEntity>(
      builder: (context, state) {
        if (_urlController.text != state.request.url) {
          _urlController.text = state.request.url;
        }

        final isConnecting =
            state.status == WebSocketConnectionStatus.connecting;
        final displayedHeaders = syncAuthorizationHeaderWithAuth(
          headers: state.request.headers,
          auth: state.request.auth,
        );
        final apiKeyPreview = syncApiKeyAuthToRequestFields(
          queryParameters: state.request.queryParameters,
          headers: displayedHeaders,
          auth: state.request.auth,
        );
        final oauth1Preview = syncOAuth1AuthToRequestFields(
          queryParameters: apiKeyPreview.queryParameters,
          headers: apiKeyPreview.headers,
          auth: _authWithoutWebSocketBodyHash(state.request.auth),
          method: HttpMethod.get,
          url: _webSocketOAuthPreviewUrl(state.request.url),
          body: const RequestBodyDraft.none(),
        );
        final oauth2Preview = syncOAuth2AuthToRequestFields(
          queryParameters: oauth1Preview.queryParameters,
          headers: oauth1Preview.headers,
          auth: state.request.auth,
        );
        final jwtPreview = syncJwtAuthToRequestFields(
          queryParameters: oauth2Preview.queryParameters,
          headers: oauth2Preview.headers,
          auth: state.request.auth,
        );
        final awsPreview = syncAwsAuthToRequestFields(
          queryParameters: jwtPreview.queryParameters,
          headers: jwtPreview.headers,
          auth: state.request.auth,
          method: HttpMethod.get,
          url: _webSocketOAuthPreviewUrl(state.request.url),
          body: const RequestBodyDraft.none(),
        );
        final hasAuthorizationOverride = _hasAuthorizationOverride(
          state.request.headers,
          state.request.auth,
        );

        return RequestModalSheetCard(
          child: Column(
            children: [
              _TopBar(
                requestName: state.request.name.isNotEmpty
                    ? state.request.name
                    : 'Untitled Request',
                onRename: (newName) {
                  context.read<WebSocketCubit>().updateRequest(
                    state.request.copyWith(name: newName),
                  );
                },
                onMoreMenuSelected: (value) => _handleMoreMenu(context, value),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.medium,
                    right: AppSpacing.medium,
                    top: AppSpacing.small,
                    bottom: AppSpacing.medium,
                  ),
                  children: [
                    _EditorCard(
                      child: TextField(
                        key: const ValueKey<String>(
                          AppWidgetKeys.websocketsUrlField,
                        ),
                        controller: _urlController,
                        enabled: !isConnecting,
                        decoration: const InputDecoration(
                          hintText: 'wss://',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: context.read<WebSocketCubit>().updateUrl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _SectionHeader(title: 'Query Params'),
                    _ParamsHeadersListCard(
                      items: awsPreview.queryParameters,
                      onChanged: context
                          .read<WebSocketCubit>()
                          .updateQueryParameters,
                      hintKey: 'Param Key',
                      hintVal: 'Param Value',
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _SectionHeader(title: 'Headers'),
                    _ParamsHeadersListCard(
                      items: awsPreview.headers,
                      onChanged: context.read<WebSocketCubit>().updateHeaders,
                      hintKey: 'Header Key',
                      hintVal: 'Header Value',
                    ),
                    if (hasAuthorizationOverride) ...[
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        'Explicit Authorization header overrides generated auth.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.medium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeader(title: 'Auth'),
                        IconButton(
                          onPressed: () => _showManageCredentials(context),
                          icon: Icon(
                            CupertinoIcons.ellipsis,
                            color: colors.primary,
                          ),
                          tooltip: 'Manage Credentials',
                        ),
                      ],
                    ),
                    _EditorCard(
                      child: ListTile(
                        key: const ValueKey<String>(
                          AppWidgetKeys.websocketsAuthTypeField,
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text('Auth', style: theme.textTheme.titleMedium),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _webSocketAuthLabel(state.request.auth.type),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxSmall),
                            Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: colors.primary,
                            ),
                          ],
                        ),
                        onTap: () =>
                            _showAuthPicker(context, state.request.auth),
                      ),
                    ),
                    if (state.request.auth.type != AuthType.none) ...[
                      const SizedBox(height: AppSpacing.small),
                      _AuthFieldsCard(
                        key: ValueKey<String>(
                          AppWidgetKeys.websocketsAuthFields(
                            state.request.auth.type.name,
                          ),
                        ),
                        auth: state.request.auth,
                        onChanged: context.read<WebSocketCubit>().updateAuth,
                        onConfigureOAuth2: () => unawaited(
                          _openOAuth2Configuration(
                            context,
                            state.request.auth.oauth2,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxLarge),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: FilledButton(
                      key: const ValueKey<String>(
                        AppWidgetKeys.websocketsConnectButton,
                      ),
                      onPressed: isConnecting
                          ? null
                          : () => unawaited(_openSession(context)),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.pill),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.large,
                        ),
                      ),
                      child: Text(
                        'Connect',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textOnPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Validates the visible draft before opening the auto-connect session sheet.
  Future<void> _openSession(BuildContext context) async {
    final error = _validateUrl(
      context.read<WebSocketCubit>().state.request.url,
    );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final draftAuth = context.read<WebSocketCubit>().state.request.auth;
    final authValidation = draftAuth.type == AuthType.jwt
        ? const RequestValidationResult.valid()
        : validateAuthBeforeSend(draftAuth);
    if (!authValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authValidation.errorMessage ?? 'Invalid authentication.',
          ),
        ),
      );
      return;
    }

    await _environmentMenuCubit.loadAvailableEnvironments();
    if (!context.mounted) {
      return;
    }

    final resolvedAuthValidation = _validateResolvedAuth(
      context.read<WebSocketCubit>().state.request,
    );
    if (!resolvedAuthValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolvedAuthValidation.errorMessage ?? 'Invalid authentication.',
          ),
        ),
      );
      return;
    }

    await showWebSocketSessionSheet(
      context,
      cubit: context.read<WebSocketCubit>(),
    );
  }

  /// Validates resolved auth placeholders before the session sheet is opened.
  RequestValidationResult _validateResolvedAuth(
    WebSocketRequestEntity request,
  ) {
    if (request.auth.type != AuthType.bearerToken &&
        request.auth.type != AuthType.jwt) {
      return const RequestValidationResult.valid();
    }

    final resolved = const ResolveRequestUseCase()(
      draft: RequestDraft(
        url: request.url,
        queryParameters: request.queryParameters,
        headers: request.headers,
        auth: request.auth,
      ),
      variableStore: _variableStore,
    );
    final validation = validateAuthBeforeSend(resolved.request.auth);
    if (!validation.isValid) {
      return validation;
    }

    if (request.auth.type == AuthType.bearerToken &&
        resolved.issues.any(
          (issue) => issue.source == 'auth.bearerToken.token',
        )) {
      return const RequestValidationResult.invalid('Bearer token is required.');
    }

    return const RequestValidationResult.valid();
  }

  /// Opens the shared OAuth2 flow and keeps WebSocket token-location preferences.
  Future<void> _openOAuth2Configuration(
    BuildContext context,
    OAuth2AuthDraft initialOauth2,
  ) async {
    final result = await showOAuth2ConfigurationSheet(
      context,
      initialOauth2: initialOauth2,
    );
    if (!context.mounted || result == null) {
      return;
    }

    final cubit = context.read<WebSocketCubit>();
    final currentAuth = cubit.state.request.auth;
    cubit.updateAuth(
      currentAuth.copyWith(
        oauth2: result.oauth2.copyWith(
          addTokenToHeader: currentAuth.oauth2.addTokenToHeader,
          headerPrefix: currentAuth.oauth2.headerPrefix,
        ),
      ),
    );

    final tokenDetails = result.tokenDetails;
    if (tokenDetails != null && context.mounted) {
      await showOAuth2TokenDetailsSheet(context, tokenDetails: tokenDetails);
    }
  }

  String? _validateUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return 'WebSocket URL is required.';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
      return 'WebSocket URL must start with ws:// or wss://.';
    }

    return null;
  }

  void _showAuthPicker(BuildContext context, RequestAuthDraft currentAuth) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Select Authentication Method',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _webSocketAuthTypes
                      .map(
                        (type) => ListTile(
                          title: Text(_webSocketAuthLabel(type)),
                          trailing: currentAuth.type == type
                              ? Icon(
                                  Icons.check,
                                  color: context.appColors.primary,
                                )
                              : null,
                          onTap: () {
                            context.read<WebSocketCubit>().updateAuth(
                              currentAuth.copyWith(type: type),
                            );
                            Navigator.pop(sheetContext);
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens a compact saved-credentials popover for applying API key auth.
  void _showManageCredentials(BuildContext context) {
    final websocketCubit = context.read<WebSocketCubit>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider<WebSocketCubit>.value(value: websocketCubit),
          BlocProvider<ManageCredentialsCubit>(
            create: (_) => getIt<ManageCredentialsCubit>()..load(),
          ),
        ],
        child: const _ManageCredentialsDialog(),
      ),
    );
  }

  void _handleMoreMenu(BuildContext context, String value) {
    final cubit = context.read<WebSocketCubit>();
    switch (value) {
      case 'environment':
        unawaited(_openEnvironmentMenu());
      case 'certificates':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificates are not implemented yet.'),
          ),
        );
      case 'settings':
        _showSettingsSheet(context, cubit);
      case 'help':
        _showHelpSheet(context);
      case 'clear':
        _confirmClear(context, cubit);
    }
  }

  /// Opens the shared Environment menu used by the HTTP request editor.
  Future<void> _openEnvironmentMenu() async {
    await _environmentMenuCubit.loadAvailableEnvironments();
    if (!mounted) {
      return;
    }

    final selection = await showRequestEnvironmentMenu(
      context,
      store: _variableStore,
    );
    if (!mounted || selection == null) {
      return;
    }

    switch (selection.action) {
      case RequestEnvironmentMenuAction.globalVariables:
        await _openGlobalVariables();
      case RequestEnvironmentMenuAction.manageEnvironments:
        await showManageEnvironmentsSheet(
          context,
          cubit: _environmentMenuCubit,
        );
      case RequestEnvironmentMenuAction.deactivate:
        await _environmentMenuCubit.deactivateEnvironment();
      case RequestEnvironmentMenuAction.select:
        await _environmentMenuCubit.selectEnvironment(selection.environmentId);
      case RequestEnvironmentMenuAction.edit:
        await _editEnvironment(selection.environmentId);
    }
  }

  Future<void> _openGlobalVariables() async {
    final savedVariables = await showGlobalVariablesSheet(
      context,
      variables: _variableStore.globalVariables,
    );
    if (savedVariables == null) {
      return;
    }

    await _environmentMenuCubit.saveGlobalVariables(savedVariables);
  }

  Future<void> _editEnvironment(String environmentId) async {
    RequestEnvironment? environment;
    for (final item in _variableStore.environments) {
      if (item.id == environmentId) {
        environment = item;
        break;
      }
    }
    if (environment == null) {
      return;
    }

    final result = await showEnvironmentEditorSheet(
      context,
      environment: environment,
      allowDelete: true,
    );
    if (result == null) {
      return;
    }

    final environments = result.deleted
        ? _variableStore.environments
              .where((item) => item.id != environmentId)
              .toList(growable: false)
        : _variableStore.environments
              .map(
                (item) => item.id == environmentId ? result.environment! : item,
              )
              .toList(growable: false);
    await _environmentMenuCubit.saveEnvironments(environments);
  }

  void _showSettingsSheet(BuildContext context, WebSocketCubit cubit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (sheetContext) {
        return BlocProvider<WebSocketCubit>.value(
          value: cubit,
          child: const _WebSocketSettingsSheet(),
        );
      },
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WebSocket Client Help',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.medium),
                const Text(
                  'WebSockets facilitate real-time, bi-directional communication between a client and a server.',
                ),
                const SizedBox(height: AppSpacing.small),
                const Text(
                  'Enter a wss:// or ws:// URL, add headers or query parameters if required by the server, and click Connect.',
                ),
                const SizedBox(height: AppSpacing.large),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context, WebSocketCubit cubit) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Editor?'),
          content: const Text(
            'This will reset the URL, params, headers, and authentication parameters.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cubit.updateRequest(
                  cubit.state.request.copyWith(
                    url: 'wss://',
                    queryParameters: const [],
                    headers: const [],
                    auth: const RequestAuthDraft.none(),
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Clear',
                style: TextStyle(color: context.appColors.methodDelete),
              ),
            ),
          ],
        );
      },
    );
  }
}

const _webSocketAuthTypes = <AuthType>[
  AuthType.none,
  AuthType.basic,
  AuthType.oauth1,
  AuthType.oauth2,
  AuthType.apiKey,
  AuthType.bearerToken,
  AuthType.digest,
  AuthType.hawk,
  AuthType.jwt,
  AuthType.ntlm,
  AuthType.awsSignature,
];

/// Returns WebSocket auth labels matching the request auth picker copy.
String _webSocketAuthLabel(AuthType type) {
  if (type == AuthType.awsSignature) {
    return 'AWS';
  }
  return type.label;
}

/// Returns true when an enabled manual Authorization row suppresses generated auth.
bool _hasAuthorizationOverride(
  List<KeyValueItem> headers,
  RequestAuthDraft auth,
) =>
    (auth.type == AuthType.basic ||
        auth.type == AuthType.bearerToken ||
        auth.type == AuthType.hawk) &&
    headers.any(
      (header) =>
          header.isEnabled &&
          header.key.trim().toLowerCase() == 'authorization' &&
          !header.isBasicAuthSystemGeneratedHeader &&
          !header.isBearerTokenSystemGeneratedHeader &&
          !header.isSystemGeneratedHawkHeader,
    );

/// Disables OAuth body hash for the bodyless WebSocket preview.
RequestAuthDraft _authWithoutWebSocketBodyHash(RequestAuthDraft auth) {
  if (auth.type != AuthType.oauth1 || !auth.oauth1.includeBodyHash) {
    return auth;
  }

  return auth.copyWith(oauth1: auth.oauth1.copyWith(includeBodyHash: false));
}

/// Converts ws/wss URLs to the HTTP scheme used by OAuth signing previews.
String _webSocketOAuthPreviewUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return url;
  }
  if (uri.scheme == 'wss') {
    return uri.replace(scheme: 'https').toString();
  }
  if (uri.scheme == 'ws') {
    return uri.replace(scheme: 'http').toString();
  }
  return url;
}

class _AuthFieldsCard extends StatelessWidget {
  /// Creates the auth field subtree for one stable authentication mode.
  const _AuthFieldsCard({
    super.key,
    required this.auth,
    required this.onChanged,
    required this.onConfigureOAuth2,
  });

  final RequestAuthDraft auth;
  final ValueChanged<RequestAuthDraft> onChanged;
  final VoidCallback onConfigureOAuth2;

  static const List<String> _oauth1SignatureMethods = <String>[
    'HMAC-SHA1',
    'HMAC-SHA256',
    'HMAC-SHA512',
    'RSA-SHA1',
    'RSA-SHA256',
    'RSA-SHA512',
    'PLAINTEXT',
  ];

  /// Renders fields for the selected WebSocket auth mode.
  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Column(
        children: switch (auth.type) {
          AuthType.basic => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsBasicUsernameField,
              label: 'Username',
              value: auth.basic.username,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  basic: BasicAuthDraft(
                    username: value,
                    password: auth.basic.password,
                  ),
                ),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsBasicPasswordField,
              label: 'Password',
              value: auth.basic.password,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  basic: BasicAuthDraft(
                    username: auth.basic.username,
                    password: value,
                  ),
                ),
              ),
            ),
          ],
          AuthType.apiKey => [
            _ApiKeyAuthFields(auth: auth, onChanged: onChanged),
          ],
          AuthType.bearerToken => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('bearer_token'),
              label: 'Token',
              hintText: 'Enter Value',
              value: auth.bearerToken.token,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  bearerToken: BearerTokenAuthDraft(
                    token: value,
                    prefix: auth.bearerToken.prefix,
                  ),
                ),
              ),
            ),
          ],
          AuthType.oauth2 => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField(
                'oauth2_access_token',
              ),
              label: 'Token',
              value: auth.oauth2.accessToken,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth2: auth.oauth2.copyWith(accessToken: value)),
              ),
            ),
            _AuthSwitchRow(
              label: 'As Header',
              value: auth.oauth2.addTokenToHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth2: auth.oauth2.copyWith(addTokenToHeader: value),
                ),
              ),
            ),
            if (auth.oauth2.addTokenToHeader)
              _AuthTextField(
                fieldKey: AppWidgetKeys.websocketsAuthField(
                  'oauth2_header_prefix',
                ),
                label: 'Header Prefix',
                value: auth.oauth2.headerPrefix,
                onChanged: (value) => onChanged(
                  auth.copyWith(
                    oauth2: auth.oauth2.copyWith(headerPrefix: value),
                  ),
                ),
              ),
            ListTile(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsEditorOAuth2ConfigureButton,
              ),
              contentPadding: EdgeInsets.zero,
              title: const Text('Configure'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(auth.oauth2.grantType.label),
                  const SizedBox(width: AppSpacing.small),
                  const Icon(CupertinoIcons.chevron_right),
                ],
              ),
              onTap: onConfigureOAuth2,
            ),
          ],
          AuthType.jwt => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('jwt_header'),
              label: 'Header',
              value: auth.jwt.header,
              hintText: 'Enter Value',
              maxLines: 3,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(header: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('jwt_payload'),
              label: 'Payload',
              value: auth.jwt.payload,
              hintText: 'Enter Value',
              maxLines: 3,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(payload: value)),
              ),
            ),
            _AuthDropdown<JwtAlgorithm>(
              fieldKey: AppWidgetKeys.websocketsAuthField('jwt_algorithm'),
              label: 'Algorithm',
              value: auth.jwt.selectedAlgorithm,
              values: JwtAlgorithm.values,
              labelFor: (value) => value.label,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(algorithm: value.label)),
              ),
            ),
            if (auth.jwt.isHmacAlgorithm) ...[
              _AuthSwitchRow(
                fieldKey: AppWidgetKeys.websocketsAuthField(
                  'jwt_base64_encoded_secret',
                ),
                label: 'Base64 Encoded Secret',
                value: auth.jwt.base64EncodedSecret,
                onChanged: (value) => onChanged(
                  auth.copyWith(
                    jwt: auth.jwt.copyWith(base64EncodedSecret: value),
                  ),
                ),
              ),
              _AuthTextField(
                fieldKey: AppWidgetKeys.websocketsAuthField('jwt_secret'),
                label: 'Secret',
                value: auth.jwt.secret,
                obscureText: true,
                hintText: 'Enter Value',
                onChanged: (value) => onChanged(
                  auth.copyWith(jwt: auth.jwt.copyWith(secret: value)),
                ),
              ),
            ] else
              _AuthTextField(
                fieldKey: AppWidgetKeys.websocketsAuthField('jwt_private_key'),
                label: 'Private Key',
                value: auth.jwt.privateKey,
                hintText: 'Enter Value',
                maxLines: 5,
                onChanged: (value) => onChanged(
                  auth.copyWith(jwt: auth.jwt.copyWith(privateKey: value)),
                ),
              ),
            _AuthSwitchRow(
              fieldKey: AppWidgetKeys.websocketsAuthField('jwt_send_as_header'),
              label: 'Send as Header',
              value: auth.jwt.sendAsHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(sendAsHeader: value)),
              ),
            ),
            if (auth.jwt.sendAsHeader)
              _AuthTextField(
                fieldKey: AppWidgetKeys.websocketsAuthField(
                  'jwt_header_prefix',
                ),
                label: 'Header Prefix',
                value: auth.jwt.prefix,
                hintText: 'Bearer',
                onChanged: (value) => onChanged(
                  auth.copyWith(jwt: auth.jwt.copyWith(prefix: value)),
                ),
              ),
          ],
          AuthType.oauth1 => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField(
                'oauth1_consumer_key',
              ),
              label: 'Consumer Key',
              value: auth.oauth1.consumerKey,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(consumerKey: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField(
                'oauth1_consumer_secret',
              ),
              label: 'Consumer Secret',
              value: auth.oauth1.consumerSecret,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth1: auth.oauth1.copyWith(consumerSecret: value),
                ),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_token'),
              label: 'Token',
              value: auth.oauth1.token,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(token: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField(
                'oauth1_token_secret',
              ),
              label: 'Token Secret',
              value: auth.oauth1.tokenSecret,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(tokenSecret: value)),
              ),
            ),
            _AuthDropdown<String>(
              label: 'Signature Method',
              value: auth.oauth1.signatureMethod,
              values: _oauth1SignatureMethods,
              labelFor: (value) => value,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth1: auth.oauth1.copyWith(signatureMethod: value),
                ),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_verifier'),
              label: 'Verifier',
              value: auth.oauth1.verifier,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(verifier: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_callback'),
              label: 'Callback',
              value: auth.oauth1.callback,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(callback: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_timestamp'),
              label: 'Timestamp',
              value: auth.oauth1.timestamp,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(timestamp: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_nonce'),
              label: 'Nonce',
              value: auth.oauth1.nonce,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(nonce: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_version'),
              label: 'Version',
              value: auth.oauth1.version,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(version: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('oauth1_realm'),
              label: 'Realm',
              value: auth.oauth1.realm,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(realm: value)),
              ),
            ),
            _AuthSwitchRow(
              label: 'As Header',
              value: auth.oauth1.asHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(asHeader: value)),
              ),
            ),
            _AuthSwitchRow(
              label: 'Include Body Hash',
              value: auth.oauth1.includeBodyHash,
              enabled: false,
              helperText:
                  'Body hash is not supported for WebSocket handshakes yet.',
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth1: auth.oauth1.copyWith(includeBodyHash: value),
                ),
              ),
            ),
            _AuthSwitchRow(
              label: 'Encode Signature',
              value: auth.oauth1.encodeSignature,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth1: auth.oauth1.copyWith(encodeSignature: value),
                ),
              ),
            ),
            _AuthSwitchRow(
              label: 'Include Empty Parameters',
              value: auth.oauth1.includeEmptyParameters,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth1: auth.oauth1.copyWith(includeEmptyParameters: value),
                ),
              ),
            ),
          ],
          AuthType.hawk => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_auth_id'),
              label: 'Auth ID',
              value: auth.hawk.identifier,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(identifier: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_auth_key'),
              label: 'Auth Key',
              value: auth.hawk.key,
              obscureText: true,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(key: value)),
              ),
            ),
            _AuthDropdown<HawkAlgorithm>(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_algorithm'),
              label: 'Algorithm',
              value: auth.hawk.selectedAlgorithm,
              values: HawkAlgorithm.values,
              labelFor: (value) => value.label,
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(algorithm: value.name)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_user'),
              label: 'User',
              value: auth.hawk.user,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(user: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_nonce'),
              label: 'Nonce',
              value: auth.hawk.nonce,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(nonce: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_ext'),
              label: 'Ext',
              value: auth.hawk.ext,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(ext: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_app'),
              label: 'App',
              value: auth.hawk.app,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(app: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_dlg'),
              label: 'Dlg',
              value: auth.hawk.delegation,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(delegation: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('hawk_timestamp'),
              label: 'Timestamp',
              value: auth.hawk.timestamp,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(timestamp: value)),
              ),
            ),
            _AuthSwitchRow(
              fieldKey: AppWidgetKeys.websocketsAuthField(
                'hawk_include_payload_hash',
              ),
              label: 'Include Payload Hash',
              value: auth.hawk.includePayloadHash,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  hawk: auth.hawk.copyWith(includePayloadHash: value),
                ),
              ),
            ),
          ],
          AuthType.digest => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_username'),
              label: 'Username',
              value: auth.digest.username,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(username: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_password'),
              label: 'Password',
              value: auth.digest.password,
              obscureText: true,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(password: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_realm'),
              label: 'Realm',
              value: auth.digest.realm,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(realm: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_nonce'),
              label: 'Nonce',
              value: auth.digest.nonce,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(nonce: value)),
              ),
            ),
            _AuthDropdown<DigestAlgorithm>(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_algorithm'),
              label: 'Algorithm',
              value: auth.digest.selectedAlgorithm,
              values: DigestAlgorithm.values,
              labelFor: (value) => value.label,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  digest: auth.digest.copyWith(algorithm: value.label),
                ),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_qop'),
              label: 'QOP',
              value: auth.digest.qop,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(qop: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_nonce_count'),
              label: 'Nonce Count',
              value: auth.digest.nonceCount,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(nonceCount: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField(
                'digest_client_nonce',
              ),
              label: 'Client Nonce',
              value: auth.digest.clientNonce,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(clientNonce: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('digest_opaque'),
              label: 'Opaque',
              value: auth.digest.opaque,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(opaque: value)),
              ),
            ),
          ],
          AuthType.awsSignature => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('aws_access_key'),
              label: 'Access Key',
              hintText: 'Enter Value',
              value: auth.aws.accessKey,
              onChanged: (value) => onChanged(
                auth.copyWith(aws: auth.aws.copyWith(accessKey: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('aws_secret_key'),
              label: 'Secret Key',
              hintText: 'Enter Value',
              value: auth.aws.secretKey,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(aws: auth.aws.copyWith(secretKey: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('aws_region'),
              label: 'Region',
              hintText: 'Enter Value',
              value: auth.aws.region,
              onChanged: (value) => onChanged(
                auth.copyWith(aws: auth.aws.copyWith(region: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('aws_service'),
              label: 'Service',
              hintText: 'Enter Value',
              value: auth.aws.service,
              onChanged: (value) => onChanged(
                auth.copyWith(aws: auth.aws.copyWith(service: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('aws_session_token'),
              label: 'Session Token',
              hintText: 'Enter Value',
              value: auth.aws.sessionToken,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(aws: auth.aws.copyWith(sessionToken: value)),
              ),
            ),
            _AuthSwitchRow(
              fieldKey: AppWidgetKeys.websocketsAuthField('aws_as_header'),
              label: 'As Header',
              value: auth.aws.asHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(aws: auth.aws.copyWith(asHeader: value)),
              ),
            ),
          ],
          AuthType.ntlm => [
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('ntlm_username'),
              label: 'Username',
              value: auth.ntlm.username,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(username: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('ntlm_password'),
              label: 'Password',
              value: auth.ntlm.password,
              obscureText: true,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(password: value)),
              ),
            ),
            _AuthTextField(
              fieldKey: AppWidgetKeys.websocketsAuthField('ntlm_domain'),
              label: 'Domain',
              value: auth.ntlm.domain,
              hintText: 'Enter Value',
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(domain: value)),
              ),
            ),
          ],
          AuthType.none => const <Widget>[],
        },
      ),
    );
  }
}

class _ApiKeyAuthFields extends StatelessWidget {
  /// Creates API Key controls backed by the shared auth draft.
  const _ApiKeyAuthFields({required this.auth, required this.onChanged});

  final RequestAuthDraft auth;
  final ValueChanged<RequestAuthDraft> onChanged;

  /// Returns true when the editor must show the custom-name field.
  bool get _isCustom =>
      auth.apiKey.isCustomName || !apiKeyNamePresets.contains(auth.apiKey.name);

  /// Renders preset/custom name, secure value, and placement controls.
  @override
  Widget build(BuildContext context) {
    final apiKey = auth.apiKey;

    return Column(
      children: [
        _AuthDropdown<String>(
          fieldKey: AppWidgetKeys.websocketsAuthField('api_key_name'),
          label: 'Key Name',
          value: _isCustom ? apiKeyCustomNameSentinel : apiKey.name,
          values: <String>[...apiKeyNamePresets, apiKeyCustomNameSentinel],
          labelFor: (value) =>
              value == apiKeyCustomNameSentinel ? 'Custom' : value,
          onChanged: (value) {
            final isCustomName = value == apiKeyCustomNameSentinel;
            onChanged(
              auth.copyWith(
                apiKey: ApiKeyAuthDraft(
                  name: isCustomName ? '' : value,
                  value: apiKey.value,
                  location: apiKey.location,
                  isCustomName: isCustomName,
                ),
              ),
            );
          },
        ),
        if (_isCustom)
          _AuthTextField(
            fieldKey: AppWidgetKeys.websocketsAuthField('api_key_custom_name'),
            label: 'Custom Key Name',
            value: apiKey.name,
            onChanged: (value) => onChanged(
              auth.copyWith(
                apiKey: ApiKeyAuthDraft(
                  name: value,
                  value: apiKey.value,
                  location: apiKey.location,
                  isCustomName: true,
                ),
              ),
            ),
          ),
        _AuthTextField(
          fieldKey: AppWidgetKeys.websocketsAuthField('api_key_value'),
          label: 'Value',
          value: apiKey.value,
          obscureText: true,
          onChanged: (value) => onChanged(
            auth.copyWith(
              apiKey: ApiKeyAuthDraft(
                name: apiKey.name,
                value: value,
                location: apiKey.location,
                isCustomName: apiKey.isCustomName,
              ),
            ),
          ),
        ),
        _AuthSwitchRow(
          fieldKey: AppWidgetKeys.websocketsAuthField('api_key_send_as_header'),
          label: 'Send as Header',
          value: apiKey.location == ApiKeyLocation.header,
          onChanged: (value) => onChanged(
            auth.copyWith(
              apiKey: ApiKeyAuthDraft(
                name: apiKey.name,
                value: apiKey.value,
                location: value ? ApiKeyLocation.header : ApiKeyLocation.query,
                isCustomName: apiKey.isCustomName,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.obscureText = false,
    this.hintText,
    this.maxLines = 1,
  });

  final String? fieldKey;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final String? hintText;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey == null ? null : ValueKey<String>(fieldKey!),
      initialValue: value,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: InputBorder.none,
      ),
      onChanged: onChanged,
    );
  }
}

class _AuthDropdown<T> extends StatelessWidget {
  /// Creates a labeled auth selector with an optional stable widget key.
  const _AuthDropdown({
    this.fieldKey,
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String? fieldKey;
  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  /// Renders the dropdown while forwarding non-null selections.
  @override
  Widget build(BuildContext context) {
    final resolvedFieldKey = fieldKey;
    return DropdownButtonFormField<T>(
      key: resolvedFieldKey == null ? null : ValueKey<String>(resolvedFieldKey),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: InputBorder.none),
      items: values
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _AuthSwitchRow extends StatelessWidget {
  /// Creates a labeled auth switch with an optional stable widget key.
  const _AuthSwitchRow({
    this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.helperText,
  });

  final String? fieldKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? helperText;

  /// Renders the adaptive switch and optional helper text.
  @override
  Widget build(BuildContext context) {
    final resolvedFieldKey = fieldKey;
    return SwitchListTile.adaptive(
      key: resolvedFieldKey == null ? null : ValueKey<String>(resolvedFieldKey),
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: helperText == null ? null : Text(helperText!),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _ManageCredentialsDialog extends StatelessWidget {
  const _ManageCredentialsDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: BlocBuilder<ManageCredentialsCubit, ManageCredentialsState>(
            builder: (context, state) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Credentials',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Divider(color: colors.divider),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Saved Credentials',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                _CredentialsDialogBody(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialsDialogBody extends StatelessWidget {
  const _CredentialsDialogBody({required this.state});

  final ManageCredentialsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (state.status == ManageCredentialsStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (state.credentials.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
        child: Center(
          child: Text(
            'No Saved Credentials',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: state.credentials.length,
        separatorBuilder: (context, index) => Divider(color: colors.divider),
        itemBuilder: (context, index) =>
            _CredentialDialogRow(credential: state.credentials[index]),
      ),
    );
  }
}

class _CredentialDialogRow extends StatelessWidget {
  const _CredentialDialogRow({required this.credential});

  final SavedCredential credential;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        credential.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        credential.type.label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
      onTap: () => _applyCredential(context),
    );
  }

  /// Applies a saved API key credential to the active WebSocket auth draft.
  void _applyCredential(BuildContext context) {
    const applyUseCase = ApplyApiKeyCredentialToAuthUseCase();
    final cubit = context.read<WebSocketCubit>();
    cubit.updateAuth(applyUseCase(cubit.state.request.auth, credential));
    Navigator.of(context).pop();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.requestName,
    required this.onRename,
    required this.onMoreMenuSelected,
  });

  final String requestName;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onMoreMenuSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.surfaceMuted,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kMinInteractiveDimension,
              ),
              child: GestureDetector(
                onTap: () => _showRenameDialog(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        requestName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxSmall),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: colors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.surfaceMuted,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 16,
                    color: colors.textPrimary,
                  ),
                ),
                offset: const Offset(0, 48),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.medium),
                  ),
                ),
                color: colors.card,
                onSelected: onMoreMenuSelected,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'environment',
                    child: const AppPopupMenuRow(
                      icon: CupertinoIcons.globe,
                      label: 'Environment',
                      trailing: Icon(CupertinoIcons.chevron_right, size: 14),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'certificates',
                    child: AppPopupMenuRow(
                      icon: CupertinoIcons.shield,
                      label: 'Certificates',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: AppPopupMenuRow(
                      icon: CupertinoIcons.settings,
                      label: 'Settings',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'help',
                    child: AppPopupMenuRow(
                      icon: CupertinoIcons.question_circle,
                      label: 'Help',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear',
                    child: AppPopupMenuRow(
                      icon: CupertinoIcons.trash,
                      label: 'Clear',
                      destructive: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: requestName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Request'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                onRename(name.isNotEmpty ? name : 'Untitled Request');
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.card,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xxSmall,
        bottom: AppSpacing.xSmall,
        top: AppSpacing.small,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ParamsHeadersListCard extends StatelessWidget {
  const _ParamsHeadersListCard({
    required this.items,
    required this.onChanged,
    required this.hintKey,
    required this.hintVal,
  });

  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>> onChanged;
  final String hintKey;
  final String hintVal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _EditorCard(
      child: Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final generatedLabel = item.systemGeneratedHeaderLabel;
            final generatedRowLabel =
                generatedLabel ??
                (item.isSystemGeneratedOAuth1QueryParameter
                    ? 'OAuth 1.0a'
                    : item.isSystemGeneratedOAuth2QueryParameter
                    ? 'OAuth 2.0'
                    : item.isSystemGeneratedApiKeyQueryParameter
                    ? 'API Key'
                    : null);
            final isGeneratedAuth = generatedRowLabel != null;
            return Padding(
              key: ValueKey(idx),
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isEnabled,
                    onChanged: isGeneratedAuth
                        ? null
                        : (val) {
                            final updated = List<KeyValueItem>.from(items);
                            updated[idx] = item.copyWith(
                              isEnabled: val ?? true,
                            );
                            onChanged(updated);
                          },
                  ),
                  Expanded(
                    child: TextFormField(
                      readOnly: isGeneratedAuth,
                      initialValue: item.key,
                      decoration: InputDecoration(
                        hintText: hintKey,
                        border: InputBorder.none,
                      ),
                      onChanged: isGeneratedAuth
                          ? null
                          : (val) {
                              final updated = List<KeyValueItem>.from(items);
                              updated[idx] = item.copyWith(key: val);
                              onChanged(updated);
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: TextFormField(
                      readOnly: isGeneratedAuth,
                      initialValue: item.value,
                      decoration: InputDecoration(
                        hintText: hintVal,
                        border: InputBorder.none,
                      ),
                      onChanged: isGeneratedAuth
                          ? null
                          : (val) {
                              final updated = List<KeyValueItem>.from(items);
                              updated[idx] = item.copyWith(value: val);
                              onChanged(updated);
                            },
                    ),
                  ),
                  isGeneratedAuth
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                          ),
                          child: Text(
                            generatedRowLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            final updated = List<KeyValueItem>.from(items)
                              ..removeAt(idx);
                            onChanged(updated);
                          },
                          icon: Icon(
                            CupertinoIcons.trash,
                            color: colors.methodDelete,
                            size: 20,
                          ),
                        ),
                ],
              ),
            );
          }),
          // Add Row
          InkWell(
            onTap: () {
              onChanged([...items, const KeyValueItem(key: '', value: '')]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.plus_circle_fill,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSocketSettingsSheet extends StatefulWidget {
  const _WebSocketSettingsSheet();

  @override
  State<_WebSocketSettingsSheet> createState() =>
      _WebSocketSettingsSheetState();
}

class _WebSocketSettingsSheetState extends State<_WebSocketSettingsSheet> {
  late final TextEditingController _timeoutController;
  late bool _verifySsl;

  @override
  void initState() {
    super.initState();
    final settings = context.read<WebSocketCubit>().state.request.settings;
    _timeoutController = TextEditingController(
      text: settings.handshakeTimeoutSeconds.toString(),
    );
    _verifySsl = settings.verifySsl;
  }

  @override
  void dispose() {
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'WebSocket Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _timeoutController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Handshake Timeout Interval in Seconds',
                  hintText: '30',
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Verify SSL'),
                  Switch.adaptive(
                    value: _verifySsl,
                    onChanged: (val) {
                      setState(() {
                        _verifySsl = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              ElevatedButton(
                onPressed: () {
                  final seconds = int.tryParse(_timeoutController.text) ?? 30;
                  context.read<WebSocketCubit>().updateSettings(
                    WebSocketSettingsEntity(
                      handshakeTimeoutSeconds: seconds,
                      verifySsl: _verifySsl,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
