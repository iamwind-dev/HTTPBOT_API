import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../request_builder/domain/entities/auth_applied_request.dart';
import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../../request_builder/domain/entities/request_variable_store.dart';
import '../../../request_builder/domain/entities/resolved_request.dart';
import '../../../request_builder/domain/helpers/auth_headers_updater.dart';
import '../../../request_builder/domain/helpers/aws_auth_headers_builder.dart';
import '../../../request_builder/domain/helpers/aws_headers_updater.dart';
import '../../../request_builder/domain/helpers/digest_authorization_header_builder.dart';
import '../../../request_builder/domain/helpers/digest_challenge_parser.dart';
import '../../../request_builder/domain/helpers/hawk_authorization_header_builder.dart';
import '../../../request_builder/domain/helpers/request_auth_validator.dart';
import '../../../request_builder/domain/usecases/apply_request_auth_use_case.dart';
import '../../../request_builder/domain/usecases/resolve_request_use_case.dart';
import '../../domain/entities/web_socket_event_entity.dart';
import '../../domain/entities/web_socket_request_entity.dart';
import '../../domain/entities/web_socket_settings_entity.dart';
import '../../domain/entities/web_socket_state_entity.dart';
import '../../domain/repositories/web_socket_client.dart';
import '../utils/web_socket_response_headers_formatter.dart';

class WebSocketCubit extends Cubit<WebSocketStateEntity> {
  WebSocketCubit({
    required WebSocketClient client,
    required Future<RequestVariableStore> Function() loadVariableStore,
    ResolveRequestUseCase resolveRequestUseCase = const ResolveRequestUseCase(),
    ApplyRequestAuthUseCase applyRequestAuthUseCase =
        const ApplyRequestAuthUseCase(),
    Duration pingInterval = const Duration(seconds: 20),
  }) : _client = client,
       _loadVariableStore = loadVariableStore,
       _resolveRequestUseCase = resolveRequestUseCase,
       _applyRequestAuthUseCase = applyRequestAuthUseCase,
       _pingInterval = pingInterval,
       super(const WebSocketStateEntity());

  final WebSocketClient _client;
  final Future<RequestVariableStore> Function() _loadVariableStore;
  final ResolveRequestUseCase _resolveRequestUseCase;
  final ApplyRequestAuthUseCase _applyRequestAuthUseCase;
  final Duration _pingInterval;
  WebSocketConnection? _connection;
  StreamSubscription<WebSocketFrameEntity>? _subscription;
  Timer? _pingTimer;
  bool _disconnecting = false;
  final HawkAuthorizationHeaderBuilder _hawkBuilder =
      HawkAuthorizationHeaderBuilder();

  /// Replaces the active WebSocket request draft after removing stale auth rows.
  void updateRequest(WebSocketRequestEntity request) {
    final normalizedHeaders = syncAuthorizationHeaderWithAuth(
      headers: request.headers,
      auth: const RequestAuthDraft.none(),
    );
    emit(
      state.copyWith(
        request: request.copyWith(
          queryParameters: _withoutAuthSystemRows(request.queryParameters),
          headers: _withoutAuthSystemRows(normalizedHeaders),
        ),
        clearErrorMessage: true,
      ),
    );
  }

  /// Updates the WebSocket URL while preserving the rest of the request.
  void updateUrl(String url) {
    updateRequest(state.request.copyWith(url: url));
  }

  /// Replaces the full query parameters collection after list edits.
  void updateQueryParameters(List<KeyValueItem> queryParameters) {
    updateRequest(state.request.copyWith(queryParameters: queryParameters));
  }

