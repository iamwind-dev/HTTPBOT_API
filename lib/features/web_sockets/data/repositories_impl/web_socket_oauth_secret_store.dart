import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OAuth1SecretPair {
  const OAuth1SecretPair({this.consumerSecret = '', this.tokenSecret = ''});

  final String consumerSecret;
  final String tokenSecret;
}

/// Groups the OAuth2 values that must remain outside persisted request JSON.
class OAuth2SecretValues {
  const OAuth2SecretValues({
    this.accessToken = '',
    this.refreshToken = '',
    this.clientSecret = '',
    this.password = '',
    this.authorizationCode = '',
    this.codeVerifier = '',
  });

  final String accessToken;
  final String refreshToken;
  final String clientSecret;
  final String password;
  final String authorizationCode;
  final String codeVerifier;

  /// Returns true when no OAuth2 secret needs secure persistence.
  bool get isEmpty =>
      accessToken.isEmpty &&
      refreshToken.isEmpty &&
      clientSecret.isEmpty &&
      password.isEmpty &&
      authorizationCode.isEmpty &&
      codeVerifier.isEmpty;
}

/// Groups JWT signing values that must remain outside persisted request JSON.
class JwtSecretValues {
  const JwtSecretValues({this.secret = '', this.privateKey = ''});

  final String secret;
  final String privateKey;

  /// Returns true when no JWT signing material needs secure persistence.
  bool get isEmpty => secret.isEmpty && privateKey.isEmpty;
}

/// Groups AWS values that must remain outside persisted request JSON.
class AwsSecretValues {
  const AwsSecretValues({this.secretKey = '', this.sessionToken = ''});

  final String secretKey;
  final String sessionToken;

  /// Returns true when no AWS signing secret needs secure persistence.
  bool get isEmpty => secretKey.isEmpty && sessionToken.isEmpty;
}

abstract class WebSocketOAuthSecretStore {
  /// Restores the OAuth1 secrets saved for a WebSocket request id.
  Future<OAuth1SecretPair> read(String requestId);

  /// Saves OAuth1 secrets outside the JSON request payload.
  Future<void> write({
    required String requestId,
    required String consumerSecret,
    required String tokenSecret,
  });

  /// Removes saved OAuth1 secrets for a WebSocket request id.
  Future<void> delete(String requestId);

  /// Restores OAuth2 secrets saved for a WebSocket request id.
  Future<OAuth2SecretValues> readOAuth2(String requestId);

  /// Saves OAuth2 secrets outside the JSON request payload.
  Future<void> writeOAuth2({
    required String requestId,
    required OAuth2SecretValues secrets,
  });

  /// Removes saved OAuth2 secrets for a WebSocket request id.
  Future<void> deleteOAuth2(String requestId);

  /// Restores the API key value saved for a WebSocket request id.
  Future<String> readApiKey(String requestId);

  /// Saves an API key value outside the JSON request payload.
  Future<void> writeApiKey({required String requestId, required String value});

  /// Removes the saved API key value for a WebSocket request id.
  Future<void> deleteApiKey(String requestId);

  /// Restores the Bearer token saved for a WebSocket request id.
  Future<String> readBearerToken(String requestId);

  /// Saves a Bearer token outside the JSON request payload.
  Future<void> writeBearerToken({
    required String requestId,
    required String value,
  });

  /// Removes the saved Bearer token for a WebSocket request id.
  Future<void> deleteBearerToken(String requestId);

  /// Restores the Digest password saved for a WebSocket request id.
  Future<String> readDigestPassword(String requestId);

  /// Saves a Digest password outside the JSON request payload.
  Future<void> writeDigestPassword({
    required String requestId,
    required String value,
  });

  /// Removes the saved Digest password for a WebSocket request id.
  Future<void> deleteDigestPassword(String requestId);

  /// Restores the NTLM password saved for a WebSocket request id.
  Future<String> readNtlmPassword(String requestId);

  /// Saves an NTLM password outside the JSON request payload.
  Future<void> writeNtlmPassword({
    required String requestId,
    required String value,
  });

