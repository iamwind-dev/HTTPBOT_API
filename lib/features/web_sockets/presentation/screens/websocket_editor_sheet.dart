import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_environment.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../../request_builder/domain/entities/request_variable_store.dart';
import '../../../request_builder/domain/entities/saved_credential.dart';
import '../../../request_builder/domain/usecases/apply_api_key_credential_to_auth_use_case.dart';
import '../../../request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import '../../../request_builder/domain/usecases/save_request_variable_store_use_case.dart';
import '../../../request_builder/presentation/cubit/environment_menu_cubit.dart';
import '../../../request_builder/presentation/cubit/manage_credentials_cubit.dart';
import '../../../request_builder/presentation/cubit/manage_credentials_state.dart';
import '../../../request_builder/presentation/widgets/global_variables_sheet.dart';
import '../../../request_builder/presentation/widgets/manage_environments_sheet.dart';
import '../../../request_builder/presentation/widgets/request_environment_menu.dart';
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
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
                      items: state.request.queryParameters,
                      onChanged: context
                          .read<WebSocketCubit>()
                          .updateQueryParameters,
                      hintKey: 'Param Key',
                      hintVal: 'Param Value',
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _SectionHeader(title: 'Headers'),
                    _ParamsHeadersListCard(
                      items: state.request.headers,
                      onChanged: context.read<WebSocketCubit>().updateHeaders,
                      hintKey: 'Header Key',
                      hintVal: 'Header Value',
                    ),
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
                        auth: state.request.auth,
                        onChanged: context.read<WebSocketCubit>().updateAuth,
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
                  child: SizedBox(
                    height: 48,
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

    await showWebSocketSessionSheet(
      context,
      cubit: context.read<WebSocketCubit>(),
    );
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
                              type == AuthType.none
                                  ? const RequestAuthDraft.none()
                                  : currentAuth.copyWith(type: type),
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

class _AuthFieldsCard extends StatelessWidget {
  const _AuthFieldsCard({required this.auth, required this.onChanged});

  final RequestAuthDraft auth;
  final ValueChanged<RequestAuthDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Column(
        children: switch (auth.type) {
          AuthType.basic => [
            _AuthTextField(
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
            _AuthTextField(
              label: 'Key',
              value: auth.apiKey.name,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  apiKey: ApiKeyAuthDraft(
                    name: value,
                    value: auth.apiKey.value,
                    location: auth.apiKey.location,
                  ),
                ),
              ),
            ),
            _AuthTextField(
              label: 'Value',
              value: auth.apiKey.value,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  apiKey: ApiKeyAuthDraft(
                    name: auth.apiKey.name,
                    value: value,
                    location: auth.apiKey.location,
                  ),
                ),
              ),
            ),
            _AuthDropdown<ApiKeyLocation>(
              label: 'Add To',
              value: auth.apiKey.location,
              values: ApiKeyLocation.values,
              labelFor: (value) => value.label,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  apiKey: ApiKeyAuthDraft(
                    name: auth.apiKey.name,
                    value: auth.apiKey.value,
                    location: value,
                  ),
                ),
              ),
            ),
          ],
          AuthType.bearerToken => [
            _AuthTextField(
              label: 'Token',
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
            _AuthTextField(
              label: 'Prefix',
              value: auth.bearerToken.prefix,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  bearerToken: BearerTokenAuthDraft(
                    token: auth.bearerToken.token,
                    prefix: value,
                  ),
                ),
              ),
            ),
          ],
          AuthType.oauth2 => [
            _AuthTextField(
              label: 'Access Token',
              value: auth.oauth2.accessToken,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth2: auth.oauth2.copyWith(accessToken: value)),
              ),
            ),
            _AuthTextField(
              label: 'Header Prefix',
              value: auth.oauth2.headerPrefix,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth2: auth.oauth2.copyWith(headerPrefix: value),
                ),
              ),
            ),
            _AuthSwitchRow(
              label: 'Send As Header',
              value: auth.oauth2.addTokenToHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  oauth2: auth.oauth2.copyWith(addTokenToHeader: value),
                ),
              ),
            ),
          ],
          AuthType.jwt => [
            _AuthTextField(
              label: 'Payload JSON',
              value: auth.jwt.payload,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(payload: value)),
              ),
            ),
            _AuthTextField(
              label: 'Secret',
              value: auth.jwt.secret,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(secret: value)),
              ),
            ),
            _AuthDropdown<JwtAlgorithm>(
              label: 'Algorithm',
              value: auth.jwt.selectedAlgorithm,
              values: JwtAlgorithm.values,
              labelFor: (value) => value.label,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(algorithm: value.label)),
              ),
            ),
            _AuthSwitchRow(
              label: 'Send As Header',
              value: auth.jwt.sendAsHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(jwt: auth.jwt.copyWith(sendAsHeader: value)),
              ),
            ),
          ],
          AuthType.oauth1 => [
            _AuthTextField(
              label: 'Consumer Key',
              value: auth.oauth1.consumerKey,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(consumerKey: value)),
              ),
            ),
            _AuthTextField(
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
              label: 'Token',
              value: auth.oauth1.token,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(token: value)),
              ),
            ),
            _AuthTextField(
              label: 'Token Secret',
              value: auth.oauth1.tokenSecret,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(tokenSecret: value)),
              ),
            ),
            _AuthSwitchRow(
              label: 'Send As Authorization Header',
              value: auth.oauth1.asHeader,
              onChanged: (value) => onChanged(
                auth.copyWith(oauth1: auth.oauth1.copyWith(asHeader: value)),
              ),
            ),
          ],
          AuthType.hawk => [
            _AuthTextField(
              label: 'Auth ID',
              value: auth.hawk.identifier,
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(identifier: value)),
              ),
            ),
            _AuthTextField(
              label: 'Auth Key',
              value: auth.hawk.key,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(key: value)),
              ),
            ),
            _AuthDropdown<HawkAlgorithm>(
              label: 'Algorithm',
              value: auth.hawk.selectedAlgorithm,
              values: HawkAlgorithm.values,
              labelFor: (value) => value.label,
              onChanged: (value) => onChanged(
                auth.copyWith(hawk: auth.hawk.copyWith(algorithm: value.name)),
              ),
            ),
          ],
          AuthType.digest => [
            _AuthTextField(
              label: 'Username',
              value: auth.digest.username,
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(username: value)),
              ),
            ),
            _AuthTextField(
              label: 'Password',
              value: auth.digest.password,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(password: value)),
              ),
            ),
            _AuthTextField(
              label: 'Realm',
              value: auth.digest.realm,
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(realm: value)),
              ),
            ),
            _AuthTextField(
              label: 'Nonce',
              value: auth.digest.nonce,
              onChanged: (value) => onChanged(
                auth.copyWith(digest: auth.digest.copyWith(nonce: value)),
              ),
            ),
            _AuthDropdown<DigestAlgorithm>(
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
          ],
          AuthType.awsSignature => [
            _AuthTextField(
              label: 'Access Key',
              value: auth.aws.accessKey,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  aws: AwsAuthDraft(
                    accessKey: value,
                    secretKey: auth.aws.secretKey,
                    region: auth.aws.region,
                    service: auth.aws.service,
                    sessionToken: auth.aws.sessionToken,
                  ),
                ),
              ),
            ),
            _AuthTextField(
              label: 'Secret Key',
              value: auth.aws.secretKey,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  aws: AwsAuthDraft(
                    accessKey: auth.aws.accessKey,
                    secretKey: value,
                    region: auth.aws.region,
                    service: auth.aws.service,
                    sessionToken: auth.aws.sessionToken,
                  ),
                ),
              ),
            ),
            _AuthTextField(
              label: 'Region',
              value: auth.aws.region,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  aws: AwsAuthDraft(
                    accessKey: auth.aws.accessKey,
                    secretKey: auth.aws.secretKey,
                    region: value,
                    service: auth.aws.service,
                    sessionToken: auth.aws.sessionToken,
                  ),
                ),
              ),
            ),
            _AuthTextField(
              label: 'Service',
              value: auth.aws.service,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  aws: AwsAuthDraft(
                    accessKey: auth.aws.accessKey,
                    secretKey: auth.aws.secretKey,
                    region: auth.aws.region,
                    service: value,
                    sessionToken: auth.aws.sessionToken,
                  ),
                ),
              ),
            ),
            _AuthTextField(
              label: 'Session Token',
              value: auth.aws.sessionToken,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(
                  aws: AwsAuthDraft(
                    accessKey: auth.aws.accessKey,
                    secretKey: auth.aws.secretKey,
                    region: auth.aws.region,
                    service: auth.aws.service,
                    sessionToken: value,
                  ),
                ),
              ),
            ),
          ],
          AuthType.ntlm => [
            _AuthTextField(
              label: 'Username',
              value: auth.ntlm.username,
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(username: value)),
              ),
            ),
            _AuthTextField(
              label: 'Password',
              value: auth.ntlm.password,
              obscureText: true,
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(password: value)),
              ),
            ),
            _AuthTextField(
              label: 'Domain',
              value: auth.ntlm.domain,
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(domain: value)),
              ),
            ),
            _AuthTextField(
              label: 'Workstation',
              value: auth.ntlm.workstation,
              onChanged: (value) => onChanged(
                auth.copyWith(ntlm: auth.ntlm.copyWith(workstation: value)),
              ),
            ),
          ],
          AuthType.none => const <Widget>[],
        },
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.obscureText = false,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label, border: InputBorder.none),
      onChanged: onChanged,
    );
  }
}

