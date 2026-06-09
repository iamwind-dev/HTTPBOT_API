import 'dart:convert';

import '../entities/request_auth_draft.dart';

class BuildBasicAuthorizationHeaderUseCase {
  const BuildBasicAuthorizationHeaderUseCase();

  /// Returns the Basic Authorization header value when either credential is present.
  String? call(BasicAuthDraft basicAuth) {
    if (_credentialsAreEmpty(basicAuth)) {
      return null;
    }

    final credentials = base64Encode(
      utf8.encode('${basicAuth.username}:${basicAuth.password}'),
    );

    return 'Basic $credentials';
  }

  /// Returns true when both Basic auth inputs are blank after trimming.
  bool _credentialsAreEmpty(BasicAuthDraft basicAuth) =>
      basicAuth.username.trim().isEmpty && basicAuth.password.trim().isEmpty;
}
