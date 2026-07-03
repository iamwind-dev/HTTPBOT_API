import 'collection_import_type.dart';
import '../../../../core/services/oauth2_callback_service.dart';
import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';

class ImportedCollectionVariableEntity {
  const ImportedCollectionVariableEntity({
    required this.name,
    required this.value,
    this.isEnabled = true,
  });

  final String name;
  final String value;
  final bool isEnabled;

  ImportedCollectionVariableEntity copyWith({
    String? name,
    String? value,
    bool? isEnabled,
  }) => ImportedCollectionVariableEntity(
    name: name ?? this.name,
    value: value ?? this.value,
    isEnabled: isEnabled ?? this.isEnabled,
  );
}

class ImportedRequestFieldEntity {
  const ImportedRequestFieldEntity({
    required this.name,
    this.value = '',
    this.description = '',
  });

  final String name;
  final String value;
  final String description;
}

class ImportedCollectionRequestEntity {
  const ImportedCollectionRequestEntity({
    required this.method,
    required this.title,
    required this.url,
    this.baseUrlValue = '',
    this.queryParameters = const <ImportedRequestFieldEntity>[],
    this.headers = const <ImportedRequestFieldEntity>[],
    this.bodyContent = '',
    this.bodyContentType = '',
  });

  final String method;
  final String title;
  final String url;
  final String baseUrlValue;
  final List<ImportedRequestFieldEntity> queryParameters;
  final List<ImportedRequestFieldEntity> headers;
  final String bodyContent;
  final String bodyContentType;

  ImportedCollectionRequestEntity copyWith({
    String? method,
    String? title,
    String? url,
    String? baseUrlValue,
    List<ImportedRequestFieldEntity>? queryParameters,
    List<ImportedRequestFieldEntity>? headers,
    String? bodyContent,
    String? bodyContentType,
  }) => ImportedCollectionRequestEntity(
    method: method ?? this.method,
    title: title ?? this.title,
    url: url ?? this.url,
    baseUrlValue: baseUrlValue ?? this.baseUrlValue,
    queryParameters: queryParameters ?? this.queryParameters,
    headers: headers ?? this.headers,
    bodyContent: bodyContent ?? this.bodyContent,
    bodyContentType: bodyContentType ?? this.bodyContentType,
  );
}

class ImportedCollectionFolderEntity {
  const ImportedCollectionFolderEntity({
    required this.name,
    this.folders = const <ImportedCollectionFolderEntity>[],
    this.requests = const <ImportedCollectionRequestEntity>[],
  });

  final String name;
  final List<ImportedCollectionFolderEntity> folders;
  final List<ImportedCollectionRequestEntity> requests;

  ImportedCollectionFolderEntity copyWith({
    String? name,
    List<ImportedCollectionFolderEntity>? folders,
    List<ImportedCollectionRequestEntity>? requests,
  }) => ImportedCollectionFolderEntity(
    name: name ?? this.name,
    folders: folders ?? this.folders,
    requests: requests ?? this.requests,
  );

  int get requestCount {
    final childFolderRequests = folders.fold<int>(
      0,
      (sum, folder) => sum + folder.requestCount,
    );

    return childFolderRequests + requests.length;
  }
}

class ImportedCollectionEntity {
  const ImportedCollectionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.importType,
    this.variables = const <ImportedCollectionVariableEntity>[],
    this.auth = const RequestAuthDraft.none(),
    this.folders = const [],
    this.rootRequests = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final CollectionImportType importType;
  final List<ImportedCollectionVariableEntity> variables;
  final RequestAuthDraft auth;
  final List<ImportedCollectionFolderEntity> folders;
  final List<ImportedCollectionRequestEntity> rootRequests;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get authLabel => auth.type.label;

  ImportedCollectionEntity copyWith({
    String? name,
    String? description,
    List<ImportedCollectionVariableEntity>? variables,
    RequestAuthDraft? auth,
    List<ImportedCollectionFolderEntity>? folders,
    List<ImportedCollectionRequestEntity>? rootRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearCreatedAt = false,
    bool clearUpdatedAt = false,
  }) => ImportedCollectionEntity(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    importType: importType,
    variables: variables ?? this.variables,
    auth: auth ?? this.auth,
    folders: folders ?? this.folders,
    rootRequests: rootRequests ?? this.rootRequests,
    createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
  );

