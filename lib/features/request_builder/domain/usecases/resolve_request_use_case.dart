import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/request_resolution_issue.dart';
import '../entities/request_variable.dart';
import '../entities/request_variable_store.dart';
import '../entities/resolved_request.dart';

class ResolveRequestUseCase {
  const ResolveRequestUseCase();

  static final RegExp _placeholderPattern = RegExp(
    r'{{\s*([a-zA-Z0-9_.-]+)\s*}}',
  );

  /// Resolves placeholders across the request draft using request, environment, then global variables.
  ResolvedRequest call({
    required RequestDraft draft,
    required RequestVariableStore variableStore,
  }) {
    final resolver = _RequestDraftResolver(
      draft: draft,
      variableStore: variableStore,
    );

    return resolver.resolve();
  }
}

class _RequestDraftResolver {
  const _RequestDraftResolver({
    required this.draft,
    required this.variableStore,
  });

  final RequestDraft draft;
  final RequestVariableStore variableStore;

  /// Builds the final resolved request plus any blocking resolution issues.
  ResolvedRequest resolve() {
    final context = _ResolutionContext.from(
      draft: draft,
      variableStore: variableStore,
    );

    return ResolvedRequest(
      request: RequestDraft(
        method: draft.method,
        url: context.resolveText(draft.url, source: 'url'),
        queryParameters: draft.queryParameters
            .map((item) => context.resolveKeyValueItem(item, source: 'query'))
            .toList(growable: false),
        headers: draft.headers
            .map((item) => context.resolveKeyValueItem(item, source: 'header'))
            .toList(growable: false),
        tests: draft.tests,
        variables: draft.variables,
        body: context.resolveBody(draft.body),
        auth: context.resolveAuth(draft.auth),
        settings: draft.settings,
        timeout: draft.timeout,
        verifySsl: draft.verifySsl,
      ),
      resolvedVariables: context.resolvedVariables,
      issues: context.issues,
    );
  }
}

class _ResolutionContext {
  _ResolutionContext({
    required this.requestVariables,
    required this.environmentVariables,
    required this.globalVariables,
  });

  final Map<String, RequestVariable> requestVariables;
  final Map<String, RequestVariable> environmentVariables;
  final Map<String, RequestVariable> globalVariables;
  final Map<String, String> _resolvedVariables = <String, String>{};
  final List<RequestResolutionIssue> _issues = <RequestResolutionIssue>[];
  final Set<String> _issueDeduplication = <String>{};

  /// Creates a resolution context with the three supported variable scopes indexed by key.
  factory _ResolutionContext.from({
    required RequestDraft draft,
    required RequestVariableStore variableStore,
  }) {
    final selectedEnvironment = variableStore.selectedEnvironment;

    return _ResolutionContext(
      requestVariables: _indexVariables(draft.variables),
      environmentVariables: _indexVariables(
        selectedEnvironment != null && selectedEnvironment.isUsable
            ? selectedEnvironment.variables
            : const <RequestVariable>[],
      ),
      globalVariables: _indexVariables(variableStore.globalVariables),
    );
  }

  /// Exposes the resolved variables as an immutable snapshot for later pipeline steps.
  Map<String, String> get resolvedVariables =>
      Map<String, String>.unmodifiable(_resolvedVariables);

  /// Exposes the collected issues as an immutable snapshot for validation and UI feedback.
  List<RequestResolutionIssue> get issues =>
      List<RequestResolutionIssue>.unmodifiable(_issues);

  /// Resolves placeholders inside a single raw string while preserving unresolved tokens.
  String resolveText(
    String input, {
    required String source,
    bool isEnabled = true,
  }) {
    if (!isEnabled || input.isEmpty) {
      return input;
    }

    return input.replaceAllMapped(ResolveRequestUseCase._placeholderPattern, (
      match,
    ) {
      final variableKey = match.group(1)?.trim() ?? '';
      final placeholder = match.group(0) ?? '';

      if (variableKey.isEmpty) {
        return placeholder;
      }

      final lookupResult = _lookupVariable(variableKey);
      if (lookupResult case _ResolvedVariableLookup(value: final value)) {
        _resolvedVariables[variableKey] = value;
        return value;
      }

      if (lookupResult case _UnresolvedVariableLookup(:final issueType)) {
        _recordIssue(
          type: issueType,
          variableKey: variableKey,
          source: source,
          placeholder: placeholder,
        );
      }

      return placeholder;
    });
  }

