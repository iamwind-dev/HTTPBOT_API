import '../entities/auth_applied_request.dart';
import '../entities/request_auth_draft.dart';
import '../entities/request_auth_issue.dart';
import '../entities/request_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/resolved_request.dart';
import '../helpers/api_key_auth_ui_sync.dart';
import '../helpers/oauth2_auth_ui_sync.dart';
import 'sync_request_auth_headers_use_case.dart';

class ApplyRequestAuthUseCase {
  const ApplyRequestAuthUseCase({
    SyncRequestAuthHeadersUseCase syncRequestAuthHeadersUseCase =
        const SyncRequestAuthHeadersUseCase(),
  }) : _syncRequestAuthHeadersUseCase = syncRequestAuthHeadersUseCase;

  final SyncRequestAuthHeadersUseCase _syncRequestAuthHeadersUseCase;

  /// Applies supported auth modes to request headers or query parameters after variable resolution.
  AuthAppliedRequest call({required ResolvedRequest resolvedRequest}) {
    final applier = _RequestAuthApplier(
      resolvedRequest: resolvedRequest,
      syncRequestAuthHeadersUseCase: _syncRequestAuthHeadersUseCase,
    );

    return applier.apply();
  }
}

class _RequestAuthApplier {
  const _RequestAuthApplier({
    required this.resolvedRequest,
    required this.syncRequestAuthHeadersUseCase,
  });

  final ResolvedRequest resolvedRequest;
  final SyncRequestAuthHeadersUseCase syncRequestAuthHeadersUseCase;

  /// Produces the request shape expected by the executor after auth mutations have been applied.
  AuthAppliedRequest apply() {
    final auth = resolvedRequest.request.auth;

    switch (auth.type) {
      case AuthType.none:
      case AuthType.basic:
      case AuthType.bearerToken:
      case AuthType.jwt:
      case AuthType.awsSignature:
        return _applyHeaderDrivenAuth();
      case AuthType.apiKey:
        return _applyApiKeyAuth();
      case AuthType.oauth2:
        return _applyOAuth2Auth();
      case AuthType.ntlm:
        return _applyNtlmAuth();
      case AuthType.digest:
      case AuthType.hawk:
      case AuthType.oauth1:
        return _buildResult(
          request: resolvedRequest.request,
          authIssues: <RequestAuthIssue>[
            RequestAuthIssue(
              type: RequestAuthIssueType.unsupportedAuthType,
              authType: auth.type,
              message:
                  '${auth.type.label} auth is declared in the model but not implemented yet.',
            ),
          ],
        );
    }
  }

  /// Applies sync-based auth headers directly to the resolved request shape.
  AuthAppliedRequest _applyHeaderDrivenAuth() {
    final nextHeaders = syncRequestAuthHeadersUseCase(
      headers: resolvedRequest.request.headers,
      auth: resolvedRequest.request.auth,
      method: resolvedRequest.request.method,
      url: resolvedRequest.request.url,
      body: resolvedRequest.request.body,
    );

    return _buildResult(
      request: _rebuildRequest(
        headers: nextHeaders,
        auth: const RequestAuthDraft.none(),
      ),
    );
  }

  /// Applies API key auth to the configured header, query, or cookie location.
  AuthAppliedRequest _applyApiKeyAuth() {
    final apiKey = resolvedRequest.request.auth.apiKey;
    final sanitizedHeaders = syncRequestAuthHeadersUseCase(
      headers: resolvedRequest.request.headers,
      auth: const RequestAuthDraft.none(),
      method: resolvedRequest.request.method,
      url: resolvedRequest.request.url,
      body: resolvedRequest.request.body,
    );
    final issues = <RequestAuthIssue>[
      ..._requireField(
        authType: AuthType.apiKey,
        fieldName: 'name',
        value: apiKey.name,
        issueType: RequestAuthIssueType.invalidConfiguration,
        message: 'API Key auth requires a key name.',
      ),
      ..._requireField(
        authType: AuthType.apiKey,
        fieldName: 'value',
        value: apiKey.value,
        issueType: RequestAuthIssueType.invalidConfiguration,
        message: 'API Key auth requires a key value.',
      ),
    ];

    if (issues.isNotEmpty) {
      return _buildResult(request: resolvedRequest.request, authIssues: issues);
    }

    return switch (apiKey.location) {
      ApiKeyLocation.header ||
      ApiKeyLocation.query => _applyEditorSyncedApiKey(),
      ApiKeyLocation.cookie => _buildResult(
        request: _rebuildRequest(
          headers: _upsertCookieHeader(
            sanitizedHeaders,
            cookieName: apiKey.name,
            cookieValue: apiKey.value,
          ),
          auth: const RequestAuthDraft.none(),
        ),
      ),
    };
  }

  /// Re-synchronizes UI-backed API key fields once right before execution.
  AuthAppliedRequest _applyEditorSyncedApiKey() {
    final syncedFields = syncApiKeyAuthToRequestFields(
      queryParameters: resolvedRequest.request.queryParameters,
      headers: resolvedRequest.request.headers,
      auth: resolvedRequest.request.auth,
    );

    return _buildResult(
      request: _rebuildRequest(
        headers: syncedFields.headers,
        queryParameters: syncedFields.queryParameters,
        auth: const RequestAuthDraft.none(),
      ),
    );
  }