  /// Removes the saved NTLM password for a WebSocket request id.
  Future<void> deleteNtlmPassword(String requestId);

  /// Restores the Hawk Auth Key saved for a WebSocket request id.
  Future<String> readHawkKey(String requestId);

  /// Saves a Hawk Auth Key outside the JSON request payload.
  Future<void> writeHawkKey({required String requestId, required String value});

  /// Removes the saved Hawk Auth Key for a WebSocket request id.
  Future<void> deleteHawkKey(String requestId);

  /// Restores JWT signing values saved for a WebSocket request id.
  Future<JwtSecretValues> readJwt(String requestId);

  /// Saves JWT signing values outside the JSON request payload.
  Future<void> writeJwt({
    required String requestId,
    required JwtSecretValues secrets,
  });

  /// Removes JWT signing values for a WebSocket request id.
  Future<void> deleteJwt(String requestId);

  /// Restores AWS signing secrets saved for a WebSocket request id.
  Future<AwsSecretValues> readAws(String requestId);

  /// Saves AWS signing secrets outside the JSON request payload.
  Future<void> writeAws({
    required String requestId,
    required AwsSecretValues secrets,
  });

  /// Removes AWS signing secrets for a WebSocket request id.
  Future<void> deleteAws(String requestId);
}

class FlutterSecureWebSocketOAuthSecretStore
    implements WebSocketOAuthSecretStore {
  const FlutterSecureWebSocketOAuthSecretStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  static const _consumerSecretPrefix = 'websocket_oauth1_consumer_secret_';
  static const _tokenSecretPrefix = 'websocket_oauth1_token_secret_';
  static const _oauth2AccessTokenPrefix = 'websocket_oauth2_access_token_';
  static const _oauth2RefreshTokenPrefix = 'websocket_oauth2_refresh_token_';
  static const _oauth2ClientSecretPrefix = 'websocket_oauth2_client_secret_';
  static const _oauth2PasswordPrefix = 'websocket_oauth2_password_';
  static const _oauth2AuthorizationCodePrefix =
      'websocket_oauth2_authorization_code_';
  static const _oauth2CodeVerifierPrefix = 'websocket_oauth2_code_verifier_';
  static const _apiKeyValuePrefix = 'websocket_api_key_value_';
  static const _bearerTokenPrefix = 'websocket_bearer_token_';
  static const _digestPasswordPrefix = 'websocket_digest_password_';
  static const _ntlmPasswordPrefix = 'websocket_ntlm_password_';
  static const _hawkKeyPrefix = 'websocket_hawk_key_';
  static const _jwtSecretPrefix = 'websocket_jwt_secret_';
  static const _jwtPrivateKeyPrefix = 'websocket_jwt_private_key_';
  static const _awsSecretKeyPrefix = 'websocket_aws_secret_key_';
  static const _awsSessionTokenPrefix = 'websocket_aws_session_token_';

  /// Restores OAuth1 secrets from platform secure storage.
  @override
  Future<OAuth1SecretPair> read(String requestId) async => OAuth1SecretPair(
    consumerSecret:
        await _storage.read(key: _consumerSecretKey(requestId)) ?? '',
    tokenSecret: await _storage.read(key: _tokenSecretKey(requestId)) ?? '',
  );

  /// Writes OAuth1 secrets to platform secure storage.
  @override
  Future<void> write({
    required String requestId,
    required String consumerSecret,
    required String tokenSecret,
  }) async {
    await _storage.write(
      key: _consumerSecretKey(requestId),
      value: consumerSecret,
    );
    await _storage.write(key: _tokenSecretKey(requestId), value: tokenSecret);
  }

  /// Deletes OAuth1 secrets from platform secure storage.
  @override
  Future<void> delete(String requestId) async {
    await _storage.delete(key: _consumerSecretKey(requestId));
    await _storage.delete(key: _tokenSecretKey(requestId));
  }

  /// Restores OAuth2 secrets from platform secure storage.
  @override
  Future<OAuth2SecretValues> readOAuth2(
    String requestId,
  ) async => OAuth2SecretValues(
    accessToken:
        await _storage.read(key: '$_oauth2AccessTokenPrefix$requestId') ?? '',
    refreshToken:
        await _storage.read(key: '$_oauth2RefreshTokenPrefix$requestId') ?? '',
    clientSecret:
        await _storage.read(key: '$_oauth2ClientSecretPrefix$requestId') ?? '',
    password:
        await _storage.read(key: '$_oauth2PasswordPrefix$requestId') ?? '',
    authorizationCode:
        await _storage.read(key: '$_oauth2AuthorizationCodePrefix$requestId') ??
        '',
    codeVerifier:
        await _storage.read(key: '$_oauth2CodeVerifierPrefix$requestId') ?? '',
  );

  /// Writes OAuth2 secrets to platform secure storage.
  @override
  Future<void> writeOAuth2({
    required String requestId,
    required OAuth2SecretValues secrets,
  }) async {
    await _writeOrDelete(
      key: '$_oauth2AccessTokenPrefix$requestId',
      value: secrets.accessToken,
    );
    await _writeOrDelete(
      key: '$_oauth2RefreshTokenPrefix$requestId',
      value: secrets.refreshToken,
    );
    await _writeOrDelete(
      key: '$_oauth2ClientSecretPrefix$requestId',
      value: secrets.clientSecret,
    );
    await _writeOrDelete(
      key: '$_oauth2PasswordPrefix$requestId',
      value: secrets.password,
    );
    await _writeOrDelete(
      key: '$_oauth2AuthorizationCodePrefix$requestId',
      value: secrets.authorizationCode,
    );
    await _writeOrDelete(
      key: '$_oauth2CodeVerifierPrefix$requestId',
      value: secrets.codeVerifier,
    );
  }

  /// Deletes OAuth2 secrets from platform secure storage.
  @override
  Future<void> deleteOAuth2(String requestId) async {
    await _storage.delete(key: '$_oauth2AccessTokenPrefix$requestId');
    await _storage.delete(key: '$_oauth2RefreshTokenPrefix$requestId');
    await _storage.delete(key: '$_oauth2ClientSecretPrefix$requestId');
    await _storage.delete(key: '$_oauth2PasswordPrefix$requestId');
    await _storage.delete(key: '$_oauth2AuthorizationCodePrefix$requestId');
    await _storage.delete(key: '$_oauth2CodeVerifierPrefix$requestId');
  }

  /// Restores an API key value from platform secure storage.
  @override
  Future<String> readApiKey(String requestId) async =>
      await _storage.read(key: '$_apiKeyValuePrefix$requestId') ?? '';

  /// Writes or removes an API key value in platform secure storage.
  @override
  Future<void> writeApiKey({
    required String requestId,
    required String value,
  }) => _writeOrDelete(key: '$_apiKeyValuePrefix$requestId', value: value);

  /// Deletes an API key value from platform secure storage.
  @override
  Future<void> deleteApiKey(String requestId) =>
      _storage.delete(key: '$_apiKeyValuePrefix$requestId');

  /// Restores a Bearer token from platform secure storage.
  @override
  Future<String> readBearerToken(String requestId) async =>
      await _storage.read(key: '$_bearerTokenPrefix$requestId') ?? '';

  /// Writes or removes a Bearer token in platform secure storage.
  @override
  Future<void> writeBearerToken({
    required String requestId,
    required String value,
  }) => _writeOrDelete(key: '$_bearerTokenPrefix$requestId', value: value);

  /// Deletes a Bearer token from platform secure storage.
  @override
  Future<void> deleteBearerToken(String requestId) =>
      _storage.delete(key: '$_bearerTokenPrefix$requestId');

  /// Restores a Digest password from platform secure storage.
  @override
  Future<String> readDigestPassword(String requestId) async =>
      await _storage.read(key: '$_digestPasswordPrefix$requestId') ?? '';

  /// Writes or removes a Digest password in platform secure storage.
  @override
  Future<void> writeDigestPassword({
    required String requestId,
    required String value,
  }) => _writeOrDelete(key: '$_digestPasswordPrefix$requestId', value: value);

  /// Deletes a Digest password from platform secure storage.
  @override
  Future<void> deleteDigestPassword(String requestId) =>
      _storage.delete(key: '$_digestPasswordPrefix$requestId');

  /// Restores an NTLM password from platform secure storage.
  @override
  Future<String> readNtlmPassword(String requestId) async =>
      await _storage.read(key: '$_ntlmPasswordPrefix$requestId') ?? '';

  /// Writes or removes an NTLM password in platform secure storage.
  @override
  Future<void> writeNtlmPassword({
    required String requestId,
    required String value,
  }) => _writeOrDelete(key: '$_ntlmPasswordPrefix$requestId', value: value);

  /// Deletes an NTLM password from platform secure storage.
  @override
  Future<void> deleteNtlmPassword(String requestId) =>
      _storage.delete(key: '$_ntlmPasswordPrefix$requestId');

  /// Restores a Hawk Auth Key from platform secure storage.
  @override
  Future<String> readHawkKey(String requestId) async =>
      await _storage.read(key: '$_hawkKeyPrefix$requestId') ?? '';

  /// Writes or removes a Hawk Auth Key in platform secure storage.
  @override
  Future<void> writeHawkKey({
    required String requestId,
    required String value,
  }) => _writeOrDelete(key: '$_hawkKeyPrefix$requestId', value: value);

  /// Deletes a Hawk Auth Key from platform secure storage.
  @override
  Future<void> deleteHawkKey(String requestId) =>
      _storage.delete(key: '$_hawkKeyPrefix$requestId');

  /// Restores JWT signing values from platform secure storage.
  @override
  Future<JwtSecretValues> readJwt(String requestId) async => JwtSecretValues(
    secret: await _storage.read(key: '$_jwtSecretPrefix$requestId') ?? '',
    privateKey:
        await _storage.read(key: '$_jwtPrivateKeyPrefix$requestId') ?? '',
  );

  /// Writes or removes JWT signing values in platform secure storage.
  @override
  Future<void> writeJwt({
    required String requestId,
    required JwtSecretValues secrets,
  }) async {
    await _writeOrDelete(
      key: '$_jwtSecretPrefix$requestId',
      value: secrets.secret,
    );
    await _writeOrDelete(
      key: '$_jwtPrivateKeyPrefix$requestId',
      value: secrets.privateKey,
    );
  }

  /// Deletes JWT signing values from platform secure storage.
  @override
  Future<void> deleteJwt(String requestId) async {
    await _storage.delete(key: '$_jwtSecretPrefix$requestId');
    await _storage.delete(key: '$_jwtPrivateKeyPrefix$requestId');
  }

  /// Restores AWS signing secrets from platform secure storage.
  @override
  Future<AwsSecretValues> readAws(String requestId) async => AwsSecretValues(
    secretKey: await _storage.read(key: '$_awsSecretKeyPrefix$requestId') ?? '',
    sessionToken:
        await _storage.read(key: '$_awsSessionTokenPrefix$requestId') ?? '',
  );

  /// Writes or removes AWS signing secrets in platform secure storage.
  @override
  Future<void> writeAws({
    required String requestId,
    required AwsSecretValues secrets,
  }) async {
    await _writeOrDelete(
      key: '$_awsSecretKeyPrefix$requestId',
      value: secrets.secretKey,
    );
    await _writeOrDelete(
      key: '$_awsSessionTokenPrefix$requestId',
      value: secrets.sessionToken,
    );
  }

  /// Deletes AWS signing secrets from platform secure storage.
  @override
  Future<void> deleteAws(String requestId) async {
    await _storage.delete(key: '$_awsSecretKeyPrefix$requestId');
    await _storage.delete(key: '$_awsSessionTokenPrefix$requestId');
  }

  /// Stores non-empty values and removes obsolete secure values.
  Future<void> _writeOrDelete({required String key, required String value}) =>
      value.isEmpty
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);

  /// Builds the secure-storage key for the consumer secret.
  String _consumerSecretKey(String requestId) =>
      '$_consumerSecretPrefix$requestId';

  /// Builds the secure-storage key for the token secret.
  String _tokenSecretKey(String requestId) => '$_tokenSecretPrefix$requestId';
}
