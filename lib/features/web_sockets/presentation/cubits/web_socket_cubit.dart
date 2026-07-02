import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/ntlm/ntlm_messages.dart';
import '../../../request_builder/domain/entities/auth_applied_request.dart';
import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../../request_builder/domain/entities/request_variable_store.dart';
import '../../../request_builder/domain/entities/resolved_request.dart';
import '../../../request_builder/domain/helpers/digest_authorization_header_builder.dart';
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

  /// Replaces the active WebSocket request draft.
  void updateRequest(WebSocketRequestEntity request) {
    emit(state.copyWith(request: request, clearErrorMessage: true));
  }

  /// Updates the WebSocket URL while preserving the rest of the request.
  void updateUrl(String url) {
    updateRequest(state.request.copyWith(url: url));
  }

  /// Replaces the full query parameters collection after list edits.
  void updateQueryParameters(List<KeyValueItem> queryParameters) {
    updateRequest(state.request.copyWith(queryParameters: queryParameters));
  }

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

    final validationError = _validateUrl(state.request.url);
    if (validationError != null) {
      _emitError(validationError);
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
      final connection = await _client
          .connect(
            uri: prepared.uri,
            headers: prepared.headers,
            timeout: Duration(
              seconds: state.request.settings.handshakeTimeoutSeconds,
            ),
            verifySsl: state.request.settings.verifySsl,
          )
          .timeout(
            Duration(seconds: state.request.settings.handshakeTimeoutSeconds),
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

  Future<_PreparedWebSocketConnection> _prepareConnection() async {
    final variableStore = await _loadVariableStore();
    final resolved = _resolveRequestUseCase(
      draft: RequestDraft(
        url: state.request.url,
        queryParameters: state.request.queryParameters,
        headers: state.request.headers,
        auth: state.request.auth,
      ),
      variableStore: variableStore,
    );
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
    _applyHandshakeOnlyAuth(headers: headers, uri: uri, auth: request.auth);

    return _PreparedWebSocketConnection(uri: uri, headers: headers);
  }

  /// Appends auth-generated query parameters to the resolved WebSocket URL.
  Uri _uriWithQueryParameters(String url, List<KeyValueItem> queryParameters) {
    final uri = Uri.parse(url);
    final nextQueryParameters = Map<String, String>.from(uri.queryParameters);

    for (final item in queryParameters) {
      if (item.isComplete) {
        nextQueryParameters[item.key] = item.value;
      }
    }

    if (nextQueryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: nextQueryParameters);
  }

  /// Converts enabled editor header rows into the handshake header map.
  Map<String, String> _headersMap(List<KeyValueItem> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      if (header.isComplete) {
        result[header.key] = header.value;
      }
    }
    return result;
  }

  /// Uses HTTP schemes for auth signing while preserving the original ws URL.
  ResolvedRequest _resolvedForHandshakeSigning(ResolvedRequest resolved) {
    final request = resolved.request;
    return ResolvedRequest(
      request: request.copyWith(url: _httpUpgradeUrl(request.url)),
      resolvedVariables: resolved.resolvedVariables,
      issues: resolved.issues,
    );
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

  /// Applies auth modes that are handshake-only in WebSocket sessions.
  void _applyHandshakeOnlyAuth({
    required Map<String, String> headers,
    required Uri uri,
    required RequestAuthDraft auth,
  }) {
    if (auth.type == AuthType.digest) {
      if (!auth.digest.hasManualChallenge) {
        throw Exception('Digest auth for WebSocket requires Realm and Nonce.');
      }

      final result = const DigestAuthorizationHeaderBuilder().build(
        method: 'GET',
        url: uri.toString(),
        digest: auth.digest,
      );
      if (!result.isValid) {
        throw Exception(
          result.errorMessage ?? 'Could not build Digest Authorization header.',
        );
      }
      headers['Authorization'] = result.authorizationHeader;
      return;
    }

    if (auth.type == AuthType.ntlm) {
      headers['Authorization'] = 'NTLM ${createType1Message()}';
    }
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
  });

  final Uri uri;
  final Map<String, String> headers;
}
