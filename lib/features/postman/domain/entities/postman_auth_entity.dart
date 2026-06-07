enum PostmanAuthType {
  none,
  basic,
  apiKey,
  bearerToken,
  digest,
  hawk,
  jwt,
  ntlm,
  awsSignature,
  oauth1,
  oauth2,
}

enum PostmanApiKeyLocation { header, query, cookie }

class PostmanBasicAuthEntity {
  const PostmanBasicAuthEntity({
    this.username = '',
    this.password = '',
  });

  final String username;
  final String password;
}

class PostmanApiKeyAuthEntity {
  const PostmanApiKeyAuthEntity({
    this.key = '',
    this.value = '',
    this.location = PostmanApiKeyLocation.header,
  });

  final String key;
  final String value;
  final PostmanApiKeyLocation location;
}

class PostmanBearerAuthEntity {
  const PostmanBearerAuthEntity({
    this.token = '',
    this.prefix = 'Bearer',
  });

  final String token;
  final String prefix;
}

class PostmanDigestAuthEntity {
  const PostmanDigestAuthEntity({
    this.username = '',
    this.password = '',
    this.realm = '',
    this.nonce = '',
    this.algorithm = '',
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
}

class PostmanHawkAuthEntity {
  const PostmanHawkAuthEntity({
    this.identifier = '',
    this.key = '',
    this.algorithm = '',
    this.app = '',
    this.delegation = '',
  });

  final String identifier;
  final String key;
  final String algorithm;
  final String app;
  final String delegation;
}

class PostmanJwtAuthEntity {
  const PostmanJwtAuthEntity({
    this.token = '',
    this.header = '',
    this.payload = '',
    this.secret = '',
    this.algorithm = '',
    this.prefix = 'Bearer',
  });

  final String token;
  final String header;
  final String payload;
  final String secret;
  final String algorithm;
  final String prefix;
}

class PostmanNtlmAuthEntity {
  const PostmanNtlmAuthEntity({
    this.username = '',
    this.password = '',
    this.domain = '',
    this.workstation = '',
  });

  final String username;
  final String password;
  final String domain;
  final String workstation;
}

class PostmanAwsAuthEntity {
  const PostmanAwsAuthEntity({
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
}

class PostmanOAuth1AuthEntity {
  const PostmanOAuth1AuthEntity({
    this.consumerKey = '',
    this.consumerSecret = '',
    this.token = '',
    this.tokenSecret = '',
    this.signatureMethod = '',
    this.nonce = '',
    this.timestamp = '',
    this.version = '',
  });

  final String consumerKey;
  final String consumerSecret;
  final String token;
  final String tokenSecret;
  final String signatureMethod;
  final String nonce;
  final String timestamp;
  final String version;
}

class PostmanOAuth2AuthEntity {
  const PostmanOAuth2AuthEntity({
    this.accessToken = '',
    this.refreshToken = '',
    this.clientId = '',
    this.clientSecret = '',
    this.tokenUrl = '',
    this.scopes = const [],
  });

  final String accessToken;
  final String refreshToken;
  final String clientId;
  final String clientSecret;
  final String tokenUrl;
  final List<String> scopes;
}

class PostmanAuthEntity {
  const PostmanAuthEntity({
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
}
