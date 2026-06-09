import '../../domain/entities/oauth2_token_details_entity.dart';
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/repositories/oauth2_repository.dart';
import '../datasources/oauth2_remote_datasource.dart';

class OAuth2RepositoryImpl implements OAuth2Repository {
  const OAuth2RepositoryImpl(this._remoteDataSource);

  final OAuth2RemoteDataSource _remoteDataSource;

  /// Exchanges the OAuth2 authorization code and maps the data response into a domain token payload.
  @override
  Future<OAuth2TokenDetailsEntity> exchangeAuthorizationCode({
    required OAuth2AuthDraft auth,
    required String code,
  }) async {
    final response = await _remoteDataSource.exchangeAuthorizationCode(
      auth: auth,
      code: code,
    );

    return OAuth2TokenDetailsEntity(
      success: true,
      resolvedAuthUrl: '',
      accessToken: response.token.accessToken,
      tokenType: response.token.tokenType,
      scope: response.token.scope?.trim() ?? '',
      refreshToken: response.token.refreshToken,
      expiresIn: response.token.expiresIn,
      request: OAuth2TokenRequestDebugInfo(
        method: 'POST',
        url: auth.resolvedAccessTokenUrl,
        headers: response.requestHeaders,
        bodyFields: response.requestBodyFields,
        encodedBody: response.encodedRequestBody,
      ),
      response: OAuth2TokenResponseDebugInfo(
        statusCode: response.statusCode,
        headers: response.responseHeaders,
        jsonBody: response.responseJsonBody,
        rawBody: response.responseRawBody,
      ),
    );
  }
}
