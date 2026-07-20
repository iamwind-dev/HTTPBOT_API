// request_auth_draft.dart
import 'package:equatable/equatable.dart';

import '../../../../core/services/oauth2_callback_service.dart';
import 'request_key_value.dart';

enum AuthType {
  none('No Auth', plannedForInitialImplementation: true),
  basic('Basic', plannedForInitialImplementation: true),
  apiKey('API Key', plannedForInitialImplementation: true),
  bearerToken('Bearer Token', plannedForInitialImplementation: true),
  digest('Digest', plannedForInitialImplementation: true),
  hawk('Hawk', plannedForInitialImplementation: true),
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
  /// Creates immutable API Key credentials and remembers Custom selection.
  const ApiKeyAuthDraft({
    this.name = '',
    this.value = '',
    this.location = ApiKeyLocation.header,
    this.isCustomName = false,
  });

  final String name;
  final String value;
  final ApiKeyLocation location;
  final bool isCustomName;

  /// Keeps the API key value out of Equatable debug output.
  @override
  bool get stringify => false;

  @override
  List<Object> get props => [name, value, location, isCustomName];
}

class BearerTokenAuthDraft extends Equatable {
  const BearerTokenAuthDraft({this.token = '', this.prefix = 'Bearer'});

  final String token;
  final String prefix;

  @override
  List<Object> get props => [token, prefix];
}

enum DigestAlgorithm {
  md5('MD5'),
  md5Sess('MD5-sess'),
  sha256('SHA-256'),
  sha256Sess('SHA-256-sess'),
  sha512256('SHA-512-256'),
  sha512256Sess('SHA-512-256-sess');

  const DigestAlgorithm(this.label);

  final String label;

  /// Returns true when this algorithm derives a session key from nonce and cnonce.
  bool get isSessionVariant => switch (this) {
    DigestAlgorithm.md5Sess ||
    DigestAlgorithm.sha256Sess ||
    DigestAlgorithm.sha512256Sess => true,
    _ => false,
  };
}

class DigestAuthDraft extends Equatable {
  const DigestAuthDraft({
    this.username = '',
    this.password = '',
    this.realm = '',
    this.nonce = '',
    this.algorithm = 'MD5',
    this.qop = '',
    this.nonceCount = '',
    this.clientNonce = '',
    this.opaque = '',
  });

  final String username;
  final String password;
  final String realm;
  final String nonce;
  final String algorithm;
  final String qop;
  final String nonceCount;
  final String clientNonce;
  final String opaque;

  /// Returns the selected algorithm enum, defaulting to MD5 for unknown persisted values.
  DigestAlgorithm get selectedAlgorithm {
    for (final candidate in DigestAlgorithm.values) {
      if (candidate.label == algorithm) {
        return candidate;
      }
    }

    return DigestAlgorithm.md5;
  }

  /// Returns true when realm and nonce allow building the header before send.
  bool get hasManualChallenge =>
      realm.trim().isNotEmpty && nonce.trim().isNotEmpty;

  /// Creates a new digest draft with any updated credential or challenge fields applied.
  DigestAuthDraft copyWith({
    String? username,
    String? password,
    String? realm,
    String? nonce,
    String? algorithm,
    String? qop,
    String? nonceCount,
    String? clientNonce,
    String? opaque,
  }) => DigestAuthDraft(
    username: username ?? this.username,
    password: password ?? this.password,
    realm: realm ?? this.realm,
    nonce: nonce ?? this.nonce,
    algorithm: algorithm ?? this.algorithm,
    qop: qop ?? this.qop,
    nonceCount: nonceCount ?? this.nonceCount,
    clientNonce: clientNonce ?? this.clientNonce,
    opaque: opaque ?? this.opaque,
  );

  @override
  List<Object> get props => [
    username,
    password,
    realm,
    nonce,
    algorithm,
    qop,
    nonceCount,
    clientNonce,
    opaque,
  ];
}