  int get itemCount => requestCount;

  int get requestCount {
    final folderRequests = folders.fold<int>(
      0,
      (sum, folder) => sum + folder.requestCount,
    );

    return folderRequests + rootRequests.length;
  }
}

extension ImportedCollectionAuthDraftX on RequestAuthDraft {
  RequestAuthDraft copyWithType(AuthType type) => copyWith(type: type);
}

RequestAuthDraft importedCollectionAuthFromLegacyLabel(String? authLabel) {
  final normalized = authLabel?.trim().toLowerCase() ?? '';
  for (final type in AuthType.values) {
    if (type.label.toLowerCase() == normalized) {
      return RequestAuthDraft(type: type);
    }
  }

  if (normalized == 'aws') {
    return const RequestAuthDraft(type: AuthType.awsSignature);
  }

  return const RequestAuthDraft.none();
}

Map<String, Object?> importedCollectionAuthToJson(RequestAuthDraft auth) => {
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
    'nonceCount': auth.digest.nonceCount,
    'clientNonce': auth.digest.clientNonce,
    'opaque': auth.digest.opaque,
  },
  'hawk': {
    'identifier': auth.hawk.identifier,
    'key': auth.hawk.key,
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
    'token': auth.jwt.token,
    'header': auth.jwt.header,
    'payload': auth.jwt.payload,
    'secret': auth.jwt.secret,
    'algorithm': auth.jwt.algorithm,
    'base64EncodedSecret': auth.jwt.base64EncodedSecret,
    'privateKey': auth.jwt.privateKey,
    'sendAsHeader': auth.jwt.sendAsHeader,
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
    'verifier': auth.oauth1.verifier,
    'callback': auth.oauth1.callback,
    'nonce': auth.oauth1.nonce,
    'timestamp': auth.oauth1.timestamp,
    'version': auth.oauth1.version,
    'realm': auth.oauth1.realm,
    'asHeader': auth.oauth1.asHeader,
    'includeBodyHash': auth.oauth1.includeBodyHash,
    'encodeSignature': auth.oauth1.encodeSignature,
    'includeEmptyParameters': auth.oauth1.includeEmptyParameters,
  },
  'oauth2': {
    'grantType': auth.oauth2.grantType.name,
    'accessToken': auth.oauth2.accessToken,
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
        .map(_importedCollectionKeyValueToJson)
        .toList(growable: false),
    'tokenRequestParams': auth.oauth2.tokenRequestParams
        .map(_importedCollectionKeyValueToJson)
        .toList(growable: false),
    'refreshTokenUrl': auth.oauth2.refreshTokenUrl,
    'authorizationCode': auth.oauth2.authorizationCode,
    'codeVerifier': auth.oauth2.codeVerifier,
    'refreshToken': auth.oauth2.refreshToken,
    'clientId': auth.oauth2.clientId,
    'clientSecret': auth.oauth2.clientSecret,
    'tokenUrl': auth.oauth2.tokenUrl,
    'scopes': auth.oauth2.scopes,
    'username': auth.oauth2.username,
    'password': auth.oauth2.password,
  },
};

Map<String, Object?> _importedCollectionKeyValueToJson(KeyValueItem item) => {
  'key': item.key,
  'value': item.value,
  'description': item.description,
  'enabled': item.isEnabled,
};