  /// Removes OAuth and API Key-owned rows from the raw editor draft.
  List<KeyValueItem> _withoutAuthSystemRows(List<KeyValueItem> items) => items
      .where(
        (item) =>
            !item.isSystemGeneratedOAuth1Header &&
            !item.isSystemGeneratedOAuth1QueryParameter &&
            !item.isSystemGeneratedOAuth2Header &&
            !item.isSystemGeneratedOAuth2QueryParameter &&
            !item.isSystemGeneratedApiKeyHeader &&
            !item.isSystemGeneratedApiKeyQueryParameter &&
            !item.isBasicAuthSystemGeneratedHeader &&
            !item.isBearerTokenSystemGeneratedHeader &&
            !item.isDigestAuthSystemGeneratedHeader &&
            !item.isNtlmAuthSystemGeneratedHeader &&
            !item.isSystemGeneratedHawkHeader &&
            !item.isJwtSystemGeneratedHeader &&
            !item.isSystemGeneratedJwtQueryParameter,
      )
      .toList(growable: false);

  /// Replaces the full header collection after list edits.
  void updateHeaders(List<KeyValueItem> headers) {
    updateRequest(state.request.copyWith(headers: headers));
  }

  /// Updates the compatible auth draft used for the handshake.
  void updateAuth(RequestAuthDraft auth) {
    updateRequest(state.request.copyWith(auth: auth));
  }

  /// Updates request-local WebSocket settings.
  void updateSettings(WebSocketSettingsEntity settings) {
    updateRequest(state.request.copyWith(settings: settings));
  }

  /// Validates, resolves, and opens a WebSocket connection.
  Future<void> connect() async {
    if (state.status == WebSocketConnectionStatus.connected ||
        state.status == WebSocketConnectionStatus.connecting) {
      return;
    }

    final validationError = _validateUrl(
      state.request.url,
      useNtlmMessage: state.request.auth.type == AuthType.ntlm,
    );
    if (validationError != null) {
      _emitError(validationError);
      return;
    }

    final authValidation = _validateWebSocketAuth(
      state.request.auth,
      validateResolvedFields: false,
    );
    if (!authValidation.isValid) {
      _emitError(authValidation.errorMessage ?? 'Invalid authentication.');
      return;
    }

    emit(
      state.copyWith(
        status: WebSocketConnectionStatus.connecting,
        events: [...state.events, _lifecycleEvent('Connecting')],
        clearErrorMessage: true,
      ),
    );

    try {
      final prepared = await _prepareConnection();
      final timeout = Duration(
        seconds: state.request.settings.handshakeTimeoutSeconds,
      );
      final connection = await _connectPrepared(
        prepared,
        timeout: timeout,
        verifySsl: state.request.settings.verifySsl,
      );
      _connection = connection;
      _listenToConnection(connection);
      final responseHeaders = normalizeWebSocketResponseHeaders(
        connection.responseHeaders,
      );
      emit(
        state.copyWith(
          status: WebSocketConnectionStatus.connected,
          events: [
            ...state.events,
            _lifecycleEvent(
              responseHeaders.isEmpty
                  ? 'Response headers unavailable'
                  : 'Response headers:',
              title: 'Connection Upgraded',
              responseHeaders: responseHeaders.isEmpty ? null : responseHeaders,
            ),
          ],
          clearErrorMessage: true,
        ),
      );
      _startPingTimer();
    } on TimeoutException {
      _emitError('WebSocket handshake timed out.');
    } on Object catch (error) {
      _emitError(_friendlyError(error));
    }
  }