class _AuthDropdown<T> extends StatelessWidget {
  const _AuthDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
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
  const _AuthSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colors.surfaceMuted,
              child: Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Title & Rename Action
          GestureDetector(
            onTap: () => _showRenameDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  requestName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

          // More Options Button
          PopupMenuButton<String>(
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
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
            ),
            color: colors.card,
            onSelected: onMoreMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'environment',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.globe, size: 18),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'Environment',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right, size: 14),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'certificates',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.shield, size: 18),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      'Certificates',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.settings, size: 18),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      'Settings',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.question_circle, size: 18),
                    const SizedBox(width: AppSpacing.small),
                    Text('Help', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: colors.methodDelete,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      'Clear',
                      style: TextStyle(
                        color: colors.methodDelete,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
            return Padding(
              key: ValueKey(idx),
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isEnabled,
                    onChanged: (val) {
                      final updated = List<KeyValueItem>.from(items);
                      updated[idx] = item.copyWith(isEnabled: val ?? true);
                      onChanged(updated);
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.key,
                      decoration: InputDecoration(
                        hintText: hintKey,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        final updated = List<KeyValueItem>.from(items);
                        updated[idx] = item.copyWith(key: val);
                        onChanged(updated);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.value,
                      decoration: InputDecoration(
                        hintText: hintVal,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        final updated = List<KeyValueItem>.from(items);
                        updated[idx] = item.copyWith(value: val);
                        onChanged(updated);
                      },
                    ),
                  ),
                  IconButton(
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
