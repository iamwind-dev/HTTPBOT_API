import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';

const _oauth2CodeVerifierCharacters =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

/// Generates a PKCE code verifier that satisfies RFC 7636 length and character rules.
String generateOAuth2CodeVerifier({int length = 64}) {
  final random = Random.secure();
  final buffer = StringBuffer();

  for (var index = 0; index < length; index++) {
    final characterIndex = random.nextInt(_oauth2CodeVerifierCharacters.length);
    buffer.write(_oauth2CodeVerifierCharacters[characterIndex]);
  }

  return buffer.toString();
}

/// Builds a PKCE code challenge from the verifier using the selected method.
String buildOAuth2CodeChallenge({
  required String codeVerifier,
  required OAuth2PkceMethod method,
}) {
  if (method == OAuth2PkceMethod.plain) {
    return codeVerifier;
  }

  final digest = sha256.convert(utf8.encode(codeVerifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}