  /// Cleanly closes the current WebSocket connection.
  Future<void> disconnect() async {
    final connection = _connection;
    if (connection == null) {
      emit(
        state.copyWith(
          status: WebSocketConnectionStatus.disconnected,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    _disconnecting = true;
    _stopPingTimer();
    await connection.close();
    await _subscription?.cancel();
    _subscription = null;
    _connection = null;
    _disconnecting = false;

    emit(
      state.copyWith(
        status: WebSocketConnectionStatus.disconnected,
        events: [...state.events, _disconnectedEvent(connection)],
        clearErrorMessage: true,
      ),
    );
  }

  /// Sends a text frame when connected and records it in the event log.
  Future<void> sendText(String message) async {
    final text = message.trim();
    final connection = _connection;
    if (text.isEmpty ||
        connection == null ||
        state.status != WebSocketConnectionStatus.connected) {
      return;
    }

    emit(state.copyWith(isSending: true));
    try {
      await connection.sendText(text);
      emit(
        state.copyWith(
          isSending: false,
          events: [
            ...state.events,
            _textEvent(WebSocketEventType.sentText, text),
          ],
        ),
      );
    } on Object catch (error) {
      emit(state.copyWith(isSending: false));
      _emitError(_friendlyError(error));
    }
  }

  /// Sends a binary frame when connected and records the filename and size.
  Future<void> sendBinary(List<int> bytes, {String? fileName}) async {
    final connection = _connection;
    if (bytes.isEmpty ||
        connection == null ||
        state.status != WebSocketConnectionStatus.connected) {
      return;
    }

    try {
      await connection.sendBinary(bytes);
      emit(
        state.copyWith(
          events: [
            ...state.events,
            _binaryEvent(
              WebSocketEventType.sentBinary,
              bytes,
              fileName: fileName,
            ),
          ],
        ),
      );
    } on Object catch (error) {
      _emitError(_friendlyError(error));
    }
  }

  /// Removes session events without changing the active connection.
  void clearEvents() {
    emit(state.copyWith(events: const <WebSocketEventEntity>[]));
  }

  /// Closes streams and the active socket before disposing the cubit.
  @override
  Future<void> close() async {
    _stopPingTimer();
    await _subscription?.cancel();
    await _connection?.close();
    return super.close();
  }

  /// Resolves request variables and auth immediately before opening the socket.
  Future<_PreparedWebSocketConnection> _prepareConnection() async {
    final variableStore = await _loadVariableStore();
    final resolved = _resolveRequestUseCase(
      draft: RequestDraft(
        url: state.request.url,
        queryParameters: state.request.queryParameters,
        headers: _withoutAuthSystemRows(state.request.headers),
        auth: state.request.auth,
      ),
      variableStore: variableStore,
    );
    final resolvedAuthValidation = _validateResolvedAuth(resolved);
    if (!resolvedAuthValidation.isValid) {
      throw Exception(
        resolvedAuthValidation.errorMessage ?? 'Invalid authentication.',
      );
    }

    final resolvedUrlError = _validateResolvedUrl(resolved.request.url);
    if (resolvedUrlError != null) {
      throw Exception(resolvedUrlError);
    }

    if (resolved.request.auth.type == AuthType.hawk) {
      return _prepareHawkConnection(resolved);
    }
    if (resolved.request.auth.type == AuthType.awsSignature) {
      return _prepareAwsConnection(resolved);
    }

    final authApplied = _applyRequestAuthUseCase(
      resolvedRequest: _resolvedForHandshakeSigning(resolved),
    );
    if (authApplied.hasBlockingIssues) {
      throw Exception(_firstAuthIssueMessage(authApplied));
    }
    final request = authApplied.request;
    final uri = _uriWithQueryParameters(
      resolved.request.url,
      request.queryParameters,
    );
    final headers = _headersMap(request.headers);
    final ntlmAuth =
        request.auth.type == AuthType.ntlm &&
            !_hasHeader(headers, 'authorization')
        ? request.auth.ntlm
        : null;

    return _PreparedWebSocketConnection(
      uri: uri,
      headers: headers,
      auth: request.auth,
      ntlmAuth: ntlmAuth,
    );
  }

  /// Signs one final resolved WebSocket GET resource with a stable Hawk context.
  _PreparedWebSocketConnection _prepareHawkConnection(
    ResolvedRequest resolved,
  ) {
    final uri = _uriWithQueryParameters(
      resolved.request.url,
      resolved.request.queryParameters,
    );
    if (_hasEnabledUserAuthorization(resolved.request.headers)) {
      return _PreparedWebSocketConnection(
        uri: uri,
        headers: _headersMap(resolved.request.headers),
        auth: const RequestAuthDraft.none(),
      );
    }

    final signingContext = _hawkBuilder.createSigningContext(
      resolved.request.auth.hawk,
    );
    final signingRequest = resolved.request.copyWith(
      url: _httpUpgradeUrl(uri.toString()),
      queryParameters: const <KeyValueItem>[],
    );
    final authApplied = _applyRequestAuthUseCase(
      resolvedRequest: ResolvedRequest(
        request: signingRequest,
        resolvedVariables: resolved.resolvedVariables,
        issues: resolved.issues,
      ),
      hawkSigningContext: signingContext,
    );
    if (authApplied.hasBlockingIssues) {
      throw Exception(_firstAuthIssueMessage(authApplied));
    }

    final request = authApplied.request;
    final headers = _headersMap(request.headers);
    final generated = request.headers
        .where((header) => header.isSystemGeneratedHawkHeader)
        .firstOrNull;
    if (generated != null) {
      _previewHawkAuthorization(generated.value);
    }

    return _PreparedWebSocketConnection(
      uri: uri,
      headers: headers,
      auth: request.auth,
    );
  }

  /// Signs one final resolved WebSocket GET resource with one AWS context.
  _PreparedWebSocketConnection _prepareAwsConnection(ResolvedRequest resolved) {
    final uri = _uriWithQueryParameters(
      resolved.request.url,
      resolved.request.queryParameters,
    );
    final signingRequest = resolved.request.copyWith(
      url: _httpUpgradeUrl(uri.toString()),
      queryParameters: const <KeyValueItem>[],
    );
    final syncedFields = syncAwsAuthToRequestFields(
      queryParameters: const <KeyValueItem>[],
      headers: signingRequest.headers,
      auth: signingRequest.auth,
      method: signingRequest.method,
      url: signingRequest.url,
      body: signingRequest.body,
      signingContext: AwsSigningContext(DateTime.now()),
    );
    final request = signingRequest.copyWith(
      headers: syncedFields.headers,
      queryParameters: syncedFields.queryParameters,
      auth: const RequestAuthDraft.none(),
    );

    return _PreparedWebSocketConnection(
      uri: _uriWithQueryParameters(uri.toString(), request.queryParameters),
      headers: _headersMap(request.headers),
      auth: request.auth,
    );
  }

  /// Opens the prepared handshake, coordinating Digest challenge retries.
  Future<WebSocketConnection> _connectPrepared(
    _PreparedWebSocketConnection prepared, {
    required Duration timeout,
    required bool verifySsl,
  }) {
    if (prepared.auth.type == AuthType.digest &&
        !_hasHeader(prepared.headers, 'authorization')) {
      return _connectWithDigestChallenge(
        prepared,
        timeout: timeout,
        verifySsl: verifySsl,
      );
    }

    return _client
        .connect(
          uri: prepared.uri,
          headers: prepared.headers,
          timeout: timeout,
          verifySsl: verifySsl,
          ntlmAuth: prepared.ntlmAuth,
          onNtlmStage: _emitNtlmStage,
        )
        .timeout(timeout);
  }

  /// Performs the Digest 401 challenge/retry sequence for WebSocket GET.
  Future<WebSocketConnection> _connectWithDigestChallenge(
    _PreparedWebSocketConnection prepared, {
    required Duration timeout,
    required bool verifySsl,
  }) async {
    try {
      return await _client
          .connect(
            uri: prepared.uri,
            headers: prepared.headers,
            timeout: timeout,
            verifySsl: verifySsl,
          )
          .timeout(timeout);
    } on WebSocketHandshakeException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      final challenge = _digestChallengeFromHeaders(error.headers);
      if (challenge == null) {
        throw Exception('Digest challenge was not received.');
      }

      final result = const DigestAuthorizationHeaderBuilder().build(
        method: 'GET',
        url: prepared.uri.toString(),
        digest: prepared.auth.digest,
        challenge: challenge,
      );
      if (!result.isValid) {
        throw Exception(
          result.errorMessage ?? 'Could not build Digest Authorization header.',
        );
      }

      _previewDigestAuthorization(result.authorizationHeader);

      final retryHeaders = Map<String, String>.from(prepared.headers)
        ..['Authorization'] = result.authorizationHeader;
      try {
        return await _client
            .connect(
              uri: prepared.uri,
              headers: retryHeaders,
              timeout: timeout,
              verifySsl: verifySsl,
            )
            .timeout(timeout);
      } on WebSocketHandshakeException catch (retryError) {
        throw Exception(
          'Digest authentication failed: '
          '${retryError.statusCode} ${retryError.reasonPhrase}',
        );
      }
    }
  }

  /// Extracts the first Digest challenge from case-insensitive response headers.
  DigestChallenge? _digestChallengeFromHeaders(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'www-authenticate') {
        continue;
      }
      final challenge = parseDigestChallenge(entry.value);
      if (challenge != null) {
        return challenge;
      }
    }

    return null;
  }

