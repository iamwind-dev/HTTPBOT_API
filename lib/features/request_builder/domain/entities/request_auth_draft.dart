// request_auth_draft.dart
import 'package:equatable/equatable.dart';

import '../../../../core/services/oauth2_callback_service.dart';
import 'request_key_value.dart';

enum AuthType {
  none('No Auth', plannedForInitialImplementation: true),
  basic('Basic', plannedForInitialImplementation: true),
  apiKey('API Key', plannedForInitialImplementation: true),
  bearerToken('Bearer Token', plannedForInitialImplementation: true),
  digest('Digest', plannedForInitialImplementation: false),
  hawk('Hawk', plannedForInitialImplementation: false),
  jwt('JWT', plannedForInitialImplementation: false),
  ntlm('NTLM', plannedForInitialImplementation: true),
  awsSignature('AWS Signature', plannedForInitialImplementation: false),
  oauth1('OAuth 1.0a', plannedForInitialImplementation: false),
  oauth2('OAuth 2.0', plannedForInitialImplementation: false);

  const AuthType(this.label, {required this.plannedForInitialImplementation});

  final String label;
  final bool plannedForInitialImplementation;
}

enum ApiKeyLocation {
  header('Header'),
  query('Query'),
  cookie('Cookie');

  const ApiKeyLocation(this.label);

  final String label;
}

enum OAuth2GrantType {
  manual('Manual'),
  authorizationCode('Authorization Code'),
  implicit('Implicit'),
  passwordCredentials('Password Credentials'),
  clientCredentials('Client Credentials');

  const OAuth2GrantType(this.label);

  final String label;
}

enum OAuth2PkceMethod {
  sha256('SHA-256'),
  plain('Plain');

  const OAuth2PkceMethod(this.label);

  final String label;
}

enum OAuth2ClientAuthentication {
  basicAuthHeader('Basic Auth Header'),
  requestBody('Request Body');

  const OAuth2ClientAuthentication(this.label);

  final String label;
}

class BasicAuthDraft extends Equatable {
  const BasicAuthDraft({this.username = '', this.password = ''});

  final String username;
  final String password;

  @override
  List<Object> get props => [username, password];
}

class ApiKeyAuthDraft extends Equatable {
  const ApiKeyAuthDraft({
    this.name = '',
    this.value = '',
    this.location = ApiKeyLocation.header,
  });

  final String name;
  final String value;
  final ApiKeyLocation location;

  @override
  List<Object> get props => [name, value, location];
}

class BearerTokenAuthDraft extends Equatable {
  const BearerTokenAuthDraft({this.token = '', this.prefix = 'Bearer'});

  final String token;
  final String prefix;

  @override
  List<Object> get props => [token, prefix];
}

class DigestAuthDraft extends Equatable {
  const DigestAuthDraft({
    this.username = '',
    this.password = '',
    this.realm = '',
    this.nonce = '',
    this.algorithm = 'MD5',
    this.qop = '',
    this.opaque = '',
  });

  final String username;
  final String password;
  final String realm;
  final String nonce;
  final String algorithm;
  final String qop;
  final String opaque;

  @override
  List<Object> get props => [
    username,
    password,
    realm,
    nonce,
    algorithm,
    qop,
    opaque,
  ];
}

class HawkAuthDraft extends Equatable {
  const HawkAuthDraft({
    this.identifier = '',
    this.key = '',
    this.algorithm = 'sha256',
    this.app = '',
    this.delegation = '',
  });

  final String identifier;
  final String key;
  final String algorithm;
  final String app;
  final String delegation;

  @override
  List<Object> get props => [identifier, key, algorithm, app, delegation];
}

class JwtAuthDraft extends Equatable {
  const JwtAuthDraft({
    this.token = '',
    this.header = '',
    this.payload = '',
    this.secret = '',
    this.algorithm = 'HS256',
    this.prefix = 'Bearer',
  });

