import 'dart:convert';

import '../entities/auth_applied_request.dart';
import '../entities/request_auth_draft.dart';
import '../entities/request_auth_issue.dart';
import '../entities/request_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/resolved_request.dart';

class ApplyRequestAuthUseCase {
  const ApplyRequestAuthUseCase();

  /// Applies supported auth modes to request headers or query parameters after variable resolution.
  AuthAppliedRequest call({required ResolvedRequest resolvedRequest}) {
    final applier = _RequestAuthApplier(resolvedRequest: resolvedRequest);

    return applier.apply();
  }
}

class _RequestAuthApplier {
  const _RequestAuthApplier({required this.resolvedRequest});

  final ResolvedRequest resolvedRequest;

  /// Produces the request shape expected by the executor after auth mutations have been applied.
  AuthAppliedRequest apply() {
    final auth = resolvedRequest.request.auth;

    switch (auth.type) {
      case AuthType.none:
        return _buildResult(request: _clearAuth(resolvedRequest.request));
      case AuthType.basic:
        return _applyBasicAuth();
      case AuthType.apiKey:
        return _applyApiKeyAuth();
      case AuthType.bearerToken:
        return _applyBearerAuth();
      case AuthType.digest:
      case AuthType.hawk:
      case AuthType.jwt:
      case AuthType.ntlm:
      case AuthType.awsSignature:
      case AuthType.oauth1:
      case AuthType.oauth2:
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

  /// Applies the standard Basic auth header when both username and password are present.
  AuthAppliedRequest _applyBasicAuth() {
    final basic = resolvedRequest.request.auth.basic;
    final issues = <RequestAuthIssue>[
      ..._requireField(
        authType: AuthType.basic,
        fieldName: 'username',
        value: basic.username,
        issueType: RequestAuthIssueType.missingCredentials,
        message: 'Basic auth requires a username.',
      ),
      ..._requireField(
        authType: AuthType.basic,
        fieldName: 'password',
        value: basic.password,
        issueType: RequestAuthIssueType.missingCredentials,
        message: 'Basic auth requires a password.',
      ),
    ];

    if (issues.isNotEmpty) {
      return _buildResult(request: resolvedRequest.request, authIssues: issues);
    }

    final credentials = base64Encode(
      utf8.encode('${basic.username}:${basic.password}'),
    );
    final nextHeaders = _upsertHeader(
      resolvedRequest.request.headers,
      key: 'Authorization',
      value: 'Basic $credentials',
    );

    return _buildResult(
      request: _rebuildRequest(
        headers: nextHeaders,
        auth: const RequestAuthDraft.none(),
      ),
    );
  }

  /// Applies a Bearer-style Authorization header using the resolved token and optional prefix.
  AuthAppliedRequest _applyBearerAuth() {
    final bearerToken = resolvedRequest.request.auth.bearerToken;
    final issues = _requireField(
      authType: AuthType.bearerToken,
      fieldName: 'token',
      value: bearerToken.token,
      issueType: RequestAuthIssueType.invalidConfiguration,
      message: 'Bearer auth requires a token.',
    );

    if (issues.isNotEmpty) {
      return _buildResult(request: resolvedRequest.request, authIssues: issues);
    }

    final prefix = bearerToken.prefix.trim();
    final authorizationValue = prefix.isEmpty
        ? bearerToken.token
        : '$prefix ${bearerToken.token}';
    final nextHeaders = _upsertHeader(
      resolvedRequest.request.headers,
      key: 'Authorization',
      value: authorizationValue,
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
      ApiKeyLocation.header => _buildResult(
        request: _rebuildRequest(
          headers: _upsertHeader(
            resolvedRequest.request.headers,
            key: apiKey.name,
            value: apiKey.value,
          ),
          auth: const RequestAuthDraft.none(),
        ),
      ),
      ApiKeyLocation.query => _buildResult(
        request: _rebuildRequest(
          queryParameters: _upsertQueryParameter(
            resolvedRequest.request.queryParameters,
            key: apiKey.name,
            value: apiKey.value,
          ),
          auth: const RequestAuthDraft.none(),
        ),
      ),
      ApiKeyLocation.cookie => _buildResult(
        request: _rebuildRequest(
          headers: _upsertCookieHeader(
            resolvedRequest.request.headers,
            cookieName: apiKey.name,
            cookieValue: apiKey.value,
          ),
          auth: const RequestAuthDraft.none(),
        ),
      ),
    };
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

  /// Clears auth state once its side effects have been merged into the request shape.
  RequestDraft _clearAuth(RequestDraft request) => RequestDraft(
    method: request.method,
    url: request.url,
    queryParameters: request.queryParameters,
    headers: request.headers,
    variables: request.variables,
    body: request.body,
    auth: const RequestAuthDraft.none(),
    timeout: request.timeout,
    verifySsl: request.verifySsl,
  );

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

  /// Upserts an enabled header by case-insensitive key and removes duplicate enabled entries.
  List<KeyValueItem> _upsertHeader(
    List<KeyValueItem> headers, {
    required String key,
    required String value,
  }) => _upsertItems(
    headers,
    matcher: (item) => item.key.toLowerCase() == key.toLowerCase(),
    replacement: KeyValueItem(key: key, value: value),
  );

  /// Upserts a query parameter by exact key while preserving disabled duplicates.
  List<KeyValueItem> _upsertQueryParameter(
    List<KeyValueItem> queryParameters, {
    required String key,
    required String value,
  }) => _upsertItems(
    queryParameters,
    matcher: (item) => item.key == key,
    replacement: KeyValueItem(key: key, value: value),
  );

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

    return _upsertHeader(headers, key: 'Cookie', value: nextCookieValue);
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