enum HawkAlgorithm {
  sha256('SHA-256'),
  sha1('SHA-1');

  const HawkAlgorithm(this.label);

  final String label;
}

class HawkAuthDraft extends Equatable {
  const HawkAuthDraft({
    this.identifier = '',
    this.key = '',
    this.algorithm = 'sha256',
    this.user = '',
    this.nonce = '',
    this.ext = '',
    this.app = '',
    this.delegation = '',
    this.timestamp = '',
    this.includePayloadHash = false,
  });

  final String identifier;
  final String key;
  final String algorithm;
  final String user;
  final String nonce;
  final String ext;
  final String app;
  final String delegation;
  final String timestamp;
  final bool includePayloadHash;

  /// Returns the selected algorithm enum, accepting both UI labels and
  /// persisted lowercase names, defaulting to SHA-256 for unknown values.
  HawkAlgorithm get selectedAlgorithm {
    final normalized = algorithm.trim().toLowerCase().replaceAll('-', '');
    for (final candidate in HawkAlgorithm.values) {
      if (candidate.label.toLowerCase().replaceAll('-', '') == normalized) {
        return candidate;
      }
    }

    return HawkAlgorithm.sha256;
  }

  /// Creates a new Hawk draft with any updated credential or signing fields applied.
  HawkAuthDraft copyWith({
    String? identifier,
    String? key,
    String? algorithm,
    String? user,
    String? nonce,
    String? ext,
    String? app,
    String? delegation,
    String? timestamp,
    bool? includePayloadHash,
  }) => HawkAuthDraft(
    identifier: identifier ?? this.identifier,
    key: key ?? this.key,
    algorithm: algorithm ?? this.algorithm,
    user: user ?? this.user,
    nonce: nonce ?? this.nonce,
    ext: ext ?? this.ext,
    app: app ?? this.app,
    delegation: delegation ?? this.delegation,
    timestamp: timestamp ?? this.timestamp,
    includePayloadHash: includePayloadHash ?? this.includePayloadHash,
  );

  @override
  List<Object> get props => [
    identifier,
    key,
    algorithm,
    user,
    nonce,
    ext,
    app,
    delegation,
    timestamp,
    includePayloadHash,
  ];
}

enum JwtAlgorithm {
  hs256('HS256'),
  hs384('HS384'),
  hs512('HS512'),
  rs256('RS256'),
  rs384('RS384'),
  rs512('RS512'),
  ps256('PS256'),
  ps384('PS384'),
  ps512('PS512'),
  es256('ES256'),
  es384('ES384'),
  es512('ES512');

  const JwtAlgorithm(this.label);

  final String label;

  /// Returns true when this algorithm signs with an HMAC shared secret.
  bool get isHmac => switch (this) {
    JwtAlgorithm.hs256 || JwtAlgorithm.hs384 || JwtAlgorithm.hs512 => true,
    _ => false,
  };

  /// Returns true when this algorithm requires an asymmetric private key.
  bool get isPrivateKey => !isHmac;
}

class JwtAuthDraft extends Equatable {
  const JwtAuthDraft({
    this.token = '',
    this.header = '',
    this.payload = '',
    this.secret = '',
    this.algorithm = 'HS256',
    this.base64EncodedSecret = false,
    this.privateKey = '',
    this.sendAsHeader = true,
    this.prefix = 'Bearer',
  });

  final String token;
  final String header;
  final String payload;
  final String secret;
  final String algorithm;
  final bool base64EncodedSecret;
  final String privateKey;
  final bool sendAsHeader;
  final String prefix;

  /// Returns the stored algorithm when it is one the JWT signer supports.
  JwtAlgorithm? get parsedAlgorithm {
    for (final candidate in JwtAlgorithm.values) {
      if (candidate.label == algorithm) {
        return candidate;
      }
    }

    return null;
  }

  /// Returns the selected algorithm for display controls with a stable fallback.
  JwtAlgorithm get selectedAlgorithm {
    return parsedAlgorithm ?? JwtAlgorithm.hs256;
  }