  /// Resolves placeholders inside one key/value row and skips disabled rows entirely.
  KeyValueItem resolveKeyValueItem(
    KeyValueItem item, {
    required String source,
  }) {
    if (!item.isEnabled) {
      return item;
    }

    final resolvedKey = resolveText(
      item.key,
      source: '$source.key:${item.key}',
    );
    final resolvedValue = resolveText(
      item.value,
      source: '$source.value:${item.key}',
    );

    return KeyValueItem(
      key: resolvedKey,
      value: resolvedValue,
      isEnabled: item.isEnabled,
      type: item.type,
      contentType: item.contentType,
      description: item.description,
    );
  }

  /// Resolves placeholders only for the currently active request body mode.
  RequestBodyDraft resolveBody(RequestBodyDraft body) {
    switch (body.type) {
      case RequestBodyType.none:
        return body;
      case RequestBodyType.raw:
        return RequestBodyDraft(
          type: body.type,
          raw: body.raw.copyWith(
            content: resolveText(body.raw.content, source: 'body.raw.content'),
          ),
          formData: body.formData,
          urlEncoded: body.urlEncoded,
          graphQl: body.graphQl,
        );
      case RequestBodyType.formData:
        return RequestBodyDraft(
          type: body.type,
          raw: body.raw,
          formData: body.formData
              .map((item) => resolveKeyValueItem(item, source: 'body.formData'))
              .toList(growable: false),
          urlEncoded: body.urlEncoded,
          graphQl: body.graphQl,
        );
      case RequestBodyType.xWwwFormUrlEncoded:
        return RequestBodyDraft(
          type: body.type,
          raw: body.raw,
          formData: body.formData,
          urlEncoded: body.urlEncoded
              .map(
                (item) => resolveKeyValueItem(item, source: 'body.urlEncoded'),
              )
              .toList(growable: false),
          graphQl: body.graphQl,
        );
      case RequestBodyType.graphql:
        return RequestBodyDraft(
          type: body.type,
          raw: body.raw,
          formData: body.formData,
          urlEncoded: body.urlEncoded,
          graphQl: GraphQlBodyDraft(
            query: resolveText(
              body.graphQl.query,
              source: 'body.graphQl.query',
            ),
            variables: resolveText(
              body.graphQl.variables,
              source: 'body.graphQl.variables',
            ),
            operationName: resolveText(
              body.graphQl.operationName ?? '',
              source: 'body.graphQl.operationName',
            ),
          ),
        );
    }
  }

