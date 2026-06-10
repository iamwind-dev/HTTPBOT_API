import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';

class JwtBuildResult {
  /// Wraps a generated JWT or a stable validation error.
  const JwtBuildResult({
    required this.isValid,
    this.token = '',
    this.errorMessage,
  });

  final bool isValid;
  final String token;
  final String? errorMessage;
}

class JwtTokenBuilder {
  const JwtTokenBuilder();

  /// Builds a JWT token from the auth draft using supported HMAC algorithms.
  JwtBuildResult build(JwtAuthDraft auth) {
    final algorithm = auth.selectedAlgorithm;
    final header = _parseJsonObject(
      auth.header,
      emptyFallback: <String, Object?>{'typ': 'JWT', 'alg': algorithm.label},
      errorMessage: 'JWT header must be a valid JSON object.',
    );
    if (header.errorMessage != null) {
      return JwtBuildResult(isValid: false, errorMessage: header.errorMessage);
    }

    final payload = _parseJsonObject(
      auth.payload,
      emptyFallback: <String, Object?>{},
      errorMessage: 'JWT payload must be a valid JSON object.',
    );
    if (payload.errorMessage != null) {
      return JwtBuildResult(isValid: false, errorMessage: payload.errorMessage);
    }

    final resolvedHeader = Map<String, Object?>.from(header.value)
      ..['typ'] = header.value['typ'] ?? 'JWT'
      ..['alg'] = algorithm.label;

    if (algorithm.isPrivateKey) {
      if (auth.privateKey.trim().isEmpty) {
        return const JwtBuildResult(
          isValid: false,
          errorMessage: 'Private Key is required for JWT.',
        );
      }

      return JwtBuildResult(
        isValid: false,
        errorMessage: '${algorithm.label} signing is not implemented yet.',
      );
    }

    if (auth.secret.isEmpty) {
      return const JwtBuildResult(
        isValid: false,
        errorMessage: 'Secret is required for JWT.',
      );
    }

    final secretBytes = _resolveSecretBytes(auth);
    if (secretBytes == null) {
      return const JwtBuildResult(
        isValid: false,
        errorMessage: 'Invalid Base64 encoded secret.',
      );
    }

    final encodedHeader = _base64UrlNoPadding(
      utf8.encode(jsonEncode(resolvedHeader)),
    );
    final encodedPayload = _base64UrlNoPadding(
      utf8.encode(jsonEncode(payload.value)),
    );
    final signingInput = '$encodedHeader.$encodedPayload';
    final signature = _signHmac(
      algorithm: algorithm,
      secretBytes: secretBytes,
      signingInput: signingInput,
    );

    return JwtBuildResult(
      isValid: true,
      token: '$signingInput.${_base64UrlNoPadding(signature)}',
    );
  }

  _JsonObjectParseResult _parseJsonObject(
    String input, {
    required Map<String, Object?> emptyFallback,
    required String errorMessage,
  }) {
    if (input.trim().isEmpty) {
      return _JsonObjectParseResult(value: emptyFallback);
    }

    try {
      final decoded = jsonDecode(input);
      if (decoded is Map) {
        return _JsonObjectParseResult(
          value: Map<String, Object?>.from(decoded),
        );
      }
    } on FormatException {
      return _JsonObjectParseResult(errorMessage: errorMessage);
    }

    return _JsonObjectParseResult(errorMessage: errorMessage);
  }

  List<int>? _resolveSecretBytes(JwtAuthDraft auth) {
    if (!auth.base64EncodedSecret) {
      return utf8.encode(auth.secret);
    }

    try {
      return base64Url.decode(base64Url.normalize(auth.secret.trim()));
    } on FormatException {
      return null;
    }
  }

  List<int> _signHmac({
    required JwtAlgorithm algorithm,
    required List<int> secretBytes,
    required String signingInput,
  }) {
    final digest = switch (algorithm) {
      JwtAlgorithm.hs256 => sha256,
      JwtAlgorithm.hs384 => sha384,
      JwtAlgorithm.hs512 => sha512,
      _ => sha256,
    };

    return Hmac(digest, secretBytes).convert(utf8.encode(signingInput)).bytes;
  }

  String _base64UrlNoPadding(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');
}

class _JsonObjectParseResult {
  /// Stores either a parsed JSON object or the user-facing validation error.
  const _JsonObjectParseResult({
    this.value = const <String, Object?>{},
    this.errorMessage,
  });

  final Map<String, Object?> value;
  final String? errorMessage;
}