  final String token;
  final String header;
  final String payload;
  final String secret;
  final String algorithm;
  final String prefix;

  @override
  List<Object> get props => [token, header, payload, secret, algorithm, prefix];
}

class NtlmAuthDraft extends Equatable {
  const NtlmAuthDraft({
    this.username = '',
    this.password = '',
    this.domain = '',
    this.workstation = '',
  });

  final String username;
  final String password;
  final String domain;
  final String workstation;

  /// Returns true when NTLM has the minimum credentials required to authenticate.
  bool get canApplyNtlm => username.trim().isNotEmpty && password.isNotEmpty;

  /// Creates a new NTLM draft with any updated credential fields applied.
  NtlmAuthDraft copyWith({
    String? username,
    String? password,
    String? domain,
    String? workstation,
  }) => NtlmAuthDraft(
    username: username ?? this.username,
    password: password ?? this.password,
    domain: domain ?? this.domain,
    workstation: workstation ?? this.workstation,
  );

  @override
  List<Object> get props => [username, password, domain, workstation];
}

class AwsAuthDraft extends Equatable {
  const AwsAuthDraft({
    this.accessKey = '',
    this.secretKey = '',
    this.region = '',
    this.service = '',
    this.sessionToken = '',
  });

  final String accessKey;
  final String secretKey;
  final String region;
  final String service;
  final String sessionToken;

  @override
  List<Object> get props => [
    accessKey,
    secretKey,
    region,
    service,
    sessionToken,
  ];
}

class OAuth1AuthDraft extends Equatable {
  const OAuth1AuthDraft({
    this.consumerKey = '',
    this.consumerSecret = '',
    this.token = '',
    this.tokenSecret = '',
    this.signatureMethod = 'HMAC-SHA1',
    this.nonce = '',
    this.timestamp = '',
    this.version = '1.0',
  });

  final String consumerKey;
  final String consumerSecret;
  final String token;
  final String tokenSecret;
  final String signatureMethod;
  final String nonce;
  final String timestamp;
  final String version;

  @override
  List<Object> get props => [
    consumerKey,
    consumerSecret,
    token,
    tokenSecret,
    signatureMethod,
    nonce,
    timestamp,
    version,
  ];
}

class OAuth2AuthDraft extends Equatable {
  const OAuth2AuthDraft({
    this.grantType = OAuth2GrantType.manual,
    this.accessToken = '',
    this.addTokenToHeader = true,
    this.headerPrefix = 'Bearer',
    this.authorizationUrl = '',
    this.accessTokenUrl = '',
    this.redirectUri = defaultOAuth2MobileRedirectUri,
    this.scope = '',
    this.usePkce = false,
    this.pkceMethod = OAuth2PkceMethod.sha256,
    this.state = '',
    this.clientAuthentication = OAuth2ClientAuthentication.requestBody,
    this.authUrlParams = const <KeyValueItem>[],
    this.tokenRequestParams = const <KeyValueItem>[],
    this.refreshTokenUrl = '',
    this.authorizationCode = '',
    this.codeVerifier = '',
    this.refreshToken = '',
    this.clientId = '',
    this.clientSecret = '',
    this.tokenUrl = '',
    this.scopes = const <String>[],
  });

  final OAuth2GrantType grantType;
  final String accessToken;
  final bool addTokenToHeader;
  final String headerPrefix;
  final String authorizationUrl;
  final String accessTokenUrl;
  final String redirectUri;
  final String scope;
  final bool usePkce;
  final OAuth2PkceMethod pkceMethod;
  final String state;
  final OAuth2ClientAuthentication clientAuthentication;
  final List<KeyValueItem> authUrlParams;
  final List<KeyValueItem> tokenRequestParams;
  final String refreshTokenUrl;
  final String authorizationCode;
  final String codeVerifier;
  final String refreshToken;
  final String clientId;
  final String clientSecret;
  final String tokenUrl;
  final List<String> scopes;