  /// Shows the last generated Digest Authorization row without saving it as user input.
  void _previewDigestAuthorization(String authorizationHeader) {
    final headers = _withoutAuthSystemRows(state.request.headers);
    emit(
      state.copyWith(
        request: state.request.copyWith(
          headers: [
            ...headers,
            KeyValueItem(
              key: 'Authorization',
              value: authorizationHeader,
              description: digestAuthSystemGeneratedHeaderDescription,
              source: RequestHeaderSource.systemAuth,
              systemTag: 'digestAuth',
            ),
          ],
        ),
      ),
    );
  }

  /// Stores the current attempt's Hawk header as a derived read-only preview.
  void _previewHawkAuthorization(String authorizationHeader) {
    final headers = _withoutAuthSystemRows(state.request.headers);
    emit(
      state.copyWith(
        request: state.request.copyWith(
          headers: [
            ...headers,
            KeyValueItem(
              key: 'Authorization',
              value: authorizationHeader,
              description: hawkSystemGeneratedHeaderDescription,
              source: RequestHeaderSource.systemAuth,
              systemTag: 'hawkAuth',
            ),
          ],
        ),
      ),
    );
  }

  /// Validates auth after resolution, preferring Basic username errors for auth placeholders.
  RequestValidationResult _validateResolvedAuth(ResolvedRequest resolved) {
    final validation = _validateWebSocketAuth(resolved.request.auth);
    if (!validation.isValid) {
      return validation;
    }

    if (resolved.request.auth.type == AuthType.hawk) {
      if (resolved.issues.any(
        (issue) => issue.source == 'auth.hawk.identifier',
      )) {
        return const RequestValidationResult.invalid(
          'Hawk Auth ID is required.',
        );
      }
      if (resolved.issues.any((issue) => issue.source == 'auth.hawk.key')) {
        return const RequestValidationResult.invalid(
          'Hawk Auth Key is required.',
        );
      }
    }

    if (resolved.request.auth.type == AuthType.basic &&
        resolved.issues.any((issue) => issue.source == 'auth.basic.username')) {
      return const RequestValidationResult.invalid(
        'Username is required for Basic Auth.',
      );
    }

    if (resolved.request.auth.type == AuthType.oauth2 &&
        resolved.issues.any(
          (issue) => issue.source == 'auth.oauth2.accessToken',
        )) {
      return const RequestValidationResult.invalid(
        'Access token is required for OAuth 2.0.',
      );
    }

    if (resolved.request.auth.type == AuthType.bearerToken &&
        resolved.issues.any(
          (issue) => issue.source == 'auth.bearerToken.token',
        )) {
      return const RequestValidationResult.invalid('Bearer token is required.');
    }

    if (resolved.request.auth.type == AuthType.ntlm) {
      if (resolved.issues.any(
        (issue) => issue.source == 'auth.ntlm.username',
      )) {
        return const RequestValidationResult.invalid(
          'Username is required for NTLM Auth.',
        );
      }
      if (resolved.issues.any(
        (issue) => issue.source == 'auth.ntlm.password',
      )) {
        return const RequestValidationResult.invalid(
          'Password is required for NTLM Auth.',
        );
      }
    }

    if (resolved.request.auth.type == AuthType.jwt) {
      if (resolved.issues.any((issue) => issue.source == 'auth.jwt.secret')) {
        return const RequestValidationResult.invalid(
          'Secret is required for JWT.',
        );
      }
      if (resolved.issues.any(
        (issue) => issue.source == 'auth.jwt.privateKey',
      )) {
        return const RequestValidationResult.invalid(
          'Private Key is required for JWT.',
        );
      }
    }

    if (resolved.request.auth.type == AuthType.apiKey) {
      if (resolved.issues.any((issue) => issue.source == 'auth.apiKey.name')) {
        return RequestValidationResult.invalid(
          resolved.request.auth.apiKey.isCustomName
              ? 'Custom key name is required.'
              : 'API key name is required.',
        );
      }

      if (resolved.issues.any((issue) => issue.source == 'auth.apiKey.value')) {
        return const RequestValidationResult.invalid(
          'API key value is required.',
        );
      }
    }

    if (resolved.request.auth.type == AuthType.awsSignature) {
      if (resolved.issues.any(
        (issue) => issue.source == 'auth.aws.accessKey',
      )) {
        return const RequestValidationResult.invalid(
          'AWS Access Key is required.',
        );
      }
      if (resolved.issues.any(
        (issue) => issue.source == 'auth.aws.secretKey',
      )) {
        return const RequestValidationResult.invalid(
          'AWS Secret Key is required.',
        );
      }
      if (resolved.issues.any((issue) => issue.source == 'auth.aws.region')) {
        return const RequestValidationResult.invalid('AWS Region is required.');
      }
      if (resolved.issues.any((issue) => issue.source == 'auth.aws.service')) {
        return const RequestValidationResult.invalid(
          'AWS Service is required.',
        );
      }
    }

    return const RequestValidationResult.valid();
  }

