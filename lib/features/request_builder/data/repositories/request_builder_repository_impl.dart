import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_draft_session.dart';
import '../../domain/entities/request_environment.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/request_variable.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/entities/saved_request_draft.dart';
import '../../domain/repositories/request_builder_repository.dart';

class RequestBuilderRepositoryImpl implements RequestBuilderRepository {
  RequestBuilderRepositoryImpl({RequestDraft? initialDraft})
    : _draft = initialDraft;

  static const RequestDraft _defaultDraft = RequestDraft(
    method: HttpMethod.get,
    url: 'https://api.example.com',
  );
  static const RequestVariableStore _defaultVariableStore =
      RequestVariableStore();

  static const _draftStorageKey = 'request_builder_draft';
  static const _currentDraftSessionStorageKey =
      'request_builder_current_draft_session';
  static const _savedRequestDraftsStorageKey =
      'request_builder_saved_request_drafts';
  static const _variableStoreStorageKey = 'request_builder_variable_store';

  RequestDraft? _draft;
  RequestDraftSession? _currentDraftSession;
  List<SavedRequestDraft>? _savedRequestDrafts;
  RequestVariableStore? _variableStore;

  /// Restores the latest persisted draft, falling back to the in-memory/default value.
  @override
  Future<RequestDraft> getRequestDraft() async {
    final cachedDraft = _draft;
    if (cachedDraft != null) {
      return cachedDraft;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawDraft = preferences.getString(_draftStorageKey);
    if (rawDraft == null || rawDraft.trim().isEmpty) {
      return _defaultDraft;
    }

    try {
      final decodedDraft = _mapFromJson(jsonDecode(rawDraft));
      if (decodedDraft.isEmpty) {
        return _defaultDraft;
      }

      final restoredDraft = _requestDraftFromJson(decodedDraft);
      _draft = restoredDraft;
      return restoredDraft;
    } catch (_) {
      return _defaultDraft;
    }
  }

  /// Persists the active draft so the editor can restore it after an app restart.
  @override
  Future<void> saveRequestDraft(RequestDraft draft) async {
    _draft = draft;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _draftStorageKey,
      jsonEncode(_requestDraftToJson(draft)),
    );
  }

  /// Restores the latest autosaved editing session, falling back to the legacy draft.
  @override
  Future<RequestDraftSession?> getCurrentRequestDraftSession() async {
    final cachedSession = _currentDraftSession;
    if (cachedSession != null) {
      return cachedSession;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_currentDraftSessionStorageKey);
    if (rawSession == null || rawSession.trim().isEmpty) {
      return null;
    }

    try {
      final decodedSession = _mapFromJson(jsonDecode(rawSession));
      if (decodedSession.isEmpty) {
        return null;
      }

      final restoredSession = _requestDraftSessionFromJson(decodedSession);
      _currentDraftSession = restoredSession;
      _draft = restoredSession.draft;
      return restoredSession;
    } catch (_) {
      return null;
    }
  }