  /// Resolves placeholders only for the active auth mode so inactive forms stay untouched.
  RequestAuthDraft resolveAuth(RequestAuthDraft auth) {
    switch (auth.type) {
      case AuthType.none:
        return auth;
      case AuthType.basic:
        return RequestAuthDraft(
          type: auth.type,
          basic: BasicAuthDraft(
            username: resolveText(
              auth.basic.username,
              source: 'auth.basic.username',
            ),
            password: resolveText(
              auth.basic.password,
              source: 'auth.basic.password',
            ),
          ),
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.apiKey:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: ApiKeyAuthDraft(
            name: resolveText(auth.apiKey.name, source: 'auth.apiKey.name'),
            value: resolveText(auth.apiKey.value, source: 'auth.apiKey.value'),
            location: auth.apiKey.location,
          ),
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.bearerToken:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: BearerTokenAuthDraft(
            token: resolveText(
              auth.bearerToken.token,
              source: 'auth.bearerToken.token',
            ),
            prefix: resolveText(
              auth.bearerToken.prefix,
              source: 'auth.bearerToken.prefix',
            ),
          ),
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.digest:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: DigestAuthDraft(
            username: resolveText(
              auth.digest.username,
              source: 'auth.digest.username',
            ),
            password: resolveText(
              auth.digest.password,
              source: 'auth.digest.password',
            ),
            realm: resolveText(auth.digest.realm, source: 'auth.digest.realm'),
            nonce: resolveText(auth.digest.nonce, source: 'auth.digest.nonce'),
            algorithm: resolveText(
              auth.digest.algorithm,
              source: 'auth.digest.algorithm',
            ),
            qop: resolveText(auth.digest.qop, source: 'auth.digest.qop'),
            opaque: resolveText(
              auth.digest.opaque,
              source: 'auth.digest.opaque',
            ),
          ),
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.hawk:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: HawkAuthDraft(
            identifier: resolveText(
              auth.hawk.identifier,
              source: 'auth.hawk.identifier',
            ),
            key: resolveText(auth.hawk.key, source: 'auth.hawk.key'),
            algorithm: resolveText(
              auth.hawk.algorithm,
              source: 'auth.hawk.algorithm',
            ),
            app: resolveText(auth.hawk.app, source: 'auth.hawk.app'),
            delegation: resolveText(
              auth.hawk.delegation,
              source: 'auth.hawk.delegation',
            ),
          ),
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.jwt:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: JwtAuthDraft(
            token: resolveText(auth.jwt.token, source: 'auth.jwt.token'),
            header: resolveText(auth.jwt.header, source: 'auth.jwt.header'),
            payload: resolveText(auth.jwt.payload, source: 'auth.jwt.payload'),
            secret: resolveText(auth.jwt.secret, source: 'auth.jwt.secret'),
            algorithm: resolveText(
              auth.jwt.algorithm,
              source: 'auth.jwt.algorithm',
            ),
            base64EncodedSecret: auth.jwt.base64EncodedSecret,
            privateKey: resolveText(
              auth.jwt.privateKey,
              source: 'auth.jwt.privateKey',
            ),
            sendAsHeader: auth.jwt.sendAsHeader,
            prefix: resolveText(auth.jwt.prefix, source: 'auth.jwt.prefix'),
          ),
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.ntlm:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: NtlmAuthDraft(
            username: resolveText(
              auth.ntlm.username,
              source: 'auth.ntlm.username',
            ),
            password: resolveText(
              auth.ntlm.password,
              source: 'auth.ntlm.password',
            ),
            domain: resolveText(auth.ntlm.domain, source: 'auth.ntlm.domain'),
            workstation: resolveText(
              auth.ntlm.workstation,
              source: 'auth.ntlm.workstation',
            ),
          ),
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.awsSignature:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: AwsAuthDraft(
            accessKey: resolveText(
              auth.aws.accessKey,
              source: 'auth.aws.accessKey',
            ),
            secretKey: resolveText(
              auth.aws.secretKey,
              source: 'auth.aws.secretKey',
            ),
            region: resolveText(auth.aws.region, source: 'auth.aws.region'),
            service: resolveText(auth.aws.service, source: 'auth.aws.service'),
            sessionToken: resolveText(
              auth.aws.sessionToken,
              source: 'auth.aws.sessionToken',
            ),
          ),
          oauth1: auth.oauth1,
          oauth2: auth.oauth2,
        );
      case AuthType.oauth1:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: OAuth1AuthDraft(
            consumerKey: resolveText(
              auth.oauth1.consumerKey,
              source: 'auth.oauth1.consumerKey',
            ),
            consumerSecret: resolveText(
              auth.oauth1.consumerSecret,
              source: 'auth.oauth1.consumerSecret',
            ),
            token: resolveText(auth.oauth1.token, source: 'auth.oauth1.token'),
            tokenSecret: resolveText(
              auth.oauth1.tokenSecret,
              source: 'auth.oauth1.tokenSecret',
            ),
            signatureMethod: resolveText(
              auth.oauth1.signatureMethod,
              source: 'auth.oauth1.signatureMethod',
            ),
            verifier: resolveText(
              auth.oauth1.verifier,
              source: 'auth.oauth1.verifier',
            ),
            callback: resolveText(
              auth.oauth1.callback,
              source: 'auth.oauth1.callback',
            ),
            nonce: resolveText(auth.oauth1.nonce, source: 'auth.oauth1.nonce'),
            timestamp: resolveText(
              auth.oauth1.timestamp,
              source: 'auth.oauth1.timestamp',
            ),
            version: resolveText(
              auth.oauth1.version,
              source: 'auth.oauth1.version',
            ),
            realm: resolveText(auth.oauth1.realm, source: 'auth.oauth1.realm'),
            asHeader: auth.oauth1.asHeader,
            includeBodyHash: auth.oauth1.includeBodyHash,
            encodeSignature: auth.oauth1.encodeSignature,
            includeEmptyParameters: auth.oauth1.includeEmptyParameters,
          ),
          oauth2: auth.oauth2,
        );
      case AuthType.oauth2:
        return RequestAuthDraft(
          type: auth.type,
          basic: auth.basic,
          apiKey: auth.apiKey,
          bearerToken: auth.bearerToken,
          digest: auth.digest,
          hawk: auth.hawk,
          jwt: auth.jwt,
          ntlm: auth.ntlm,
          aws: auth.aws,
          oauth1: auth.oauth1,
          oauth2: OAuth2AuthDraft(
            grantType: auth.oauth2.grantType,
            accessToken: resolveText(
              auth.oauth2.accessToken,
              source: 'auth.oauth2.accessToken',
            ),
            addTokenToHeader: auth.oauth2.addTokenToHeader,
            headerPrefix: resolveText(
              auth.oauth2.headerPrefix,
              source: 'auth.oauth2.headerPrefix',
            ),
            authorizationUrl: resolveText(
              auth.oauth2.authorizationUrl,
              source: 'auth.oauth2.authorizationUrl',
            ),
            accessTokenUrl: resolveText(
              auth.oauth2.accessTokenUrl,
              source: 'auth.oauth2.accessTokenUrl',
            ),
            redirectUri: resolveText(
              auth.oauth2.redirectUri,
              source: 'auth.oauth2.redirectUri',
            ),
            scope: resolveText(auth.oauth2.scope, source: 'auth.oauth2.scope'),
            usePkce: auth.oauth2.usePkce,
            pkceMethod: auth.oauth2.pkceMethod,
            state: resolveText(auth.oauth2.state, source: 'auth.oauth2.state'),
            clientAuthentication: auth.oauth2.clientAuthentication,
            authUrlParams: auth.oauth2.authUrlParams
                .map(
                  (item) => resolveKeyValueItem(
                    item,
                    source: 'auth.oauth2.authUrlParams',
                  ),
                )
                .toList(growable: false),
            tokenRequestParams: auth.oauth2.tokenRequestParams
                .map(
                  (item) => resolveKeyValueItem(
                    item,
                    source: 'auth.oauth2.tokenRequestParams',
                  ),
                )
                .toList(growable: false),
            refreshTokenUrl: resolveText(
              auth.oauth2.refreshTokenUrl,
              source: 'auth.oauth2.refreshTokenUrl',
            ),
            authorizationCode: resolveText(
              auth.oauth2.authorizationCode,
              source: 'auth.oauth2.authorizationCode',
            ),
            codeVerifier: resolveText(
              auth.oauth2.codeVerifier,
              source: 'auth.oauth2.codeVerifier',
            ),
            refreshToken: resolveText(
              auth.oauth2.refreshToken,
              source: 'auth.oauth2.refreshToken',
            ),
            clientId: resolveText(
              auth.oauth2.clientId,
              source: 'auth.oauth2.clientId',
            ),
            clientSecret: resolveText(
              auth.oauth2.clientSecret,
              source: 'auth.oauth2.clientSecret',
            ),
            tokenUrl: resolveText(
              auth.oauth2.tokenUrl,
              source: 'auth.oauth2.tokenUrl',
            ),
            scopes: auth.oauth2.scopes
                .map((scope) => resolveText(scope, source: 'auth.oauth2.scope'))
                .toList(growable: false),
          ),
        );
    }
  }

  /// Indexes variables by key so the latest entry in a scope wins during lookups.
  static Map<String, RequestVariable> _indexVariables(
    List<RequestVariable> variables,
  ) {
    final indexedVariables = <String, RequestVariable>{};

    for (final variable in variables) {
      final key = variable.key.trim();
      if (key.isEmpty) {
        continue;
      }

      indexedVariables[key] = variable;
    }

    return indexedVariables;
  }

  /// Resolves one variable key across request, environment, then global scope with fallback.
  _VariableLookup _lookupVariable(String key) {
    RequestVariable? disabledCandidate;
    RequestVariable? emptyCandidate;

    for (final variable in _orderedCandidatesFor(key)) {
      if (!variable.isEnabled) {
        disabledCandidate ??= variable;
        continue;
      }

      final value = variable.effectiveValue;
      if (value.trim().isEmpty) {
        emptyCandidate ??= variable;
        continue;
      }

      return _ResolvedVariableLookup(value);
    }

    if (disabledCandidate != null) {
      return const _UnresolvedVariableLookup(
        RequestResolutionIssueType.disabledVariable,
      );
    }

    if (emptyCandidate != null) {
      return const _UnresolvedVariableLookup(
        RequestResolutionIssueType.emptyVariable,
      );
    }

    return const _UnresolvedVariableLookup(
      RequestResolutionIssueType.missingVariable,
    );
  }

  /// Returns candidate variables ordered by resolution priority.
  Iterable<RequestVariable> _orderedCandidatesFor(String key) sync* {
    final requestVariable = requestVariables[key];
    if (requestVariable != null) {
      yield requestVariable;
    }

    final environmentVariable = environmentVariables[key];
    if (environmentVariable != null) {
      yield environmentVariable;
    }

    final globalVariable = globalVariables[key];
    if (globalVariable != null) {
      yield globalVariable;
    }
  }

  /// Records one issue per source/key/type tuple so repeated placeholders do not spam the UI.
  void _recordIssue({
    required RequestResolutionIssueType type,
    required String variableKey,
    required String source,
    required String placeholder,
  }) {
    final signature = '$source|$variableKey|${type.name}';
    if (_issueDeduplication.contains(signature)) {
      return;
    }

    _issueDeduplication.add(signature);
    _issues.add(
      RequestResolutionIssue(
        type: type,
        variableKey: variableKey,
        source: source,
        placeholder: placeholder,
      ),
    );
  }
}

sealed class _VariableLookup {
  const _VariableLookup();
}

class _ResolvedVariableLookup extends _VariableLookup {
  const _ResolvedVariableLookup(this.value);

  final String value;
}

class _UnresolvedVariableLookup extends _VariableLookup {
  const _UnresolvedVariableLookup(this.issueType);

  final RequestResolutionIssueType issueType;
}