  /// Returns true when the selected JWT algorithm uses an HMAC shared secret.
  bool get isHmacAlgorithm => selectedAlgorithm.isHmac;

  /// Returns true when the selected JWT algorithm requires a private key.
  bool get isPrivateKeyAlgorithm => selectedAlgorithm.isPrivateKey;

  /// Returns the Authorization value while avoiding duplicate whitespace.
  String authorizationValueForToken(String jwtToken) {
    final trimmedToken = jwtToken.trim();
    final trimmedPrefix = prefix.trim();
    if (trimmedPrefix.isEmpty) {
      return trimmedToken;
    }

    return '$trimmedPrefix $trimmedToken';
  }

  /// Creates a new JWT draft with any updated signing fields applied.
  JwtAuthDraft copyWith({
    String? token,
    String? header,
    String? payload,
    String? secret,
    String? algorithm,
    bool? base64EncodedSecret,
    String? privateKey,
    bool? sendAsHeader,
    String? prefix,
  }) => JwtAuthDraft(
    token: token ?? this.token,
    header: header ?? this.header,
    payload: payload ?? this.payload,
    secret: secret ?? this.secret,
    algorithm: algorithm ?? this.algorithm,
    base64EncodedSecret: base64EncodedSecret ?? this.base64EncodedSecret,
    privateKey: privateKey ?? this.privateKey,
    sendAsHeader: sendAsHeader ?? this.sendAsHeader,
    prefix: prefix ?? this.prefix,
  );

  @override
  List<Object> get props => [
    token,
    header,
    payload,
    secret,
    algorithm,
    base64EncodedSecret,
    privateKey,
    sendAsHeader,
    prefix,
  ];

  @override
  bool? get stringify => false;
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

  /// Prevents NTLM credentials from appearing in diagnostic string output.

  @override
  bool? get stringify => false;
}

class AwsAuthDraft extends Equatable {
  const AwsAuthDraft({
    this.accessKey = '',
    this.secretKey = '',
    this.region = '',
    this.service = '',
    this.sessionToken = '',
    this.asHeader = true,
  });

  final String accessKey;
  final String secretKey;
  final String region;
  final String service;
  final String sessionToken;
  final bool asHeader;

  /// Creates a new AWS draft with any updated signing fields applied.
  AwsAuthDraft copyWith({
    String? accessKey,
    String? secretKey,
    String? region,
    String? service,
    String? sessionToken,
    bool? asHeader,
  }) => AwsAuthDraft(
    accessKey: accessKey ?? this.accessKey,
    secretKey: secretKey ?? this.secretKey,
    region: region ?? this.region,
    service: service ?? this.service,
    sessionToken: sessionToken ?? this.sessionToken,
    asHeader: asHeader ?? this.asHeader,
  );

  @override
  List<Object> get props => [
    accessKey,
    secretKey,
    region,
    service,
    sessionToken,
    asHeader,
  ];

  @override
  bool? get stringify => false;
}

class OAuth1AuthDraft extends Equatable {
  const OAuth1AuthDraft({
    this.consumerKey = '',
    this.consumerSecret = '',
    this.token = '',
    this.tokenSecret = '',
    this.signatureMethod = 'HMAC-SHA1',
    this.verifier = '',
    this.callback = '',
    this.nonce = '',
    this.timestamp = '',
    this.version = '1.0',
    this.realm = '',
    this.asHeader = false,
    this.includeBodyHash = false,
    this.encodeSignature = true,
    this.includeEmptyParameters = false,
  });

  final String consumerKey;
  final String consumerSecret;
  final String token;
  final String tokenSecret;
  final String signatureMethod;
  final String verifier;
  final String callback;
  final String nonce;
  final String timestamp;
  final String version;
  final String realm;
  final bool asHeader;
  final bool includeBodyHash;
  final bool encodeSignature;
  final bool includeEmptyParameters;

