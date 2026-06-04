import 'dart:convert';

import '../entities/request_auth_draft.dart';

class BuildBasicAuthorizationHeaderUseCase {
  const BuildBasicAuthorizationHeaderUseCase();

  /// Returns the Basic Authorization header value when both credentials are present.
  String? call(BasicAuthDraft basicAuth) {
    if (!_hasCompleteCredentials(basicAuth)) {
      return null;
    }

    final credentials = base64Encode(
      utf8.encode('${basicAuth.username}:${basicAuth.password}'),
    );

    return 'Basic $credentials';
  }

  /// Returns true when both Basic auth inputs contain non-whitespace characters.
  bool _hasCompleteCredentials(BasicAuthDraft basicAuth) =>
      basicAuth.username.trim().isNotEmpty &&
      basicAuth.password.trim().isNotEmpty;
}
