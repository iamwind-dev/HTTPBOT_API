import '../entities/request_auth_draft.dart';
import '../entities/request_key_value.dart';
import 'auth_authorization_header_policy.dart';

/// Synchronizes Authorization with Basic or Bearer auth settings.
List<KeyValueItem> syncAuthorizationHeaderWithAuth({
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
}) {
  final headersWithoutSystemAuth = headers
      .where((header) => !_isGeneratedAuthorizationHeaderForBasicBearer(header))
      .toList(growable: false);
  final authorizationValue = buildAuthorizationValueFromAuth(auth);
  final shouldGenerateAuthorization =
      authorizationValue != null &&
      (auth.type == AuthType.basic || auth.type == AuthType.bearerToken);

  if (!shouldGenerateAuthorization ||
      headersWithoutSystemAuth.any(_isUserDefinedAuthorizationHeader)) {
    return List<KeyValueItem>.unmodifiable(headersWithoutSystemAuth);
  }

  return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
    ...headersWithoutSystemAuth,
    KeyValueItem(
      key: 'Authorization',
      value: authorizationValue,
      description: _authorizationDescriptionForAuthType(auth.type),
      source: RequestHeaderSource.systemAuth,
      systemTag: _authorizationSystemTagForAuthType(auth.type),
    ),
  ]);
}

/// Returns true when an enabled row owns Authorization outside editor automation.
bool _isUserDefinedAuthorizationHeader(KeyValueItem header) =>
    header.isEnabled &&
    header.key.trim().toLowerCase() == 'authorization' &&
    !_isGeneratedAuthorizationHeaderForBasicBearer(header);

/// Returns true when a header row belongs to the Basic or Bearer auth sync flow.
bool _isGeneratedAuthorizationHeaderForBasicBearer(KeyValueItem header) =>
    header.isBasicAuthSystemGeneratedHeader ||
    header.isBearerTokenSystemGeneratedHeader;

/// Returns the editor metadata used for the active auth-generated Authorization row.
String _authorizationDescriptionForAuthType(AuthType authType) =>
    switch (authType) {
      AuthType.basic => basicAuthSystemGeneratedHeaderDescription,
      AuthType.bearerToken => bearerTokenSystemGeneratedHeaderDescription,
      _ => bearerTokenSystemGeneratedHeaderDescription,
    };

/// Returns the stable ownership tag for Basic and Bearer generated headers.
String _authorizationSystemTagForAuthType(AuthType authType) =>
    switch (authType) {
      AuthType.basic => 'basicAuth',
      AuthType.bearerToken => 'bearerAuth',
      _ => 'bearerAuth',
    };