  /// Returns true when the selected signature method is one of the unsupported RSA variants.
  bool get usesRsaSignature =>
      signatureMethod == 'RSA-SHA1' ||
      signatureMethod == 'RSA-SHA256' ||
      signatureMethod == 'RSA-SHA512';

  /// Creates a new OAuth1 draft with any updated credential or signing fields applied.
  OAuth1AuthDraft copyWith({
    String? consumerKey,
    String? consumerSecret,
    String? token,
    String? tokenSecret,
    String? signatureMethod,
    String? verifier,
    String? callback,
    String? nonce,
    String? timestamp,
    String? version,
    String? realm,
    bool? asHeader,
    bool? includeBodyHash,
    bool? encodeSignature,
    bool? includeEmptyParameters,
  }) => OAuth1AuthDraft(
    consumerKey: consumerKey ?? this.consumerKey,
    consumerSecret: consumerSecret ?? this.consumerSecret,
    token: token ?? this.token,
    tokenSecret: tokenSecret ?? this.tokenSecret,
    signatureMethod: signatureMethod ?? this.signatureMethod,
    verifier: verifier ?? this.verifier,
    callback: callback ?? this.callback,
    nonce: nonce ?? this.nonce,
    timestamp: timestamp ?? this.timestamp,
    version: version ?? this.version,
    realm: realm ?? this.realm,
    asHeader: asHeader ?? this.asHeader,
    includeBodyHash: includeBodyHash ?? this.includeBodyHash,
    encodeSignature: encodeSignature ?? this.encodeSignature,
    includeEmptyParameters:
        includeEmptyParameters ?? this.includeEmptyParameters,
  );

  @override
  List<Object> get props => [
    consumerKey,
    consumerSecret,
    token,
    tokenSecret,
    signatureMethod,
    verifier,
    callback,
    nonce,
    timestamp,
    version,
    realm,
    asHeader,
    includeBodyHash,
    encodeSignature,
    includeEmptyParameters,
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
    this.username = '',
    this.password = '',
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
  final String username;
  final String password;

  /// Returns true when the selected OAuth2 grant type uses the manual token flow.
  bool get isManual => grantType == OAuth2GrantType.manual;

  /// Returns true when manual OAuth2 has a token that can be applied to the request.
  bool get canApplyManualToken => isManual && accessToken.trim().isNotEmpty;

  /// Returns true when an implemented OAuth2 flow has produced a token that can be applied to the request.
  bool get canApplyAccessToken =>
      isImplementedGrantType && accessToken.trim().isNotEmpty;

  /// Returns true when the manual token should be synchronized into the Authorization header.
  bool get sendsTokenAsHeader => addTokenToHeader;

  /// Returns true when the selected OAuth2 grant type uses the authorization code flow.
  bool get isAuthorizationCode =>
      grantType == OAuth2GrantType.authorizationCode;

  /// Returns true when the selected OAuth2 grant type uses the implicit flow.
  bool get isImplicit => grantType == OAuth2GrantType.implicit;

  /// Returns true when the selected OAuth2 grant type uses the password credentials flow.
  bool get isPasswordCredentials =>
      grantType == OAuth2GrantType.passwordCredentials;

  /// Returns true when the selected OAuth2 grant type uses the client credentials flow.
  bool get isClientCredentials =>
      grantType == OAuth2GrantType.clientCredentials;

  /// Returns true when the selected OAuth2 grant type has an implemented flow.
  bool get isImplementedGrantType =>
      isManual ||
      isAuthorizationCode ||
      isImplicit ||
      isPasswordCredentials ||
      isClientCredentials;

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

  /// Returns the Authorization value with a Bearer fallback and no duplicate prefix.
  String get resolvedAuthorizationValue {
    final token = accessToken.trim();
    final configuredPrefix = headerPrefix.trim();
    final prefix = configuredPrefix.isEmpty ? 'Bearer' : configuredPrefix;

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
    String? username,
    String? password,
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
    username: username ?? this.username,
    password: password ?? this.password,
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
    username,
    password,
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
