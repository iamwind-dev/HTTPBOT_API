import 'dart:convert';

import '../entities/request_auth_draft.dart';

class BuildBasicAuthorizationHeaderUseCase {
  const BuildBasicAuthorizationHeaderUseCase();

  /// Returns the Basic Authorization header value when the username is present.
  String? call(BasicAuthDraft basicAuth) {
    if (_usernameIsEmpty(basicAuth)) {
      return null;
    }

    final credentials = base64Encode(
      utf8.encode('${basicAuth.username}:${basicAuth.password}'),
    );

    return 'Basic $credentials';
  }

  /// Returns true when Basic auth cannot intentionally generate credentials.
  bool _usernameIsEmpty(BasicAuthDraft basicAuth) =>
      basicAuth.username.trim().isEmpty;
}