  /// Returns true when the selected OAuth2 grant type uses the manual token flow.
  bool get isManual => grantType == OAuth2GrantType.manual;

  /// Returns true when manual OAuth2 has a token that can be applied to the request.
  bool get canApplyManualToken => isManual && accessToken.trim().isNotEmpty;

  /// Returns true when an implemented OAuth2 flow has produced a token that can be applied to the request.
  bool get canApplyAccessToken =>
      (isManual || isAuthorizationCode) && accessToken.trim().isNotEmpty;

  /// Returns true when the manual token should be synchronized into the Authorization header.
  bool get sendsTokenAsHeader => addTokenToHeader;

  /// Returns true when the selected OAuth2 grant type uses the authorization code flow.
  bool get isAuthorizationCode =>
      grantType == OAuth2GrantType.authorizationCode;

  /// Returns the token endpoint used for authorization code exchange.
  String get resolvedAccessTokenUrl {
    final preferredUrl = accessTokenUrl.trim();
    if (preferredUrl.isNotEmpty) {
      return preferredUrl;
    }

    return tokenUrl.trim();
  }

  /// Returns the refresh-token endpoint with a fallback to the access-token endpoint.
  String get resolvedRefreshTokenUrl {
    final preferredUrl = refreshTokenUrl.trim();
    if (preferredUrl.isNotEmpty) {
      return preferredUrl;
    }

    return resolvedAccessTokenUrl;
  }

  /// Returns the Authorization value while avoiding duplicate header prefixes.
  String get resolvedAuthorizationValue {
    final token = accessToken.trim();
    final prefix = headerPrefix.trim();

    if (prefix.isEmpty) {
      return token;
    }

    if (token.toLowerCase().startsWith('${prefix.toLowerCase()} ')) {
      return token;
    }

    return '$prefix $token';
  }

  /// Creates a new OAuth2 draft with any updated configuration or runtime values applied.
  OAuth2AuthDraft copyWith({
    OAuth2GrantType? grantType,
    String? accessToken,
    bool? addTokenToHeader,
    String? headerPrefix,
    String? authorizationUrl,
    String? accessTokenUrl,
    String? redirectUri,
    String? scope,
    bool? usePkce,
    OAuth2PkceMethod? pkceMethod,
    String? state,
    OAuth2ClientAuthentication? clientAuthentication,
    List<KeyValueItem>? authUrlParams,
    List<KeyValueItem>? tokenRequestParams,
    String? refreshTokenUrl,
    String? authorizationCode,
    String? codeVerifier,
    String? refreshToken,
    String? clientId,
    String? clientSecret,
    String? tokenUrl,
    List<String>? scopes,
  }) => OAuth2AuthDraft(
    grantType: grantType ?? this.grantType,
    accessToken: accessToken ?? this.accessToken,
    addTokenToHeader: addTokenToHeader ?? this.addTokenToHeader,
    headerPrefix: headerPrefix ?? this.headerPrefix,
    authorizationUrl: authorizationUrl ?? this.authorizationUrl,
    accessTokenUrl: accessTokenUrl ?? this.accessTokenUrl,
    redirectUri: redirectUri ?? this.redirectUri,
    scope: scope ?? this.scope,
    usePkce: usePkce ?? this.usePkce,
    pkceMethod: pkceMethod ?? this.pkceMethod,
    state: state ?? this.state,
    clientAuthentication: clientAuthentication ?? this.clientAuthentication,
    authUrlParams: authUrlParams ?? this.authUrlParams,
    tokenRequestParams: tokenRequestParams ?? this.tokenRequestParams,
    refreshTokenUrl: refreshTokenUrl ?? this.refreshTokenUrl,
    authorizationCode: authorizationCode ?? this.authorizationCode,
    codeVerifier: codeVerifier ?? this.codeVerifier,
    refreshToken: refreshToken ?? this.refreshToken,
    clientId: clientId ?? this.clientId,
    clientSecret: clientSecret ?? this.clientSecret,
    tokenUrl: tokenUrl ?? this.tokenUrl,
    scopes: scopes ?? this.scopes,
  );