  /// Re-synchronizes UI-backed OAuth2 fields once right before execution.
  AuthAppliedRequest _applyOAuth2Auth() {
    final syncedFields = syncOAuth2AuthToRequestFields(
      queryParameters: resolvedRequest.request.queryParameters,
      headers: resolvedRequest.request.headers,
      auth: resolvedRequest.request.auth,
    );

    return _buildResult(
      request: _rebuildRequest(
        headers: syncedFields.headers,
        queryParameters: syncedFields.queryParameters,
        auth: const RequestAuthDraft.none(),
      ),
    );
  }

  /// Rebuilds the request with only the auth-mutated sections changed.
  RequestDraft _rebuildRequest({
    List<KeyValueItem>? headers,
    List<KeyValueItem>? queryParameters,
    RequestAuthDraft? auth,
  }) {
    final request = resolvedRequest.request;

    return RequestDraft(
      method: request.method,
      url: request.url,
      queryParameters: queryParameters ?? request.queryParameters,
      headers: headers ?? request.headers,
      variables: request.variables,
      body: request.body,
      auth: auth ?? request.auth,
      timeout: request.timeout,
      verifySsl: request.verifySsl,
    );
  }

  /// Builds the final auth-applied output while preserving any earlier resolution issues.
  AuthAppliedRequest _buildResult({
    required RequestDraft request,
    List<RequestAuthIssue> authIssues = const <RequestAuthIssue>[],
  }) {
    return AuthAppliedRequest(
      request: request,
      appliedAuthType: resolvedRequest.request.auth.type,
      resolutionIssues: resolvedRequest.issues,
      authIssues: authIssues,
    );
  }

  /// Validates NTLM credentials and passes the request through with auth intact.
  ///
  /// NTLM authenticates the connection during send, so no Authorization header
  /// is synced into the request here.
  AuthAppliedRequest _applyNtlmAuth() {
    final ntlm = resolvedRequest.request.auth.ntlm;
    final issues = <RequestAuthIssue>[
      ..._requireNtlmField(
        fieldName: 'username',
        value: ntlm.username,
        message: 'Username is required for NTLM.',
      ),
      ..._requireNtlmField(
        fieldName: 'password',
        value: ntlm.password,
        message: 'Password is required for NTLM.',
      ),
    ];

    return _buildResult(
      request: resolvedRequest.request,
      authIssues: issues,
    );
  }

  /// Returns one blocking missing-credentials issue when an NTLM field is blank.
  List<RequestAuthIssue> _requireNtlmField({
    required String fieldName,
    required String value,
    required String message,
  }) {
    if (value.trim().isNotEmpty) {
      return const <RequestAuthIssue>[];
    }
    return <RequestAuthIssue>[
      RequestAuthIssue(
        type: RequestAuthIssueType.missingCredentials,
        authType: AuthType.ntlm,
        fieldName: fieldName,
        message: message,
      ),
    ];
  }

  /// Returns one blocking issue when a required auth field is blank.
  List<RequestAuthIssue> _requireField({
    required AuthType authType,
    required String fieldName,
    required String value,
    required RequestAuthIssueType issueType,
    required String message,
  }) {
    if (value.trim().isNotEmpty) {
      return const <RequestAuthIssue>[];
    }

    return <RequestAuthIssue>[
      RequestAuthIssue(
        type: issueType,
        authType: authType,
        fieldName: fieldName,
        message: message,
      ),
    ];
  }

  /// Upserts a cookie into the Cookie header while preserving other cookies.
  List<KeyValueItem> _upsertCookieHeader(
    List<KeyValueItem> headers, {
    required String cookieName,
    required String cookieValue,
  }) {
    final existingCookieHeader = headers.where(
      (item) =>
          item.isEnabled && item.key.toLowerCase() == 'cookie'.toLowerCase(),
    );
    final currentCookieValue = existingCookieHeader.isEmpty
        ? ''
        : existingCookieHeader.first.value;
    final nextCookieValue = _mergeCookieValue(
      currentCookieValue,
      cookieName: cookieName,
      cookieValue: cookieValue,
    );

    return _upsertItems(
      headers,
      matcher: (item) => item.key.toLowerCase() == 'cookie',
      replacement: KeyValueItem(key: 'Cookie', value: nextCookieValue),
    );
  }

  /// Merges one cookie pair into the existing cookie header string.
  String _mergeCookieValue(
    String currentCookieValue, {
    required String cookieName,
    required String cookieValue,
  }) {
    final segments = currentCookieValue
        .split(';')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final nextSegments = <String>[];
    var replaced = false;

    for (final segment in segments) {
      final separatorIndex = segment.indexOf('=');
      final existingName = separatorIndex == -1
          ? segment
          : segment.substring(0, separatorIndex).trim();

      if (existingName == cookieName) {
        nextSegments.add('$cookieName=$cookieValue');
        replaced = true;
        continue;
      }

      nextSegments.add(segment);
    }

    if (!replaced) {
      nextSegments.add('$cookieName=$cookieValue');
    }

    return nextSegments.join('; ');
  }

  /// Upserts an enabled key/value item and collapses duplicate enabled matches to one entry.
  List<KeyValueItem> _upsertItems(
    List<KeyValueItem> items, {
    required bool Function(KeyValueItem item) matcher,
    required KeyValueItem replacement,
  }) {
    final nextItems = <KeyValueItem>[];
    var inserted = false;

    for (final item in items) {
      if (item.isEnabled && matcher(item)) {
        if (!inserted) {
          nextItems.add(replacement);
          inserted = true;
        }
        continue;
      }

      nextItems.add(item);
    }

    if (!inserted) {
      nextItems.add(replacement);
    }

    return List<KeyValueItem>.unmodifiable(nextItems);
  }
}