  /// Persists the active editing session so in-progress editor changes survive restarts.
  @override
  Future<void> saveCurrentRequestDraftSession(
    RequestDraftSession session,
  ) async {
    _currentDraftSession = session;
    _draft = session.draft;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _currentDraftSessionStorageKey,
      jsonEncode(_requestDraftSessionToJson(session)),
    );
    await preferences.setString(
      _draftStorageKey,
      jsonEncode(_requestDraftToJson(session.draft)),
    );
  }

  /// Clears the autosaved editing session after an explicit discard.
  @override
  Future<void> clearCurrentRequestDraftSession() async {
    _currentDraftSession = null;

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_currentDraftSessionStorageKey);
  }

  /// Restores the saved request list with full draft payloads.
  @override
  Future<List<SavedRequestDraft>> getSavedRequestDrafts() async {
    final cachedRequests = _savedRequestDrafts;
    if (cachedRequests != null) {
      return cachedRequests;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawRequests = preferences.getString(_savedRequestDraftsStorageKey);
    if (rawRequests == null || rawRequests.trim().isEmpty) {
      return const <SavedRequestDraft>[];
    }

    try {
      final decodedRequests = jsonDecode(rawRequests);
      final restoredRequests = _savedRequestDraftListFromJson(decodedRequests);
      _savedRequestDrafts = restoredRequests;
      return restoredRequests;
    } catch (_) {
      return const <SavedRequestDraft>[];
    }
  }

  /// Persists the saved request list with full draft payloads.
  @override
  Future<void> saveSavedRequestDrafts(List<SavedRequestDraft> requests) async {
    _savedRequestDrafts = List<SavedRequestDraft>.unmodifiable(requests);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedRequestDraftsStorageKey,
      jsonEncode(
        requests.map(_savedRequestDraftToJson).toList(growable: false),
      ),
    );
  }

  /// Restores the latest persisted variable store, falling back to the in-memory/default value.
  @override
  Future<RequestVariableStore> getRequestVariableStore() async {
    final cachedStore = _variableStore;
    if (cachedStore != null) {
      return cachedStore;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawStore = preferences.getString(_variableStoreStorageKey);
    if (rawStore == null || rawStore.trim().isEmpty) {
      return _defaultVariableStore;
    }

    try {
      final decodedStore = _mapFromJson(jsonDecode(rawStore));
      if (decodedStore.isEmpty) {
        return _defaultVariableStore;
      }

      final restoredStore = _requestVariableStoreFromJson(decodedStore);
      _variableStore = restoredStore;
      return restoredStore;
    } catch (_) {
      return _defaultVariableStore;
    }
  }

  /// Persists the variable store so environment/global values survive app restarts.
  @override
  Future<void> saveRequestVariableStore(RequestVariableStore store) async {
    _variableStore = store;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _variableStoreStorageKey,
      jsonEncode(_requestVariableStoreToJson(store)),
    );
  }

  Map<String, Object?> _requestDraftToJson(RequestDraft draft) => {
    'method': draft.method.name,
    'url': draft.url,
    'queryParameters': draft.queryParameters
        .map(_keyValueItemToJson)
        .toList(growable: false),
    'headers': draft.headers.map(_keyValueItemToJson).toList(growable: false),
    'variables': draft.variables
        .map(_requestVariableToJson)
        .toList(growable: false),
    'body': _requestBodyDraftToJson(draft.body),
    'auth': _requestAuthDraftToJson(draft.auth),
    'timeoutSeconds': draft.timeout.inSeconds,
    'verifySsl': draft.verifySsl,
  };

  Map<String, Object?> _requestDraftSessionToJson(
    RequestDraftSession session,
  ) => {
    'title': session.title,
    'requestIndex': session.requestIndex,
    'draft': _requestDraftToJson(session.draft),
  };

  RequestDraftSession _requestDraftSessionFromJson(Map<String, dynamic> json) {
    final requestIndex = json['requestIndex'];

    return RequestDraftSession(
      title: json['title'] as String? ?? 'Untitled Request',
      requestIndex: requestIndex is num ? requestIndex.toInt() : null,
      draft: _requestDraftFromJson(_mapFromJson(json['draft'])),
    );
  }

  Map<String, Object?> _savedRequestDraftToJson(SavedRequestDraft request) => {
    'title': request.title,
    'draft': _requestDraftToJson(request.draft),
  };

  SavedRequestDraft _savedRequestDraftFromJson(Map<String, dynamic> json) =>
      SavedRequestDraft(
        title: json['title'] as String? ?? 'Untitled Request',
        draft: _requestDraftFromJson(_mapFromJson(json['draft'])),
      );

  List<SavedRequestDraft> _savedRequestDraftListFromJson(Object? value) {
    if (value is! List) {
      return const <SavedRequestDraft>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => _savedRequestDraftFromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  RequestDraft _requestDraftFromJson(Map<String, dynamic> json) => RequestDraft(
    method: _httpMethodFromName(json['method'] as String?),
    url: json['url'] as String? ?? _defaultDraft.url,
    queryParameters: _listFromJson(
      json['queryParameters'],
      (value) => _keyValueItemFromJson(value),
    ),
    headers: _listFromJson(
      json['headers'],
      (value) => _keyValueItemFromJson(value),
    ),
    variables: _listFromJson(
      json['variables'],
      (value) => _requestVariableFromJson(value),
    ),
    body: _requestBodyDraftFromJson(_mapFromJson(json['body'])),
    auth: _requestAuthDraftFromJson(_mapFromJson(json['auth'])),
    timeout: Duration(seconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 30),
    verifySsl: json['verifySsl'] as bool? ?? true,
  );

  Map<String, Object?> _requestVariableStoreToJson(
    RequestVariableStore store,
  ) => {
    'globalVariables': store.globalVariables
        .map(_requestVariableToJson)
        .toList(growable: false),
    'environments': store.environments
        .map(_requestEnvironmentToJson)
        .toList(growable: false),
    'selectedEnvironmentId': store.selectedEnvironmentId,
  };

  RequestVariableStore _requestVariableStoreFromJson(
    Map<String, dynamic> json,
  ) => RequestVariableStore(
    globalVariables: _listFromJson(
      json['globalVariables'],
      (value) => _requestVariableFromJson(value),
    ),
    environments: _listFromJson(
      json['environments'],
      (value) => _requestEnvironmentFromJson(value),
    ),
    selectedEnvironmentId: json['selectedEnvironmentId'] as String? ?? '',
  );

  Map<String, Object?> _requestBodyDraftToJson(RequestBodyDraft body) => {
    'type': body.type.name,
    'raw': {
      'subtype': body.raw.subtype.name,
      'content': body.raw.content,
    },
    'formData': body.formData.map(_keyValueItemToJson).toList(growable: false),
    'urlEncoded': body.urlEncoded
        .map(_keyValueItemToJson)
        .toList(growable: false),
    'graphQl': {
      'query': body.graphQl.query,
      'variables': body.graphQl.variables,
    },
  };

  RequestBodyDraft _requestBodyDraftFromJson(Map<String, dynamic> json) {
    final legacyTypeName = json['type'] as String?;
    final bodyType = _requestBodyTypeFromName(legacyTypeName);

    return RequestBodyDraft(
      type: bodyType,
      raw: _rawBodyDraftFromJson(
        bodyType: bodyType,
        rawJson: json['raw'],
        legacyJsonBody: json['json'] as String? ?? '',
        legacyRawContentType: json['rawContentType'] as String? ?? '',
      ),
      formData: _listFromJson(
        json['formData'],
        (value) => _keyValueItemFromJson(value),
      ),
      urlEncoded: _listFromJson(
        json['urlEncoded'],
        (value) => _keyValueItemFromJson(value),
      ),
      graphQl: _graphQlBodyDraftFromJson(_mapFromJson(json['graphQl'])),
    );
  }

  /// Maps both the new raw-body structure and the legacy raw/json payload fields.
  RawBodyDraft _rawBodyDraftFromJson({
    required RequestBodyType bodyType,
    required Object? rawJson,
    required String legacyJsonBody,
    required String legacyRawContentType,
  }) {
    if (rawJson is Map) {
      final rawMap = Map<String, dynamic>.from(rawJson);
      return RawBodyDraft(
        subtype: _rawBodySubtypeFromName(rawMap['subtype'] as String?),
        content: rawMap['content'] as String? ?? '',
      );
    }

    if (bodyType == RequestBodyType.raw) {
      return RawBodyDraft(
        subtype: _rawBodySubtypeFromLegacyContentType(legacyRawContentType),
        content: rawJson as String? ?? '',
      );
    }

    if (legacyJsonBody.trim().isNotEmpty) {
      return RawBodyDraft(
        subtype: RawBodySubtype.json,
        content: legacyJsonBody,
      );
    }

    return const RawBodyDraft();
  }

  GraphQlBodyDraft _graphQlBodyDraftFromJson(Map<String, dynamic> json) =>
      GraphQlBodyDraft(
        query: json['query'] as String? ?? '',
        variables: json['variables'] as String? ?? '',
      );

  Map<String, Object?> _requestAuthDraftToJson(RequestAuthDraft auth) => {
    'type': auth.type.name,
    'basic': {'username': auth.basic.username, 'password': auth.basic.password},
    'apiKey': {
      'name': auth.apiKey.name,
      'value': auth.apiKey.value,
      'location': auth.apiKey.location.name,
    },
    'bearerToken': {
      'token': auth.bearerToken.token,
      'prefix': auth.bearerToken.prefix,
    },
    'digest': {
      'username': auth.digest.username,
      'password': auth.digest.password,
      'realm': auth.digest.realm,
      'nonce': auth.digest.nonce,
      'algorithm': auth.digest.algorithm,
      'qop': auth.digest.qop,
      'opaque': auth.digest.opaque,
    },
    'hawk': {
      'identifier': auth.hawk.identifier,
      'key': auth.hawk.key,
      'algorithm': auth.hawk.algorithm,
      'app': auth.hawk.app,
      'delegation': auth.hawk.delegation,
    },
    'jwt': {
      'token': auth.jwt.token,
      'header': auth.jwt.header,
      'payload': auth.jwt.payload,
      'secret': auth.jwt.secret,
      'algorithm': auth.jwt.algorithm,
      'prefix': auth.jwt.prefix,
    },
    'ntlm': {
      'username': auth.ntlm.username,
      'password': auth.ntlm.password,
      'domain': auth.ntlm.domain,
      'workstation': auth.ntlm.workstation,
    },
    'aws': {
      'accessKey': auth.aws.accessKey,
      'secretKey': auth.aws.secretKey,
      'region': auth.aws.region,
      'service': auth.aws.service,
      'sessionToken': auth.aws.sessionToken,
    },
    'oauth1': {
      'consumerKey': auth.oauth1.consumerKey,
      'consumerSecret': auth.oauth1.consumerSecret,
      'token': auth.oauth1.token,
      'tokenSecret': auth.oauth1.tokenSecret,
      'signatureMethod': auth.oauth1.signatureMethod,
      'nonce': auth.oauth1.nonce,
      'timestamp': auth.oauth1.timestamp,
      'version': auth.oauth1.version,
    },
    'oauth2': {
      'accessToken': auth.oauth2.accessToken,
      'refreshToken': auth.oauth2.refreshToken,
      'clientId': auth.oauth2.clientId,
      'clientSecret': auth.oauth2.clientSecret,
      'tokenUrl': auth.oauth2.tokenUrl,
      'scopes': auth.oauth2.scopes,
    },
  };

  RequestAuthDraft _requestAuthDraftFromJson(Map<String, dynamic> json) =>
      RequestAuthDraft(
        type: _authTypeFromName(json['type'] as String?),
        basic: _basicAuthDraftFromJson(_mapFromJson(json['basic'])),
        apiKey: _apiKeyAuthDraftFromJson(_mapFromJson(json['apiKey'])),
        bearerToken: _bearerTokenAuthDraftFromJson(
          _mapFromJson(json['bearerToken']),
        ),
        digest: _digestAuthDraftFromJson(_mapFromJson(json['digest'])),
        hawk: _hawkAuthDraftFromJson(_mapFromJson(json['hawk'])),
        jwt: _jwtAuthDraftFromJson(_mapFromJson(json['jwt'])),
        ntlm: _ntlmAuthDraftFromJson(_mapFromJson(json['ntlm'])),
        aws: _awsAuthDraftFromJson(_mapFromJson(json['aws'])),
        oauth1: _oAuth1AuthDraftFromJson(_mapFromJson(json['oauth1'])),
        oauth2: _oAuth2AuthDraftFromJson(_mapFromJson(json['oauth2'])),
      );

  BasicAuthDraft _basicAuthDraftFromJson(Map<String, dynamic> json) =>
      BasicAuthDraft(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  ApiKeyAuthDraft _apiKeyAuthDraftFromJson(Map<String, dynamic> json) =>
      ApiKeyAuthDraft(
        name: json['name'] as String? ?? '',
        value: json['value'] as String? ?? '',
        location: _apiKeyLocationFromName(json['location'] as String?),
      );

  BearerTokenAuthDraft _bearerTokenAuthDraftFromJson(
    Map<String, dynamic> json,
  ) => BearerTokenAuthDraft(
    token: json['token'] as String? ?? '',
    prefix: json['prefix'] as String? ?? 'Bearer',
  );

  DigestAuthDraft _digestAuthDraftFromJson(Map<String, dynamic> json) =>
      DigestAuthDraft(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        realm: json['realm'] as String? ?? '',
        nonce: json['nonce'] as String? ?? '',
        algorithm: json['algorithm'] as String? ?? 'MD5',
        qop: json['qop'] as String? ?? '',
        opaque: json['opaque'] as String? ?? '',
      );

  HawkAuthDraft _hawkAuthDraftFromJson(Map<String, dynamic> json) =>
      HawkAuthDraft(
        identifier: json['identifier'] as String? ?? '',
        key: json['key'] as String? ?? '',
        algorithm: json['algorithm'] as String? ?? 'sha256',
        app: json['app'] as String? ?? '',
        delegation: json['delegation'] as String? ?? '',
      );

  JwtAuthDraft _jwtAuthDraftFromJson(Map<String, dynamic> json) => JwtAuthDraft(
    token: json['token'] as String? ?? '',
    header: json['header'] as String? ?? '',
    payload: json['payload'] as String? ?? '',
    secret: json['secret'] as String? ?? '',
    algorithm: json['algorithm'] as String? ?? 'HS256',
    prefix: json['prefix'] as String? ?? 'Bearer',
  );

  NtlmAuthDraft _ntlmAuthDraftFromJson(Map<String, dynamic> json) =>
      NtlmAuthDraft(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        domain: json['domain'] as String? ?? '',
        workstation: json['workstation'] as String? ?? '',
      );

  AwsAuthDraft _awsAuthDraftFromJson(Map<String, dynamic> json) => AwsAuthDraft(
    accessKey: json['accessKey'] as String? ?? '',
    secretKey: json['secretKey'] as String? ?? '',
    region: json['region'] as String? ?? '',
    service: json['service'] as String? ?? '',
    sessionToken: json['sessionToken'] as String? ?? '',
  );

  OAuth1AuthDraft _oAuth1AuthDraftFromJson(Map<String, dynamic> json) =>
      OAuth1AuthDraft(
        consumerKey: json['consumerKey'] as String? ?? '',
        consumerSecret: json['consumerSecret'] as String? ?? '',
        token: json['token'] as String? ?? '',
        tokenSecret: json['tokenSecret'] as String? ?? '',
        signatureMethod: json['signatureMethod'] as String? ?? 'HMAC-SHA1',
        nonce: json['nonce'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        version: json['version'] as String? ?? '1.0',
      );

  OAuth2AuthDraft _oAuth2AuthDraftFromJson(Map<String, dynamic> json) =>
      OAuth2AuthDraft(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        clientSecret: json['clientSecret'] as String? ?? '',
        tokenUrl: json['tokenUrl'] as String? ?? '',
        scopes: _stringListFromJson(json['scopes']),
      );

  Map<String, Object?> _requestEnvironmentToJson(
    RequestEnvironment environment,
  ) => {
    'id': environment.id,
    'name': environment.name,
    'variables': environment.variables
        .map(_requestVariableToJson)
        .toList(growable: false),
    'isEnabled': environment.isEnabled,
  };

  RequestEnvironment _requestEnvironmentFromJson(Map<String, dynamic> json) =>
      RequestEnvironment(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        variables: _listFromJson(
          json['variables'],
          (value) => _requestVariableFromJson(value),
        ),
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  Map<String, Object?> _requestVariableToJson(RequestVariable variable) => {
    'key': variable.key,
    'currentValue': variable.currentValue,
    'initialValue': variable.initialValue,
    'scope': variable.scope.name,
    'isEnabled': variable.isEnabled,
    'isSecret': variable.isSecret,
    'description': variable.description,
  };

  RequestVariable _requestVariableFromJson(Map<String, dynamic> json) =>
      RequestVariable(
        key: json['key'] as String? ?? '',
        currentValue: json['currentValue'] as String? ?? '',
        initialValue: json['initialValue'] as String? ?? '',
        scope: _requestVariableScopeFromName(json['scope'] as String?),
        isEnabled: json['isEnabled'] as bool? ?? true,
        isSecret: json['isSecret'] as bool? ?? false,
        description: json['description'] as String? ?? '',
      );

  Map<String, Object?> _keyValueItemToJson(KeyValueItem item) => {
    'key': item.key,
    'value': item.value,
    'isEnabled': item.isEnabled,
    'type': item.type.name,
    'contentType': item.contentType,
    'description': item.description,
  };

  KeyValueItem _keyValueItemFromJson(Map<String, dynamic> json) => KeyValueItem(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    isEnabled: json['isEnabled'] as bool? ?? true,
    type: _keyValueItemTypeFromName(json['type'] as String?),
    contentType: json['contentType'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );

  HttpMethod _httpMethodFromName(String? value) =>
      _enumValueOrFallback(HttpMethod.values, value, HttpMethod.get);

  RequestBodyType _requestBodyTypeFromName(String? value) =>
      switch (value) {
        'json' => RequestBodyType.raw,
        _ => _enumValueOrFallback(
          RequestBodyType.values,
          value,
          RequestBodyType.none,
        ),
      };

  RawBodySubtype _rawBodySubtypeFromName(String? value) => _enumValueOrFallback(
    RawBodySubtype.values,
    value,
    RawBodySubtype.text,
  );

  RawBodySubtype _rawBodySubtypeFromLegacyContentType(String value) {
    final normalized = value.trim().toLowerCase();

    return switch (normalized) {
      'application/json' => RawBodySubtype.json,
      'text/xml' || 'application/xml' => RawBodySubtype.xml,
      'text/html' => RawBodySubtype.html,
      _ => RawBodySubtype.text,
    };
  }

  AuthType _authTypeFromName(String? value) =>
      _enumValueOrFallback(AuthType.values, value, AuthType.none);

  ApiKeyLocation _apiKeyLocationFromName(String? value) =>
      _enumValueOrFallback(ApiKeyLocation.values, value, ApiKeyLocation.header);

  RequestVariableScope _requestVariableScopeFromName(String? value) =>
      _enumValueOrFallback(
        RequestVariableScope.values,
        value,
        RequestVariableScope.request,
      );

  KeyValueItemType _keyValueItemTypeFromName(String? value) =>
      _enumValueOrFallback(
        KeyValueItemType.values,
        value,
        KeyValueItemType.text,
      );

  List<T> _listFromJson<T>(
    Object? value,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  List<String> _stringListFromJson(Object? value) {
    if (value is! List) {
      return <String>[];
    }

    return value.whereType<String>().toList(growable: false);
  }

  Map<String, dynamic> _mapFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  T _enumValueOrFallback<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null || name.trim().isEmpty) {
      return fallback;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return fallback;
  }
}
