import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jwt;

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

  /// Builds a JWT token from the auth draft using its selected signing algorithm.
  JwtBuildResult build(JwtAuthDraft auth) {
    final algorithm = auth.parsedAlgorithm;
    if (algorithm == null) {
      return JwtBuildResult(
        isValid: false,
        errorMessage: 'Unsupported JWT algorithm: ${auth.algorithm}.',
      );
    }
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

      return _buildAsymmetricToken(
        algorithm: algorithm,
        header: resolvedHeader,
        payload: payload.value,
        privateKey: auth.privateKey,
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

  /// Signs an asymmetric JWT through the JOSE-aware package implementation.
  JwtBuildResult _buildAsymmetricToken({
    required JwtAlgorithm algorithm,
    required Map<String, Object?> header,
    required Map<String, Object?> payload,
    required String privateKey,
  }) {
    try {
      final key = switch (algorithm) {
        JwtAlgorithm.rs256 ||
        JwtAlgorithm.rs384 ||
        JwtAlgorithm.rs512 ||
        JwtAlgorithm.ps256 ||
        JwtAlgorithm.ps384 ||
        JwtAlgorithm.ps512 => jwt.RSAPrivateKey(privateKey),
        JwtAlgorithm.es256 ||
        JwtAlgorithm.es384 ||
        JwtAlgorithm.es512 => jwt.ECPrivateKey(privateKey),
        _ => throw StateError('Unsupported asymmetric JWT algorithm.'),
      };
      final token = jwt
          .JWT(payload, header: Map<String, dynamic>.from(header))
          .sign(key, algorithm: _toJoseAlgorithm(algorithm), noIssueAt: true);
      return JwtBuildResult(isValid: true, token: token);
    } on Object {
      return const JwtBuildResult(
        isValid: false,
        errorMessage: 'Invalid Private Key for JWT.',
      );
    }
  }

  /// Maps the app's persisted JWT algorithm to the signing package enum.
  jwt.JWTAlgorithm _toJoseAlgorithm(JwtAlgorithm algorithm) =>
      switch (algorithm) {
        JwtAlgorithm.rs256 => jwt.JWTAlgorithm.RS256,
        JwtAlgorithm.rs384 => jwt.JWTAlgorithm.RS384,
        JwtAlgorithm.rs512 => jwt.JWTAlgorithm.RS512,
        JwtAlgorithm.ps256 => jwt.JWTAlgorithm.PS256,
        JwtAlgorithm.ps384 => jwt.JWTAlgorithm.PS384,
        JwtAlgorithm.ps512 => jwt.JWTAlgorithm.PS512,
        JwtAlgorithm.es256 => jwt.JWTAlgorithm.ES256,
        JwtAlgorithm.es384 => jwt.JWTAlgorithm.ES384,
        JwtAlgorithm.es512 => jwt.JWTAlgorithm.ES512,
        _ => throw StateError('Unsupported asymmetric JWT algorithm.'),
      };

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
