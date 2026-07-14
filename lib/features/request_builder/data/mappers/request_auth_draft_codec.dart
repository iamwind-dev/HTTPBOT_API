import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_key_value.dart';

Map<String, Object?> requestAuthDraftToJson(RequestAuthDraft auth) => {
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
        .map(keyValueItemToJson)
        .toList(growable: false),
    'tokenRequestParams': auth.oauth2.tokenRequestParams
        .map(keyValueItemToJson)
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

RequestAuthDraft requestAuthDraftFromJson(Map<String, dynamic> json) =>
    RequestAuthDraft(
      type: authTypeFromName(json['type'] as String?),
      basic: basicAuthDraftFromJson(mapFromJson(json['basic'])),
      apiKey: apiKeyAuthDraftFromJson(mapFromJson(json['apiKey'])),
      bearerToken: bearerTokenAuthDraftFromJson(
        mapFromJson(json['bearerToken']),
      ),
      digest: digestAuthDraftFromJson(mapFromJson(json['digest'])),
      hawk: hawkAuthDraftFromJson(mapFromJson(json['hawk'])),
      jwt: jwtAuthDraftFromJson(mapFromJson(json['jwt'])),
      ntlm: ntlmAuthDraftFromJson(mapFromJson(json['ntlm'])),
      aws: awsAuthDraftFromJson(mapFromJson(json['aws'])),
      oauth1: oAuth1AuthDraftFromJson(mapFromJson(json['oauth1'])),
      oauth2: oAuth2AuthDraftFromJson(mapFromJson(json['oauth2'])),
    );

BasicAuthDraft basicAuthDraftFromJson(Map<String, dynamic> json) =>
    BasicAuthDraft(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );

ApiKeyAuthDraft apiKeyAuthDraftFromJson(Map<String, dynamic> json) =>
    ApiKeyAuthDraft(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      location: apiKeyLocationFromName(json['location'] as String?),
    );

BearerTokenAuthDraft bearerTokenAuthDraftFromJson(Map<String, dynamic> json) =>
    BearerTokenAuthDraft(
      token: json['token'] as String? ?? '',
      prefix: json['prefix'] as String? ?? 'Bearer',
    );

DigestAuthDraft digestAuthDraftFromJson(Map<String, dynamic> json) =>
    DigestAuthDraft(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      realm: json['realm'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'MD5',
      qop: json['qop'] as String? ?? '',
      nonceCount: json['nonceCount'] as String? ?? '',
      clientNonce: json['clientNonce'] as String? ?? '',
      opaque: json['opaque'] as String? ?? '',
    );

HawkAuthDraft hawkAuthDraftFromJson(Map<String, dynamic> json) =>
    HawkAuthDraft(
      identifier: json['identifier'] as String? ?? '',
      key: json['key'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'sha256',
      user: json['user'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      app: json['app'] as String? ?? '',
      delegation: json['delegation'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      includePayloadHash: json['includePayloadHash'] as bool? ?? false,
    );

JwtAuthDraft jwtAuthDraftFromJson(Map<String, dynamic> json) => JwtAuthDraft(
  token: json['token'] as String? ?? '',
  header: json['header'] as String? ?? '',
  payload: json['payload'] as String? ?? '',
  secret: json['secret'] as String? ?? '',
  algorithm: json['algorithm'] as String? ?? 'HS256',
  base64EncodedSecret: json['base64EncodedSecret'] as bool? ?? false,
  privateKey: json['privateKey'] as String? ?? '',
  sendAsHeader: json['sendAsHeader'] as bool? ?? true,
  prefix: json['prefix'] as String? ?? 'Bearer',
);

NtlmAuthDraft ntlmAuthDraftFromJson(Map<String, dynamic> json) =>
    NtlmAuthDraft(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      workstation: json['workstation'] as String? ?? '',
    );

AwsAuthDraft awsAuthDraftFromJson(Map<String, dynamic> json) => AwsAuthDraft(
  accessKey: json['accessKey'] as String? ?? '',
  secretKey: json['secretKey'] as String? ?? '',
  region: json['region'] as String? ?? '',
  service: json['service'] as String? ?? '',
  sessionToken: json['sessionToken'] as String? ?? '',
);

OAuth1AuthDraft oAuth1AuthDraftFromJson(Map<String, dynamic> json) =>
    OAuth1AuthDraft(
      consumerKey: json['consumerKey'] as String? ?? '',
      consumerSecret: json['consumerSecret'] as String? ?? '',
      token: json['token'] as String? ?? '',
      tokenSecret: json['tokenSecret'] as String? ?? '',
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

OAuth2AuthDraft oAuth2AuthDraftFromJson(Map<String, dynamic> json) =>
    OAuth2AuthDraft(
      grantType: oAuth2GrantTypeFromName(json['grantType'] as String?),
      accessToken: json['accessToken'] as String? ?? '',
      addTokenToHeader: json['addTokenToHeader'] as bool? ?? true,
      headerPrefix: json['headerPrefix'] as String? ?? 'Bearer',
      authorizationUrl: json['authorizationUrl'] as String? ?? '',
      accessTokenUrl: json['accessTokenUrl'] as String? ?? '',
      redirectUri: json['redirectUri'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      usePkce: json['usePkce'] as bool? ?? false,
      pkceMethod: oAuth2PkceMethodFromName(json['pkceMethod'] as String?),
      state: json['state'] as String? ?? '',
      clientAuthentication: oAuth2ClientAuthenticationFromName(
        json['clientAuthentication'] as String?,
      ),
      authUrlParams: listFromJson(
        json['authUrlParams'],
        (value) => keyValueItemFromJson(value),
      ),
      tokenRequestParams: listFromJson(
        json['tokenRequestParams'],
        (value) => keyValueItemFromJson(value),
      ),
      refreshTokenUrl: json['refreshTokenUrl'] as String? ?? '',
      authorizationCode: json['authorizationCode'] as String? ?? '',
      codeVerifier: json['codeVerifier'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      tokenUrl: json['tokenUrl'] as String? ?? '',
      scopes: stringListFromJson(json['scopes']),
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );

Map<String, Object?> keyValueItemToJson(KeyValueItem item) => {
  'key': item.key,
  'value': item.value,
  'isEnabled': item.isEnabled,
  'type': item.type.name,
  'contentType': item.contentType,
  'description': item.description,
};

KeyValueItem keyValueItemFromJson(Map<String, dynamic> json) => KeyValueItem(
  key: json['key'] as String? ?? '',
  value: json['value'] as String? ?? '',
  isEnabled: json['isEnabled'] as bool? ?? true,
  type: keyValueItemTypeFromName(json['type'] as String?),
  contentType: json['contentType'] as String? ?? '',
  description: json['description'] as String? ?? '',
);

AuthType authTypeFromName(String? value) =>
    enumValueOrFallback(AuthType.values, value, AuthType.none);

ApiKeyLocation apiKeyLocationFromName(String? value) =>
    enumValueOrFallback(ApiKeyLocation.values, value, ApiKeyLocation.header);

OAuth2GrantType oAuth2GrantTypeFromName(String? value) =>
    enumValueOrFallback(
      OAuth2GrantType.values,
      value,
      OAuth2GrantType.manual,
    );

OAuth2PkceMethod oAuth2PkceMethodFromName(String? value) =>
    enumValueOrFallback(
      OAuth2PkceMethod.values,
      value,
      OAuth2PkceMethod.sha256,
    );

OAuth2ClientAuthentication oAuth2ClientAuthenticationFromName(String? value) =>
    enumValueOrFallback(
      OAuth2ClientAuthentication.values,
      value,
      OAuth2ClientAuthentication.basicAuthHeader,
    );

KeyValueItemType keyValueItemTypeFromName(String? value) =>
    enumValueOrFallback(
      KeyValueItemType.values,
      value,
      KeyValueItemType.text,
    );

List<T> listFromJson<T>(
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

List<String> stringListFromJson(Object? value) {
  if (value is! List) {
    return <String>[];
  }

  return value.whereType<String>().toList(growable: false);
}

Map<String, dynamic> mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

T enumValueOrFallback<T extends Enum>(List<T> values, String? name, T fallback) {
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