RequestAuthDraft importedCollectionAuthFromJson(
  Object? value, {
  String? legacyAuthLabel,
}) {
  if (value is! Map) {
    return importedCollectionAuthFromLegacyLabel(legacyAuthLabel);
  }

  final json = Map<String, dynamic>.from(value);
  final type = _importedCollectionAuthTypeFromName(
    json['type'] as String?,
    legacyAuthLabel,
  );
  final basic = _map(json['basic']);
  final apiKey = _map(json['apiKey']);
  final bearerToken = _map(json['bearerToken']);
  final digest = _map(json['digest']);
  final hawk = _map(json['hawk']);
  final jwt = _map(json['jwt']);
  final ntlm = _map(json['ntlm']);
  final aws = _map(json['aws']);
  final oauth1 = _map(json['oauth1']);
  final oauth2 = _map(json['oauth2']);

  return RequestAuthDraft(
    type: type,
    basic: BasicAuthDraft(
      username: basic['username'] as String? ?? '',
      password: basic['password'] as String? ?? '',
    ),
    apiKey: ApiKeyAuthDraft(
      name: apiKey['name'] as String? ?? '',
      value: apiKey['value'] as String? ?? '',
      location: _importedCollectionApiKeyLocationFromName(
        apiKey['location'] as String?,
      ),
    ),
    bearerToken: BearerTokenAuthDraft(
      token: bearerToken['token'] as String? ?? '',
      prefix: bearerToken['prefix'] as String? ?? 'Bearer',
    ),
    digest: DigestAuthDraft(
      username: digest['username'] as String? ?? '',
      password: digest['password'] as String? ?? '',
      realm: digest['realm'] as String? ?? '',
      nonce: digest['nonce'] as String? ?? '',
      algorithm: digest['algorithm'] as String? ?? 'MD5',
      qop: digest['qop'] as String? ?? '',
      nonceCount: digest['nonceCount'] as String? ?? '',
      clientNonce: digest['clientNonce'] as String? ?? '',
      opaque: digest['opaque'] as String? ?? '',
    ),
    hawk: HawkAuthDraft(
      identifier: hawk['identifier'] as String? ?? '',
      key: hawk['key'] as String? ?? '',
      algorithm: hawk['algorithm'] as String? ?? 'sha256',
      user: hawk['user'] as String? ?? '',
      nonce: hawk['nonce'] as String? ?? '',
      ext: hawk['ext'] as String? ?? '',
      app: hawk['app'] as String? ?? '',
      delegation: hawk['delegation'] as String? ?? '',
      timestamp: hawk['timestamp'] as String? ?? '',
      includePayloadHash: hawk['includePayloadHash'] as bool? ?? false,
    ),
    jwt: JwtAuthDraft(
      token: jwt['token'] as String? ?? '',
      header: jwt['header'] as String? ?? '',
      payload: jwt['payload'] as String? ?? '',
      secret: jwt['secret'] as String? ?? '',
      algorithm: jwt['algorithm'] as String? ?? 'HS256',
      base64EncodedSecret: jwt['base64EncodedSecret'] as bool? ?? false,
      privateKey: jwt['privateKey'] as String? ?? '',
      sendAsHeader: jwt['sendAsHeader'] as bool? ?? true,
      prefix: jwt['prefix'] as String? ?? 'Bearer',
    ),
    ntlm: NtlmAuthDraft(
      username: ntlm['username'] as String? ?? '',
      password: ntlm['password'] as String? ?? '',
      domain: ntlm['domain'] as String? ?? '',
      workstation: ntlm['workstation'] as String? ?? '',
    ),
    aws: AwsAuthDraft(
      accessKey: aws['accessKey'] as String? ?? '',
      secretKey: aws['secretKey'] as String? ?? '',
      region: aws['region'] as String? ?? '',
      service: aws['service'] as String? ?? '',
      sessionToken: aws['sessionToken'] as String? ?? '',
    ),
    oauth1: OAuth1AuthDraft(
      consumerKey: oauth1['consumerKey'] as String? ?? '',
      consumerSecret: oauth1['consumerSecret'] as String? ?? '',
      token: oauth1['token'] as String? ?? '',
      tokenSecret: oauth1['tokenSecret'] as String? ?? '',
      signatureMethod: oauth1['signatureMethod'] as String? ?? 'HMAC-SHA1',
      verifier: oauth1['verifier'] as String? ?? '',
      callback: oauth1['callback'] as String? ?? '',
      nonce: oauth1['nonce'] as String? ?? '',
      timestamp: oauth1['timestamp'] as String? ?? '',
      version: oauth1['version'] as String? ?? '1.0',
      realm: oauth1['realm'] as String? ?? '',
      asHeader: oauth1['asHeader'] as bool? ?? false,
      includeBodyHash: oauth1['includeBodyHash'] as bool? ?? false,
      encodeSignature: oauth1['encodeSignature'] as bool? ?? true,
      includeEmptyParameters:
          oauth1['includeEmptyParameters'] as bool? ?? false,
    ),
    oauth2: OAuth2AuthDraft(
      grantType: _importedCollectionOAuth2GrantTypeFromName(
        oauth2['grantType'] as String?,
      ),
      accessToken: oauth2['accessToken'] as String? ?? '',
      addTokenToHeader: oauth2['addTokenToHeader'] as bool? ?? true,
      headerPrefix: oauth2['headerPrefix'] as String? ?? 'Bearer',
      authorizationUrl: oauth2['authorizationUrl'] as String? ?? '',
      accessTokenUrl: oauth2['accessTokenUrl'] as String? ?? '',
      redirectUri: oauth2['redirectUri'] as String? ?? defaultOAuth2MobileRedirectUri,
      scope: oauth2['scope'] as String? ?? '',
      usePkce: oauth2['usePkce'] as bool? ?? false,
      pkceMethod: _importedCollectionOAuth2PkceMethodFromName(
        oauth2['pkceMethod'] as String?,
      ),
      state: oauth2['state'] as String? ?? '',
      clientAuthentication:
          _importedCollectionOAuth2ClientAuthFromName(
            oauth2['clientAuthentication'] as String?,
          ),
      authUrlParams: _importedCollectionKeyValueListFromJson(
        oauth2['authUrlParams'],
      ),
      tokenRequestParams: _importedCollectionKeyValueListFromJson(
        oauth2['tokenRequestParams'],
      ),
      refreshTokenUrl: oauth2['refreshTokenUrl'] as String? ?? '',
      authorizationCode: oauth2['authorizationCode'] as String? ?? '',
      codeVerifier: oauth2['codeVerifier'] as String? ?? '',
      refreshToken: oauth2['refreshToken'] as String? ?? '',
      clientId: oauth2['clientId'] as String? ?? '',
      clientSecret: oauth2['clientSecret'] as String? ?? '',
      tokenUrl: oauth2['tokenUrl'] as String? ?? '',
      scopes: _stringList(oauth2['scopes']),
      username: oauth2['username'] as String? ?? '',
      password: oauth2['password'] as String? ?? '',
    ),
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .whereType<String>()
      .toList(growable: false);
}

List<KeyValueItem> _importedCollectionKeyValueListFromJson(Object? value) {
  if (value is! List) {
    return const <KeyValueItem>[];
  }

  return value
      .whereType<Map>()
      .map((item) {
        final json = Map<String, dynamic>.from(item);
        return KeyValueItem(
          key: json['key'] as String? ?? '',
          value: json['value'] as String? ?? '',
          description: json['description'] as String? ?? '',
          isEnabled: json['enabled'] as bool? ?? true,
        );
      })
      .toList(growable: false);
}

AuthType _importedCollectionAuthTypeFromName(
  String? name,
  String? legacyAuthLabel,
) {
  final normalized = name?.trim().toLowerCase();
  if (normalized != null && normalized.isNotEmpty) {
    for (final type in AuthType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
  }

  return importedCollectionAuthFromLegacyLabel(legacyAuthLabel).type;
}

ApiKeyLocation _importedCollectionApiKeyLocationFromName(String? name) {
  final normalized = name?.trim().toLowerCase();
  for (final location in ApiKeyLocation.values) {
    if (location.name.toLowerCase() == normalized) {
      return location;
    }
  }

  return ApiKeyLocation.header;
}

OAuth2GrantType _importedCollectionOAuth2GrantTypeFromName(String? name) {
  final normalized = name?.trim().toLowerCase();
  for (final value in OAuth2GrantType.values) {
    if (value.name.toLowerCase() == normalized) {
      return value;
    }
  }

  return OAuth2GrantType.manual;
}

OAuth2PkceMethod _importedCollectionOAuth2PkceMethodFromName(String? name) {
  final normalized = name?.trim().toLowerCase();
  for (final value in OAuth2PkceMethod.values) {
    if (value.name.toLowerCase() == normalized) {
      return value;
    }
  }

  return OAuth2PkceMethod.sha256;
}

OAuth2ClientAuthentication _importedCollectionOAuth2ClientAuthFromName(
  String? name,
) {
  final normalized = name?.trim().toLowerCase();
  for (final value in OAuth2ClientAuthentication.values) {
    if (value.name.toLowerCase() == normalized) {
      return value;
    }
  }

  return OAuth2ClientAuthentication.requestBody;
}
