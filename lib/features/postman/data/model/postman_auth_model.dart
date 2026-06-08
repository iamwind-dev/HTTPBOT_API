import '../../domain/entities/postman_auth_entity.dart';

class PostmanAuthModel {
  const PostmanAuthModel({
    this.type = PostmanAuthType.none,
    this.basic = const PostmanBasicAuthEntity(),
    this.apiKey = const PostmanApiKeyAuthEntity(),
    this.bearerToken = const PostmanBearerAuthEntity(),
    this.digest = const PostmanDigestAuthEntity(),
    this.hawk = const PostmanHawkAuthEntity(),
    this.jwt = const PostmanJwtAuthEntity(),
    this.ntlm = const PostmanNtlmAuthEntity(),
    this.aws = const PostmanAwsAuthEntity(),
    this.oauth1 = const PostmanOAuth1AuthEntity(),
    this.oauth2 = const PostmanOAuth2AuthEntity(),
  });

  final PostmanAuthType type;
  final PostmanBasicAuthEntity basic;
  final PostmanApiKeyAuthEntity apiKey;
  final PostmanBearerAuthEntity bearerToken;
  final PostmanDigestAuthEntity digest;
  final PostmanHawkAuthEntity hawk;
  final PostmanJwtAuthEntity jwt;
  final PostmanNtlmAuthEntity ntlm;
  final PostmanAwsAuthEntity aws;
  final PostmanOAuth1AuthEntity oauth1;
  final PostmanOAuth2AuthEntity oauth2;

  factory PostmanAuthModel.fromJson(Object? json) {
    if (json is! Map) {
      return const PostmanAuthModel();
    }

    final map = Map<String, dynamic>.from(json);
    final typeName = map['type']?.toString().trim().toLowerCase() ?? '';
    return PostmanAuthModel(
      type: _parseAuthType(typeName),
      basic: _parseBasic(map['basic']),
      apiKey: _parseApiKey(map['apikey']),
      bearerToken: _parseBearer(map['bearer']),
      digest: _parseDigest(map['digest']),
      hawk: _parseHawk(map['hawk']),
      jwt: _parseJwt(map['jwt']),
      ntlm: _parseNtlm(map['ntlm']),
      aws: _parseAws(map['awsv4']),
      oauth1: _parseOAuth1(map['oauth1']),
      oauth2: _parseOAuth2(map['oauth2']),
    );
  }

  static PostmanAuthType _parseAuthType(String input) {
    switch (input) {
      case 'basic':
        return PostmanAuthType.basic;
      case 'apikey':
        return PostmanAuthType.apiKey;
      case 'bearer':
        return PostmanAuthType.bearerToken;
      case 'digest':
        return PostmanAuthType.digest;
      case 'hawk':
        return PostmanAuthType.hawk;
      case 'jwt':
        return PostmanAuthType.jwt;
      case 'ntlm':
        return PostmanAuthType.ntlm;
      case 'awsv4':
        return PostmanAuthType.awsSignature;
      case 'oauth1':
        return PostmanAuthType.oauth1;
      case 'oauth2':
        return PostmanAuthType.oauth2;
      default:
        return PostmanAuthType.none;
    }
  }

  static Map<String, String> _readAttributeMap(Object? input) {
    final result = <String, String>{};
    for (final item in input as List? ?? const []) {
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);
      final key = map['key']?.toString() ?? '';
      if (key.isEmpty) {
        continue;
      }
      result[key] = map['value']?.toString() ?? '';
    }
    return result;
  }

  static PostmanBasicAuthEntity _parseBasic(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanBasicAuthEntity(
      username: values['username'] ?? '',
      password: values['password'] ?? '',
    );
  }

  static PostmanApiKeyAuthEntity _parseApiKey(Object? input) {
    final values = _readAttributeMap(input);
    final locationName = (values['in'] ?? '').trim().toLowerCase();
    return PostmanApiKeyAuthEntity(
      key: values['key'] ?? '',
      value: values['value'] ?? '',
      location: switch (locationName) {
        'query' => PostmanApiKeyLocation.query,
        'cookie' => PostmanApiKeyLocation.cookie,
        _ => PostmanApiKeyLocation.header,
      },
    );
  }

  static PostmanBearerAuthEntity _parseBearer(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanBearerAuthEntity(token: values['token'] ?? '');
  }

  static PostmanDigestAuthEntity _parseDigest(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanDigestAuthEntity(
      username: values['username'] ?? '',
      password: values['password'] ?? '',
      realm: values['realm'] ?? '',
      nonce: values['nonce'] ?? '',
      algorithm: values['algorithm'] ?? '',
      qop: values['qop'] ?? '',
      opaque: values['opaque'] ?? '',
    );
  }

  static PostmanHawkAuthEntity _parseHawk(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanHawkAuthEntity(
      identifier: values['authId'] ?? '',
      key: values['authKey'] ?? '',
      algorithm: values['algorithm'] ?? '',
      app: values['app'] ?? '',
      delegation: values['delegation'] ?? '',
    );
  }

  static PostmanJwtAuthEntity _parseJwt(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanJwtAuthEntity(
      token: values['token'] ?? '',
      header: values['header'] ?? '',
      payload: values['payload'] ?? '',
      secret: values['secret'] ?? '',
      algorithm: values['algorithm'] ?? '',
      prefix: values['addTokenTo'] ?? 'Bearer',
    );
  }

  static PostmanNtlmAuthEntity _parseNtlm(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanNtlmAuthEntity(
      username: values['username'] ?? '',
      password: values['password'] ?? '',
      domain: values['domain'] ?? '',
      workstation: values['workstation'] ?? '',
    );
  }

  static PostmanAwsAuthEntity _parseAws(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanAwsAuthEntity(
      accessKey: values['accessKey'] ?? '',
      secretKey: values['secretKey'] ?? '',
      region: values['region'] ?? '',
      service: values['service'] ?? '',
      sessionToken: values['sessionToken'] ?? '',
    );
  }

  static PostmanOAuth1AuthEntity _parseOAuth1(Object? input) {
    final values = _readAttributeMap(input);
    return PostmanOAuth1AuthEntity(
      consumerKey: values['consumerKey'] ?? '',
      consumerSecret: values['consumerSecret'] ?? '',
      token: values['token'] ?? '',
      tokenSecret: values['tokenSecret'] ?? '',
      signatureMethod: values['signatureMethod'] ?? '',
      nonce: values['nonce'] ?? '',
      timestamp: values['timestamp'] ?? '',
      version: values['version'] ?? '',
    );
  }

  static PostmanOAuth2AuthEntity _parseOAuth2(Object? input) {
    final values = _readAttributeMap(input);
    final scopes = (values['scope'] ?? '')
        .split(' ')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return PostmanOAuth2AuthEntity(
      accessToken: values['accessToken'] ?? '',
      refreshToken: values['refreshToken'] ?? '',
      clientId: values['clientId'] ?? '',
      clientSecret: values['clientSecret'] ?? '',
      tokenUrl: values['tokenUrl'] ?? '',
      scopes: scopes,
    );
  }

  PostmanAuthEntity toEntity() {
    return PostmanAuthEntity(
      type: type,
      basic: basic,
      apiKey: apiKey,
      bearerToken: bearerToken,
      digest: digest,
      hawk: hawk,
      jwt: jwt,
      ntlm: ntlm,
      aws: aws,
      oauth1: oauth1,
      oauth2: oauth2,
    );
  }
}