  @override
  List<Object> get props => [
    grantType,
    accessToken,
    addTokenToHeader,
    headerPrefix,
    authorizationUrl,
    accessTokenUrl,
    redirectUri,
    scope,
    usePkce,
    pkceMethod,
    state,
    clientAuthentication,
    authUrlParams,
    tokenRequestParams,
    refreshTokenUrl,
    authorizationCode,
    codeVerifier,
    refreshToken,
    clientId,
    clientSecret,
    tokenUrl,
    scopes,
  ];
}

class RequestAuthDraft extends Equatable {
  const RequestAuthDraft({
    this.type = AuthType.none,
    this.basic = const BasicAuthDraft(),
    this.apiKey = const ApiKeyAuthDraft(),
    this.bearerToken = const BearerTokenAuthDraft(),
    this.digest = const DigestAuthDraft(),
    this.hawk = const HawkAuthDraft(),
    this.jwt = const JwtAuthDraft(),
    this.ntlm = const NtlmAuthDraft(),
    this.aws = const AwsAuthDraft(),
    this.oauth1 = const OAuth1AuthDraft(),
    this.oauth2 = const OAuth2AuthDraft(),
  });

  const RequestAuthDraft.none()
    : type = AuthType.none,
      basic = const BasicAuthDraft(),
      apiKey = const ApiKeyAuthDraft(),
      bearerToken = const BearerTokenAuthDraft(),
      digest = const DigestAuthDraft(),
      hawk = const HawkAuthDraft(),
      jwt = const JwtAuthDraft(),
      ntlm = const NtlmAuthDraft(),
      aws = const AwsAuthDraft(),
      oauth1 = const OAuth1AuthDraft(),
      oauth2 = const OAuth2AuthDraft();

  /// Creates a new auth draft with any updated auth mode or credentials applied.
  RequestAuthDraft copyWith({
    AuthType? type,
    BasicAuthDraft? basic,
    ApiKeyAuthDraft? apiKey,
    BearerTokenAuthDraft? bearerToken,
    DigestAuthDraft? digest,
    HawkAuthDraft? hawk,
    JwtAuthDraft? jwt,
    NtlmAuthDraft? ntlm,
    AwsAuthDraft? aws,
    OAuth1AuthDraft? oauth1,
    OAuth2AuthDraft? oauth2,
  }) => RequestAuthDraft(
    type: type ?? this.type,
    basic: basic ?? this.basic,
    apiKey: apiKey ?? this.apiKey,
    bearerToken: bearerToken ?? this.bearerToken,
    digest: digest ?? this.digest,
    hawk: hawk ?? this.hawk,
    jwt: jwt ?? this.jwt,
    ntlm: ntlm ?? this.ntlm,
    aws: aws ?? this.aws,
    oauth1: oauth1 ?? this.oauth1,
    oauth2: oauth2 ?? this.oauth2,
  );

  final AuthType type;
  final BasicAuthDraft basic;
  final ApiKeyAuthDraft apiKey;
  final BearerTokenAuthDraft bearerToken;
  final DigestAuthDraft digest;
  final HawkAuthDraft hawk;
  final JwtAuthDraft jwt;
  final NtlmAuthDraft ntlm;
  final AwsAuthDraft aws;
  final OAuth1AuthDraft oauth1;
  final OAuth2AuthDraft oauth2;

  /// Returns true when the selected auth mode is NTLM and has the minimum credentials to send.
  bool get canApplyNtlm => type == AuthType.ntlm && ntlm.canApplyNtlm;

  @override
  List<Object> get props => [
    type,
    basic,
    apiKey,
    bearerToken,
    digest,
    hawk,
    jwt,
    ntlm,
    aws,
    oauth1,
    oauth2,
  ];
}