  /// Appends auth-generated query parameters to the resolved WebSocket URL.
  Uri _uriWithQueryParameters(String url, List<KeyValueItem> queryParameters) {
    final uri = Uri.parse(url);
    final appendedQuery = queryParameters
        .where((item) => item.isComplete)
        .map(_serializeQueryParameter)
        .toList(growable: false);
    if (appendedQuery.isEmpty) {
      return uri;
    }

    final nextQuery = <String>[
      if (uri.query.isNotEmpty) uri.query,
      ...appendedQuery,
    ].join('&');

    return uri.replace(query: nextQuery);
  }

  /// Encodes one resolved query row without collapsing repeated keys.
  String _serializeQueryParameter(KeyValueItem item) =>
      '${Uri.encodeQueryComponent(item.key)}='
      '${Uri.encodeQueryComponent(item.value)}';

  /// Converts enabled editor header rows into the handshake header map.
  Map<String, String> _headersMap(List<KeyValueItem> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      if (header.isComplete) {
        if (header.key.trim().toLowerCase() == 'authorization' &&
            _hasHeader(result, 'authorization')) {
          continue;
        }
        result[header.key] = header.value;
      }
    }
    return result;
  }

  /// Applies WebSocket-specific Hawk validation before shared auth validation.
  RequestValidationResult _validateWebSocketAuth(
    RequestAuthDraft auth, {
    bool validateResolvedFields = true,
  }) {
    if (auth.type == AuthType.jwt && !validateResolvedFields) {
      return const RequestValidationResult.valid();
    }
    if (auth.type == AuthType.ntlm) {
      if (auth.ntlm.username.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Username is required for NTLM Auth.',
        );
      }
      if (auth.ntlm.password.isEmpty) {
        return const RequestValidationResult.invalid(
          'Password is required for NTLM Auth.',
        );
      }
      return const RequestValidationResult.valid();
    }
    if (auth.type == AuthType.awsSignature) {
      if (!validateResolvedFields) {
        return const RequestValidationResult.valid();
      }
      if (auth.aws.accessKey.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'AWS Access Key is required.',
        );
      }
      if (auth.aws.secretKey.isEmpty) {
        return const RequestValidationResult.invalid(
          'AWS Secret Key is required.',
        );
      }
      if (auth.aws.region.trim().isEmpty) {
        return const RequestValidationResult.invalid('AWS Region is required.');
      }
      if (auth.aws.service.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'AWS Service is required.',
        );
      }
      return const RequestValidationResult.valid();
    }
    if (auth.type != AuthType.hawk) {
      return validateAuthBeforeSend(auth);
    }

    final hawk = auth.hawk;
    if (hawk.identifier.trim().isEmpty) {
      return const RequestValidationResult.invalid('Hawk Auth ID is required.');
    }
    if (hawk.key.trim().isEmpty) {
      return const RequestValidationResult.invalid(
        'Hawk Auth Key is required.',
      );
    }
    if (!validateResolvedFields) {
      return const RequestValidationResult.valid();
    }

    final algorithm = hawk.algorithm.trim();
    final normalizedAlgorithm = algorithm.toLowerCase().replaceAll('-', '');
    if (normalizedAlgorithm != 'sha256' && normalizedAlgorithm != 'sha1') {
      return RequestValidationResult.invalid(
        'Unsupported Hawk algorithm: $algorithm',
      );
    }

    final timestamp = hawk.timestamp.trim();
    final parsedTimestamp = int.tryParse(timestamp);
    if (timestamp.isNotEmpty &&
        (parsedTimestamp == null || parsedTimestamp < 0)) {
      return const RequestValidationResult.invalid('Invalid Hawk timestamp.');
    }
    return const RequestValidationResult.valid();
  }

  /// Returns true when enabled raw headers already own Authorization.
  bool _hasEnabledUserAuthorization(List<KeyValueItem> headers) => headers.any(
    (header) =>
        header.isComplete &&
        header.key.trim().toLowerCase() == 'authorization' &&
        !header.isSystemGeneratedAuthorizationHeader,
  );

  /// Validates the resolved URL components needed by WebSocket auth signers.
  String? _validateResolvedUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) {
      return 'WebSocket URL must include a host.';
    }
    return null;
  }

  /// Uses HTTP schemes for auth signing while preserving the original ws URL.
  ResolvedRequest _resolvedForHandshakeSigning(ResolvedRequest resolved) {
    final request = resolved.request;
    return ResolvedRequest(
      request: request.copyWith(
        url: _httpUpgradeUrl(request.url),
        auth: _authWithoutWebSocketBodyHash(request.auth),
      ),
      resolvedVariables: resolved.resolvedVariables,
      issues: resolved.issues,
    );
  }

  /// Disables OAuth body hash only for the bodyless WebSocket handshake snapshot.
  RequestAuthDraft _authWithoutWebSocketBodyHash(RequestAuthDraft auth) {
    if (auth.type != AuthType.oauth1 || !auth.oauth1.includeBodyHash) {
      return auth;
    }

    return auth.copyWith(oauth1: auth.oauth1.copyWith(includeBodyHash: false));
  }

  /// Converts a WebSocket URL to the HTTP URL seen by auth signers.
  String _httpUpgradeUrl(String url) {
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

  /// Subscribes to incoming frames and server-side lifecycle changes.
  void _listenToConnection(WebSocketConnection connection) {
    _subscription = connection.stream.listen(
      (frame) {
        if (frame.isText) {
          emit(
            state.copyWith(
              events: [
                ...state.events,
                _textEvent(WebSocketEventType.receivedText, frame.text ?? ''),
              ],
            ),
          );
          return;
        }

        final bytes = frame.binary ?? const <int>[];
        emit(
          state.copyWith(
            events: [
              ...state.events,
              _binaryEvent(WebSocketEventType.receivedBinary, bytes),
            ],
          ),
        );
      },
      onError: (Object error) => _emitError(_friendlyError(error)),
      onDone: () {
        if (_disconnecting || isClosed) {
          return;
        }
        _connection = null;
        _stopPingTimer();
        emit(
          state.copyWith(
            status: WebSocketConnectionStatus.disconnected,
            events: [...state.events, _disconnectedEvent(connection)],
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  /// Returns a user-facing validation error for unsupported WebSocket URLs.
  String? _validateUrl(String url, {bool useNtlmMessage = false}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      if (useNtlmMessage) {
        return 'Invalid WebSocket URL.';
      }
      return 'WebSocket URL is required.';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
      if (useNtlmMessage) {
        return 'Invalid WebSocket URL.';
      }
      return 'WebSocket URL must start with ws:// or wss://.';
    }

    return null;
  }

  /// Moves the state into error and records the error in the event log.
  void _emitError(String message) {
    _stopPingTimer();
    emit(
      state.copyWith(
        status: WebSocketConnectionStatus.error,
        errorMessage: message,
        events: [...state.events, _errorEvent(message)],
      ),
    );
  }

  /// Removes Dart exception boilerplate from messages shown in the event log.
  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  /// Returns true when a header map already contains a case-insensitive key.
  bool _hasHeader(Map<String, String> headers, String name) =>
      headers.keys.any((key) => key.toLowerCase() == name);

  /// Emits safe NTLM lifecycle text without exposing handshake blobs.
  void _emitNtlmStage(WebSocketNtlmStage stage) {
    final text = switch (stage) {
      WebSocketNtlmStage.negotiating => 'Negotiating NTLM',
      WebSocketNtlmStage.authenticating => 'Authenticating NTLM',
    };
    emit(state.copyWith(events: [...state.events, _lifecycleEvent(text)]));
  }

  /// Returns the first blocking auth or variable resolution message.
  String _firstAuthIssueMessage(AuthAppliedRequest authApplied) {
    if (authApplied.authIssues.isNotEmpty) {
      return authApplied.authIssues.first.message;
    }
    if (authApplied.resolutionIssues.isNotEmpty) {
      final issue = authApplied.resolutionIssues.first;
      return 'Missing variable: ${issue.placeholder}';
    }
    return 'Could not apply WebSocket authentication.';
  }

  /// Creates a lifecycle event with optional handshake response headers.
  WebSocketEventEntity _lifecycleEvent(
    String text, {
    String? title,
    Map<String, String>? responseHeaders,
  }) => WebSocketEventEntity(
    id: _eventId(),
    type: WebSocketEventType.lifecycle,
    timestamp: DateTime.now(),
    title: title,
    text: text,
    responseHeaders: responseHeaders,
  );

  /// Creates the disconnected lifecycle event with optional close details.
  WebSocketEventEntity _disconnectedEvent([WebSocketConnection? connection]) =>
      WebSocketEventEntity(
        id: _eventId(),
        type: WebSocketEventType.disconnected,
        timestamp: DateTime.now(),
        text: 'Disconnected',
        closeCode: connection?.closeCode ?? 1000,
        closeReason: connection?.closeReason,
      );

  /// Creates a sent or received text event.
  WebSocketEventEntity _textEvent(WebSocketEventType type, String text) =>
      WebSocketEventEntity(
        id: _eventId(),
        type: type,
        timestamp: DateTime.now(),
        text: text,
      );

  /// Records the 20-second socket heartbeat while the connection is open.
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isClosed ||
          _connection == null ||
          state.status != WebSocketConnectionStatus.connected) {
        return;
      }
      emit(
        state.copyWith(
          events: [
            ...state.events,
            _textEvent(WebSocketEventType.ping, 'Ping'),
          ],
        ),
      );
    });
  }

  /// Stops heartbeat event logging when the socket leaves connected state.
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Creates a sent or received binary event with a small byte preview.
  WebSocketEventEntity _binaryEvent(
    WebSocketEventType type,
    List<int> bytes, {
    String? fileName,
  }) => WebSocketEventEntity(
    id: _eventId(),
    type: type,
    timestamp: DateTime.now(),
    binaryPreview: bytes.take(16).toList(growable: false),
    binarySizeBytes: bytes.length,
    fileName: fileName,
  );

  /// Creates an error event for connection or send failures.
  WebSocketEventEntity _errorEvent(String message) => WebSocketEventEntity(
    id: _eventId(),
    type: WebSocketEventType.error,
    timestamp: DateTime.now(),
    errorMessage: message,
  );

  /// Builds a stable-enough event id for this in-memory session log.
  String _eventId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class _PreparedWebSocketConnection {
  const _PreparedWebSocketConnection({
    required this.uri,
    required this.headers,
    required this.auth,
    this.ntlmAuth,
  });

  final Uri uri;
  final Map<String, String> headers;
  final RequestAuthDraft auth;
  final NtlmAuthDraft? ntlmAuth;
}
