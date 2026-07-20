import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../domain/entities/web_socket_request_entity.dart';
import '../../domain/entities/web_socket_settings_entity.dart';
import '../../domain/repositories/web_socket_repository.dart';
import 'web_socket_oauth_secret_store.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  /// Creates the repository with an injectable auth secret store for tests.
  WebSocketRepositoryImpl({
    WebSocketOAuthSecretStore oauthSecretStore =
        const FlutterSecureWebSocketOAuthSecretStore(),
  }) : _oauthSecretStore = oauthSecretStore;

  static const _storageKey = 'websockets_requests_list';

  final WebSocketOAuthSecretStore _oauthSecretStore;
  List<WebSocketRequestEntity>? _cachedRequests;

  /// Restores saved WebSocket requests and merges auth secrets from secure storage.
  @override
  Future<List<WebSocketRequestEntity>> getRequests() async {
    final cached = _cachedRequests;
    if (cached != null) {
      return cached;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawList = preferences.getString(_storageKey);
    if (rawList == null || rawList.trim().isEmpty) {
      _cachedRequests = const <WebSocketRequestEntity>[];
      return const <WebSocketRequestEntity>[];
    }

    try {
      final decoded = jsonDecode(rawList);
      if (decoded is! List) {
        _cachedRequests = const <WebSocketRequestEntity>[];
        return const <WebSocketRequestEntity>[];
      }

      final requests = await Future.wait(
        decoded.whereType<Map>().map(
          (item) => _requestFromJson(Map<String, dynamic>.from(item)),
        ),
      );
      _cachedRequests = requests;
      return requests;
    } catch (_) {
      _cachedRequests = const <WebSocketRequestEntity>[];
      return const <WebSocketRequestEntity>[];
    }
  }

  /// Saves a new WebSocket request and any auth secrets it owns.
  @override
  Future<WebSocketRequestEntity> createRequest(
    WebSocketRequestEntity request,
  ) async {
    final requests = List<WebSocketRequestEntity>.from(await getRequests());
    requests.add(request);
    _cachedRequests = requests;
    await _persist(requests);
    return request;
  }

  /// Updates a WebSocket request and refreshes any auth secrets it owns.
  @override
  Future<WebSocketRequestEntity> updateRequest(
    WebSocketRequestEntity request,
  ) async {
    final requests = List<WebSocketRequestEntity>.from(await getRequests());
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      requests[index] = request;
    } else {
      requests.add(request);
    }
    _cachedRequests = requests;
    await _persist(requests);
    return request;
  }

  /// Deletes a WebSocket request and its auth secrets.
  @override
  Future<void> deleteRequest(String id) async {
    final requests = List<WebSocketRequestEntity>.from(await getRequests());
    requests.removeWhere((r) => r.id == id);
    _cachedRequests = requests;
    await _oauthSecretStore.delete(id);
    await _oauthSecretStore.deleteOAuth2(id);
    await _oauthSecretStore.deleteApiKey(id);
    await _oauthSecretStore.deleteBearerToken(id);
    await _oauthSecretStore.deleteDigestPassword(id);
    await _oauthSecretStore.deleteNtlmPassword(id);
    await _oauthSecretStore.deleteHawkKey(id);
    await _oauthSecretStore.deleteJwt(id);
    await _oauthSecretStore.deleteAws(id);
    await _persist(requests);
  }

  /// Persists requests in JSON while keeping auth secrets in secure storage.
  Future<void> _persist(List<WebSocketRequestEntity> requests) async {
    final preferences = await SharedPreferences.getInstance();
    for (final request in requests) {
      await _persistAuthSecrets(request);
    }
    final raw = jsonEncode(
      requests.map(_requestToJson).toList(growable: false),
    );
    await preferences.setString(_storageKey, raw);
  }

  /// Stores or clears secrets for the request's current auth mode.
  Future<void> _persistAuthSecrets(WebSocketRequestEntity request) async {
    if (request.auth.type == AuthType.oauth1) {
      final oauth1 = request.auth.oauth1;
      if (oauth1.consumerSecret.isEmpty && oauth1.tokenSecret.isEmpty) {
        await _oauthSecretStore.delete(request.id);
      } else {
        await _oauthSecretStore.write(
          requestId: request.id,
          consumerSecret: oauth1.consumerSecret,
          tokenSecret: oauth1.tokenSecret,
        );
      }
    } else {
      await _oauthSecretStore.delete(request.id);
    }

    if (request.auth.type == AuthType.oauth2) {
      final oauth2 = request.auth.oauth2;
      final secrets = OAuth2SecretValues(
        accessToken: oauth2.accessToken,
        refreshToken: oauth2.refreshToken,
        clientSecret: oauth2.clientSecret,
        password: oauth2.password,
        authorizationCode: oauth2.authorizationCode,
        codeVerifier: oauth2.codeVerifier,
      );
      if (secrets.isEmpty) {
        await _oauthSecretStore.deleteOAuth2(request.id);
      } else {
        await _oauthSecretStore.writeOAuth2(
          requestId: request.id,
          secrets: secrets,
        );
      }
    } else {
      await _oauthSecretStore.deleteOAuth2(request.id);
    }

    if (request.auth.type == AuthType.apiKey) {
      await _oauthSecretStore.writeApiKey(
        requestId: request.id,
        value: request.auth.apiKey.value,
      );
    } else {
      await _oauthSecretStore.deleteApiKey(request.id);
    }

    if (request.auth.type == AuthType.bearerToken) {
      await _oauthSecretStore.writeBearerToken(
        requestId: request.id,
        value: request.auth.bearerToken.token,
      );
    } else {
      await _oauthSecretStore.deleteBearerToken(request.id);
    }

    if (request.auth.type == AuthType.digest) {
      await _oauthSecretStore.writeDigestPassword(
        requestId: request.id,
        value: request.auth.digest.password,
      );
    } else {
      await _oauthSecretStore.deleteDigestPassword(request.id);

      if (request.auth.type == AuthType.ntlm) {
        await _oauthSecretStore.writeNtlmPassword(
          requestId: request.id,
          value: request.auth.ntlm.password,
        );
      } else {
        await _oauthSecretStore.deleteNtlmPassword(request.id);
      }
    }

    if (request.auth.type == AuthType.hawk) {
      await _oauthSecretStore.writeHawkKey(
        requestId: request.id,
        value: request.auth.hawk.key,
      );
    } else {
      await _oauthSecretStore.deleteHawkKey(request.id);
    }

    if (request.auth.type == AuthType.jwt) {
      final secrets = JwtSecretValues(
        secret: request.auth.jwt.secret,
        privateKey: request.auth.jwt.privateKey,
      );
      if (secrets.isEmpty) {
        await _oauthSecretStore.deleteJwt(request.id);
      } else {
        await _oauthSecretStore.writeJwt(
          requestId: request.id,
          secrets: secrets,
        );
      }
    } else {
      await _oauthSecretStore.deleteJwt(request.id);
    }

    if (request.auth.type == AuthType.awsSignature) {
      final secrets = AwsSecretValues(
        secretKey: request.auth.aws.secretKey,
        sessionToken: request.auth.aws.sessionToken,
      );
      if (secrets.isEmpty) {
        await _oauthSecretStore.deleteAws(request.id);
      } else {
        await _oauthSecretStore.writeAws(
          requestId: request.id,
          secrets: secrets,
        );
      }
    } else {
      await _oauthSecretStore.deleteAws(request.id);
    }
  }

  /// Maps a WebSocket request into the persisted JSON payload.
  Map<String, Object?> _requestToJson(WebSocketRequestEntity request) => {
    'id': request.id,
    'name': request.name,
    'url': request.url,
    'queryParameters': _withoutAuthSystemRows(
      request.queryParameters,
    ).map(_keyValueItemToJson).toList(growable: false),
    'headers': _withoutAuthSystemRows(
      request.headers,
    ).map(_keyValueItemToJson).toList(growable: false),
    'auth': _requestAuthDraftToJson(request.auth),
    'settings': {
      'handshakeTimeoutSeconds': request.settings.handshakeTimeoutSeconds,
      'verifySsl': request.settings.verifySsl,
    },
    'createdAt': request.createdAt?.toIso8601String(),
    'updatedAt': request.updatedAt?.toIso8601String(),
  };

  /// Maps stored JSON into a domain request and restores secure auth secrets.
  Future<WebSocketRequestEntity> _requestFromJson(
    Map<String, dynamic> json,
  ) async {
    final requestId = json['id'] as String? ?? '';
    final authJson = _mapFromJson(json['auth']);
    final auth = await _requestAuthDraftFromJson(requestId, authJson);

    return WebSocketRequestEntity(
      id: requestId,
      name: json['name'] as String? ?? 'Untitled Request',
      url: json['url'] as String? ?? '',
      queryParameters: _withoutAuthSystemRows(
        _listFromJson(json['queryParameters'], _keyValueItemFromJson),
      ),
      headers: _withoutAuthSystemRows(
        _listFromJson(json['headers'], _keyValueItemFromJson),
      ),
      auth: auth,
      settings: _settingsFromJson(_mapFromJson(json['settings'])),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Maps stored settings JSON into a WebSocket settings entity.
  WebSocketSettingsEntity _settingsFromJson(Map<String, dynamic> json) =>
      WebSocketSettingsEntity(
        handshakeTimeoutSeconds: json['handshakeTimeoutSeconds'] as int? ?? 30,
        verifySsl: json['verifySsl'] as bool? ?? true,
      );

  /// Removes OAuth and API Key-owned generated rows from persisted drafts.
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
            !item.isSystemGeneratedJwtQueryParameter &&
            !item.isSystemGeneratedAwsHeader &&
            !item.isSystemGeneratedAwsQueryParameter,
      )
      .toList(growable: false);

  /// Maps a key-value row into JSON.
  Map<String, Object?> _keyValueItemToJson(KeyValueItem item) => {
    'key': item.key,
    'value': item.value,
    'isEnabled': item.isEnabled,
    'type': item.type.name,
    'contentType': item.contentType,
    'description': item.description,
    'source': item.source.name,
    'systemTag': item.systemTag,
  };

  /// Maps stored key-value JSON into a row.
  KeyValueItem _keyValueItemFromJson(Map<String, dynamic> json) => KeyValueItem(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    isEnabled: json['isEnabled'] as bool? ?? true,
    type: _keyValueItemTypeFromName(json['type'] as String?),
    contentType: json['contentType'] as String? ?? '',
    description: json['description'] as String? ?? '',
    source: _requestHeaderSourceFromName(json['source'] as String?),
    systemTag: json['systemTag'] as String? ?? '',
  );

  /// Restores the persisted key-value row type.
  KeyValueItemType _keyValueItemTypeFromName(String? value) =>
      value == 'file' ? KeyValueItemType.file : KeyValueItemType.text;

  /// Restores the persisted key-value ownership source.
  RequestHeaderSource _requestHeaderSourceFromName(String? value) =>
      _enumValueOrFallback(
        RequestHeaderSource.values,
        value,
        RequestHeaderSource.user,
      );

  /// Maps auth drafts into JSON while omitting auth secrets.
  Map<String, Object?> _requestAuthDraftToJson(RequestAuthDraft auth) => {
    'type': auth.type.name,
    'basic': {'username': auth.basic.username, 'password': auth.basic.password},
    'apiKey': {
      'name': auth.apiKey.name,
      'location': auth.apiKey.location.name,
      'isCustomName': auth.apiKey.isCustomName,
    },
    'bearerToken': {'prefix': auth.bearerToken.prefix},
    'digest': {
      'username': auth.digest.username,
      'realm': auth.digest.realm,
      'nonce': auth.digest.nonce,
      'algorithm': auth.digest.algorithm,
      'qop': auth.digest.qop,
      'nonceCount': auth.digest.nonceCount,
      'clientNonce': auth.digest.clientNonce,
      'opaque': auth.digest.opaque,
    },
    'hawk': {
      'identifier': auth.hawk.identifier,
      'algorithm': auth.hawk.algorithm,
      'user': auth.hawk.user,
      'nonce': auth.hawk.nonce,
      'ext': auth.hawk.ext,
      'app': auth.hawk.app,
      'delegation': auth.hawk.delegation,
      'timestamp': auth.hawk.timestamp,
      'includePayloadHash': auth.hawk.includePayloadHash,
    },
    'jwt': {
      'header': auth.jwt.header,
      'payload': auth.jwt.payload,
      'algorithm': auth.jwt.algorithm,
      'base64EncodedSecret': auth.jwt.base64EncodedSecret,
      'sendAsHeader': auth.jwt.sendAsHeader,
      'prefix': auth.jwt.prefix,
    },
    'ntlm': {
      'username': auth.ntlm.username,
      'domain': auth.ntlm.domain,
      'workstation': auth.ntlm.workstation,
    },
    'aws': {
      'accessKey': auth.aws.accessKey,
      'region': auth.aws.region,
      'service': auth.aws.service,
      'asHeader': auth.aws.asHeader,
    },
    'oauth1': {
      'consumerKey': auth.oauth1.consumerKey,
      'token': auth.oauth1.token,
      'signatureMethod': auth.oauth1.signatureMethod,
      'realm': auth.oauth1.realm,
      'version': auth.oauth1.version,
      'nonce': auth.oauth1.nonce,
      'timestamp': auth.oauth1.timestamp,
      'verifier': auth.oauth1.verifier,
      'callback': auth.oauth1.callback,
      'asHeader': auth.oauth1.asHeader,
      'includeEmptyParameters': auth.oauth1.includeEmptyParameters,
      'includeBodyHash': auth.oauth1.includeBodyHash,
      'encodeSignature': auth.oauth1.encodeSignature,
    },
    'oauth2': {
      'grantType': auth.oauth2.grantType.name,
      'addTokenToHeader': auth.oauth2.addTokenToHeader,
      'headerPrefix': auth.oauth2.headerPrefix,
      'authorizationUrl': auth.oauth2.authorizationUrl,
      'accessTokenUrl': auth.oauth2.accessTokenUrl,
      'redirectUri': auth.oauth2.redirectUri,
      'scope': auth.oauth2.scope,
      'usePkce': auth.oauth2.usePkce,
      'pkceMethod': auth.oauth2.pkceMethod.name,
      'state': auth.oauth2.state,
      'clientAuthentication': auth.oauth2.clientAuthentication.name,
      'authUrlParams': auth.oauth2.authUrlParams
          .map(_keyValueItemToJson)
          .toList(growable: false),
      'tokenRequestParams': auth.oauth2.tokenRequestParams
          .map(_keyValueItemToJson)
          .toList(growable: false),
      'refreshTokenUrl': auth.oauth2.refreshTokenUrl,
      'clientId': auth.oauth2.clientId,
      'tokenUrl': auth.oauth2.tokenUrl,
      'scopes': auth.oauth2.scopes,
      'username': auth.oauth2.username,
    },
  };

  /// Maps stored auth JSON into a draft and restores secure secrets.
  Future<RequestAuthDraft> _requestAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async => RequestAuthDraft(
    type: _authTypeFromName(json['type'] as String?),
    basic: _basicAuthDraftFromJson(_mapFromJson(json['basic'])),
    apiKey: await _apiKeyAuthDraftFromJson(
      requestId,
      _mapFromJson(json['apiKey']),
    ),
    bearerToken: await _bearerTokenAuthDraftFromJson(
      requestId,
      _mapFromJson(json['bearerToken']),
    ),
    digest: await _digestAuthDraftFromJson(
      requestId,
      _mapFromJson(json['digest']),
    ),
    ntlm: await _ntlmAuthDraftFromJson(requestId, _mapFromJson(json['ntlm'])),
    hawk: await _hawkAuthDraftFromJson(requestId, _mapFromJson(json['hawk'])),
    jwt: await _jwtAuthDraftFromJson(requestId, _mapFromJson(json['jwt'])),
    aws: await _awsAuthDraftFromJson(requestId, _mapFromJson(json['aws'])),
    oauth1: await _oauth1AuthDraftFromJson(
      requestId,
      _mapFromJson(json['oauth1']),
    ),
    oauth2: await _oauth2AuthDraftFromJson(
      requestId,
      _mapFromJson(json['oauth2']),
    ),
  );

  /// Maps stored Basic auth JSON into a draft.
  BasicAuthDraft _basicAuthDraftFromJson(Map<String, dynamic> json) =>
      BasicAuthDraft(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  /// Maps stored API key config into a draft and migrates legacy plaintext.
  Future<ApiKeyAuthDraft> _apiKeyAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secureValue = await _oauthSecretStore.readApiKey(requestId);
    final legacyValue = json['value'] as String? ?? '';
    final value = secureValue.isNotEmpty ? secureValue : legacyValue;
    if (legacyValue.isNotEmpty) {
      await _oauthSecretStore.writeApiKey(requestId: requestId, value: value);
    }

    return ApiKeyAuthDraft(
      name: json['name'] as String? ?? '',
      value: value,
      location: _apiKeyLocationFromName(json['location'] as String?),
      isCustomName: json['isCustomName'] as bool? ?? false,
    );
  }

  /// Maps stored Bearer auth JSON into a draft.
  Future<BearerTokenAuthDraft> _bearerTokenAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secureToken = await _oauthSecretStore.readBearerToken(requestId);
    final legacyToken = json['token'] as String? ?? '';
    final token = secureToken.isNotEmpty ? secureToken : legacyToken;
    if (legacyToken.isNotEmpty) {
      await _oauthSecretStore.writeBearerToken(
        requestId: requestId,
        value: token,
      );
    }

    return BearerTokenAuthDraft(
      token: token,
      prefix: json['prefix'] as String? ?? 'Bearer',
    );
  }

  /// Maps stored Digest auth JSON into a draft and migrates legacy plaintext.
  Future<DigestAuthDraft> _digestAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final securePassword = await _oauthSecretStore.readDigestPassword(
      requestId,
    );
    final legacyPassword = json['password'] as String? ?? '';
    final password = securePassword.isNotEmpty
        ? securePassword
        : legacyPassword;
    if (legacyPassword.isNotEmpty) {
      await _oauthSecretStore.writeDigestPassword(
        requestId: requestId,
        value: password,
      );
    }

    return DigestAuthDraft(
      username: json['username'] as String? ?? '',
      password: password,
      realm: json['realm'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'MD5',
      qop: json['qop'] as String? ?? '',
      nonceCount: json['nonceCount'] as String? ?? '',
      clientNonce: json['clientNonce'] as String? ?? '',
      opaque: json['opaque'] as String? ?? '',
    );
  }

  /// Restores NTLM credentials and migrates a legacy plaintext password.
  Future<NtlmAuthDraft> _ntlmAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final securePassword = await _oauthSecretStore.readNtlmPassword(requestId);
    final legacyPassword = json['password'] as String? ?? '';
    final password = securePassword.isNotEmpty
        ? securePassword
        : legacyPassword;
    if (legacyPassword.isNotEmpty) {
      await _oauthSecretStore.writeNtlmPassword(
        requestId: requestId,
        value: password,
      );
    }

    return NtlmAuthDraft(
      username: json['username'] as String? ?? '',
      password: password,
      domain: json['domain'] as String? ?? '',
      workstation: json['workstation'] as String? ?? '',
    );
  }

  /// Maps stored Hawk auth JSON into a draft and migrates the legacy key.
  Future<HawkAuthDraft> _hawkAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secureKey = await _oauthSecretStore.readHawkKey(requestId);
    final legacyKey = json['key'] as String? ?? '';
    final key = secureKey.isNotEmpty ? secureKey : legacyKey;
    if (legacyKey.isNotEmpty) {
      await _oauthSecretStore.writeHawkKey(requestId: requestId, value: key);
    }

    return HawkAuthDraft(
      identifier: json['identifier'] as String? ?? '',
      key: key,
      algorithm: json['algorithm'] as String? ?? 'sha256',
      user: json['user'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      app: json['app'] as String? ?? '',
      delegation: json['delegation'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      includePayloadHash: json['includePayloadHash'] as bool? ?? false,
    );
  }

  /// Restores JWT configuration and migrates legacy signing values to secure storage.
  Future<JwtAuthDraft> _jwtAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secureSecrets = await _oauthSecretStore.readJwt(requestId);
    final legacySecret = json['secret'] as String? ?? '';
    final legacyPrivateKey = json['privateKey'] as String? ?? '';
    final secret = secureSecrets.secret.isNotEmpty
        ? secureSecrets.secret
        : legacySecret;
    final privateKey = secureSecrets.privateKey.isNotEmpty
        ? secureSecrets.privateKey
        : legacyPrivateKey;
    if (legacySecret.isNotEmpty || legacyPrivateKey.isNotEmpty) {
      await _oauthSecretStore.writeJwt(
        requestId: requestId,
        secrets: JwtSecretValues(secret: secret, privateKey: privateKey),
      );
    }

    return JwtAuthDraft(
      header: json['header'] as String? ?? '',
      payload: json['payload'] as String? ?? '',
      secret: secret,
      algorithm: json['algorithm'] as String? ?? 'HS256',
      base64EncodedSecret: json['base64EncodedSecret'] as bool? ?? false,
      privateKey: privateKey,
      sendAsHeader: json['sendAsHeader'] as bool? ?? true,
      prefix: json['prefix'] as String? ?? 'Bearer',
    );
  }

  /// Restores AWS config and migrates legacy signing secrets to secure storage.
  Future<AwsAuthDraft> _awsAuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secure = await _oauthSecretStore.readAws(requestId);
    final legacySecretKey = json['secretKey'] as String? ?? '';
    final legacySessionToken = json['sessionToken'] as String? ?? '';
    final secretKey = secure.secretKey.isNotEmpty
        ? secure.secretKey
        : legacySecretKey;
    final sessionToken = secure.sessionToken.isNotEmpty
        ? secure.sessionToken
        : legacySessionToken;
    if (legacySecretKey.isNotEmpty || legacySessionToken.isNotEmpty) {
      await _oauthSecretStore.writeAws(
        requestId: requestId,
        secrets: AwsSecretValues(
          secretKey: secretKey,
          sessionToken: sessionToken,
        ),
      );
    }

    return AwsAuthDraft(
      accessKey: json['accessKey'] as String? ?? '',
      secretKey: secretKey,
      region: json['region'] as String? ?? '',
      service: json['service'] as String? ?? '',
      sessionToken: sessionToken,
      asHeader: json['asHeader'] as bool? ?? true,
    );
  }

  /// Maps stored OAuth1 auth JSON into a draft and migrates legacy secrets.
  Future<OAuth1AuthDraft> _oauth1AuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secureSecrets = await _oauthSecretStore.read(requestId);
    final legacyConsumerSecret = json['consumerSecret'] as String? ?? '';
    final legacyTokenSecret = json['tokenSecret'] as String? ?? '';
    final consumerSecret = secureSecrets.consumerSecret.isNotEmpty
        ? secureSecrets.consumerSecret
        : legacyConsumerSecret;
    final tokenSecret = secureSecrets.tokenSecret.isNotEmpty
        ? secureSecrets.tokenSecret
        : legacyTokenSecret;

    if (legacyConsumerSecret.isNotEmpty || legacyTokenSecret.isNotEmpty) {
      await _oauthSecretStore.write(
        requestId: requestId,
        consumerSecret: consumerSecret,
        tokenSecret: tokenSecret,
      );
    }

    return OAuth1AuthDraft(
      consumerKey: json['consumerKey'] as String? ?? '',
      consumerSecret: consumerSecret,
      token: json['token'] as String? ?? '',
      tokenSecret: tokenSecret,
      signatureMethod: json['signatureMethod'] as String? ?? 'HMAC-SHA1',
      verifier: json['verifier'] as String? ?? '',
      callback: json['callback'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      version: json['version'] as String? ?? '1.0',
      realm: json['realm'] as String? ?? '',
      asHeader: json['asHeader'] as bool? ?? false,
      includeBodyHash: json['includeBodyHash'] as bool? ?? false,
      encodeSignature: json['encodeSignature'] as bool? ?? true,
      includeEmptyParameters: json['includeEmptyParameters'] as bool? ?? false,
    );
  }

  /// Maps stored OAuth2 config into a draft and migrates legacy secrets.
  Future<OAuth2AuthDraft> _oauth2AuthDraftFromJson(
    String requestId,
    Map<String, dynamic> json,
  ) async {
    final secure = await _oauthSecretStore.readOAuth2(requestId);
    final legacy = OAuth2SecretValues(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      password: json['password'] as String? ?? '',
      authorizationCode: json['authorizationCode'] as String? ?? '',
      codeVerifier: json['codeVerifier'] as String? ?? '',
    );
    final secrets = OAuth2SecretValues(
      accessToken: secure.accessToken.isNotEmpty
          ? secure.accessToken
          : legacy.accessToken,
      refreshToken: secure.refreshToken.isNotEmpty
          ? secure.refreshToken
          : legacy.refreshToken,
      clientSecret: secure.clientSecret.isNotEmpty
          ? secure.clientSecret
          : legacy.clientSecret,
      password: secure.password.isNotEmpty ? secure.password : legacy.password,
      authorizationCode: secure.authorizationCode.isNotEmpty
          ? secure.authorizationCode
          : legacy.authorizationCode,
      codeVerifier: secure.codeVerifier.isNotEmpty
          ? secure.codeVerifier
          : legacy.codeVerifier,
    );
    if (!legacy.isEmpty) {
      await _oauthSecretStore.writeOAuth2(
        requestId: requestId,
        secrets: secrets,
      );
    }

    return OAuth2AuthDraft(
      grantType: _enumValueOrFallback(
        OAuth2GrantType.values,
        json['grantType'] as String?,
        OAuth2GrantType.manual,
      ),
      accessToken: secrets.accessToken,
      addTokenToHeader: json['addTokenToHeader'] as bool? ?? true,
      headerPrefix: json['headerPrefix'] as String? ?? 'Bearer',
      authorizationUrl: json['authorizationUrl'] as String? ?? '',
      accessTokenUrl: json['accessTokenUrl'] as String? ?? '',
      redirectUri:
          json['redirectUri'] as String? ?? const OAuth2AuthDraft().redirectUri,
      scope: json['scope'] as String? ?? '',
      usePkce: json['usePkce'] as bool? ?? false,
      pkceMethod: _enumValueOrFallback(
        OAuth2PkceMethod.values,
        json['pkceMethod'] as String?,
        OAuth2PkceMethod.sha256,
      ),
      state: json['state'] as String? ?? '',
      clientAuthentication: _enumValueOrFallback(
        OAuth2ClientAuthentication.values,
        json['clientAuthentication'] as String?,
        OAuth2ClientAuthentication.requestBody,
      ),
      authUrlParams: _listFromJson(
        json['authUrlParams'],
        _keyValueItemFromJson,
      ),
      tokenRequestParams: _listFromJson(
        json['tokenRequestParams'],
        _keyValueItemFromJson,
      ),
      refreshTokenUrl: json['refreshTokenUrl'] as String? ?? '',
      authorizationCode: secrets.authorizationCode,
      codeVerifier: secrets.codeVerifier,
      refreshToken: secrets.refreshToken,
      clientId: json['clientId'] as String? ?? '',
      clientSecret: secrets.clientSecret,
      tokenUrl: json['tokenUrl'] as String? ?? '',
      scopes:
          (json['scopes'] as List?)?.whereType<String>().toList() ??
          const <String>[],
      username: json['username'] as String? ?? '',
      password: secrets.password,
    );
  }

  /// Restores the persisted auth type.
  AuthType _authTypeFromName(String? value) =>
      _enumValueOrFallback(AuthType.values, value, AuthType.none);

  /// Restores the persisted API key location.
  ApiKeyLocation _apiKeyLocationFromName(String? value) =>
      _enumValueOrFallback(ApiKeyLocation.values, value, ApiKeyLocation.header);

  /// Maps a JSON list into typed values.
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

  /// Safely maps dynamic JSON into a string-keyed map.
  Map<String, dynamic> _mapFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  /// Restores enum values by name with a fallback for older records.
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
