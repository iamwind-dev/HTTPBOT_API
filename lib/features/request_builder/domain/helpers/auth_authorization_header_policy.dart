import '../entities/request_auth_draft.dart';
import '../usecases/build_basic_authorization_header_use_case.dart';
import '../usecases/build_bearer_authorization_header_use_case.dart';

const _buildBasicAuthorizationHeaderUseCase =
    BuildBasicAuthorizationHeaderUseCase();
const _buildBearerAuthorizationHeaderUseCase =
    BuildBearerAuthorizationHeaderUseCase();

/// Returns the Basic Authorization header value for the provided credentials.
String? buildBasicAuthorizationValue({
  required String username,
  required String password,
}) => _buildBasicAuthorizationHeaderUseCase(
  BasicAuthDraft(username: username, password: password),
);

/// Returns the Bearer Authorization header value for a bearer token.
String? buildBearerAuthorizationValue(String token) =>
    _buildBearerAuthorizationHeaderUseCase(BearerTokenAuthDraft(token: token));

/// Returns the Bearer Authorization header value for a prebuilt JWT token.
String? buildJwtAuthorizationValue(String jwt) =>
    _buildBearerAuthorizationHeaderUseCase(BearerTokenAuthDraft(token: jwt));

/// Returns the Authorization header value implied by the active auth mode.
String? buildAuthorizationValueFromAuth(RequestAuthDraft auth) {
  return switch (auth.type) {
    AuthType.basic => buildBasicAuthorizationValue(
      username: auth.basic.username,
      password: auth.basic.password,
    ),
    AuthType.bearerToken => buildBearerAuthorizationValue(
      auth.bearerToken.token,
    ),
    AuthType.none ||
    AuthType.apiKey ||
    AuthType.digest ||
    AuthType.hawk ||
    AuthType.jwt ||
    AuthType.ntlm ||
    AuthType.awsSignature ||
    AuthType.oauth1 ||
    AuthType.oauth2 => null,
  };
}
