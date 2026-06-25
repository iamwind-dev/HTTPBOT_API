import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';
import 'digest_challenge_parser.dart';

class DigestAuthorizationResult {
  /// Wraps a Digest header build outcome so callers can short-circuit on failure.
  const DigestAuthorizationResult._({
    required this.isValid,
    this.authorizationHeader = '',
    this.errorMessage,
  });

  /// Creates a successful result carrying the full Authorization value.
  const DigestAuthorizationResult.valid(String authorizationHeader)
    : this._(isValid: true, authorizationHeader: authorizationHeader);

  /// Creates a failed result with a stable user-facing message.
  const DigestAuthorizationResult.invalid(String message)
    : this._(isValid: false, errorMessage: message);

  final bool isValid;
  final String authorizationHeader;
  final String? errorMessage;
}

/// Returns the request-uri (path plus query) used in Digest computations.
String buildDigestUri(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return '/';
  }

  final path = uri.path.isEmpty ? '/' : uri.path;

  return uri.hasQuery ? '$path?${uri.query}' : path;
}

class DigestAuthorizationHeaderBuilder {
  const DigestAuthorizationHeaderBuilder({String Function()? cnonceGenerator})
    : _cnonceGenerator = cnonceGenerator;

  final String Function()? _cnonceGenerator;

  /// Builds the Digest Authorization header from the draft, merged with an
  /// optional server challenge.
  ///
  /// Draft realm/nonce/opaque/qop win when set; the challenge fills the gaps.
  /// The challenge algorithm wins in challenge-based mode, mirroring what the
  /// server will use to verify the response.
  DigestAuthorizationResult build({
    required String method,
    required String url,
    required DigestAuthDraft digest,
    DigestChallenge? challenge,
  }) {
    final username = digest.username.trim();
    final password = digest.password;
    final realm = _firstNonEmpty(digest.realm, challenge?.realm);
    final nonce = _firstNonEmpty(digest.nonce, challenge?.nonce);
    final opaque = _firstNonEmpty(digest.opaque, challenge?.opaque);
    final qop = _firstNonEmpty(digest.qop, challenge?.preferredQop);
    final algorithmLabel = challenge != null && challenge.algorithm.isNotEmpty
        ? challenge.algorithm
        : digest.algorithm;

    if (username.isEmpty) {
      return const DigestAuthorizationResult.invalid(
        'Username is required for Digest.',
      );
    }
    if (password.isEmpty) {
      return const DigestAuthorizationResult.invalid(
        'Password is required for Digest.',
      );
    }
    if (realm.isEmpty) {
      return const DigestAuthorizationResult.invalid(
        'Realm is required for Digest.',
      );
    }
    if (nonce.isEmpty) {
      return const DigestAuthorizationResult.invalid(
        'Nonce is required for Digest.',
      );
    }
    if (qop == 'auth-int') {
      return const DigestAuthorizationResult.invalid(
        'Digest qop=auth-int is not implemented yet.',
      );
    }
    if (qop.isNotEmpty && qop != 'auth') {
      return const DigestAuthorizationResult.invalid(
        'Could not build Digest Authorization header.',
      );
    }

    final algorithm = _algorithmFromLabel(algorithmLabel);
    if (algorithm == null) {
      return const DigestAuthorizationResult.invalid(
        'Could not build Digest Authorization header.',
      );
    }

    final digestUri = buildDigestUri(url);
    final usesQop = qop.isNotEmpty;
    final nonceCount = usesQop
        ? _firstNonEmpty(digest.nonceCount, '00000001')
        : '';
    final clientNonce = usesQop || algorithm.isSessionVariant
        ? _firstNonEmpty(digest.clientNonce, _generateCnonce())
        : '';

    String hash(String input) => _hash(algorithm, input);

    var ha1 = hash('$username:$realm:$password');
    if (algorithm.isSessionVariant) {
      ha1 = hash('$ha1:$nonce:$clientNonce');
    }
    final ha2 = hash('$method:$digestUri');
    final response = usesQop
        ? hash('$ha1:$nonce:$nonceCount:$clientNonce:$qop:$ha2')
        : hash('$ha1:$nonce:$ha2');

    final parts = <String>[
      'username="$username"',
      'realm="$realm"',
      'nonce="$nonce"',
      'uri="$digestUri"',
      'algorithm=${algorithm.label}',
      if (usesQop) 'qop=$qop',
      if (usesQop) 'nc=$nonceCount',
      if (clientNonce.isNotEmpty) 'cnonce="$clientNonce"',
      'response="$response"',
      if (opaque.isNotEmpty) 'opaque="$opaque"',
    ];

    return DigestAuthorizationResult.valid('Digest ${parts.join(', ')}');
  }

  /// Returns the first value with meaningful input, defaulting to empty.
  String _firstNonEmpty(String primary, String? fallback) {
    final trimmedPrimary = primary.trim();
    if (trimmedPrimary.isNotEmpty) {
      return trimmedPrimary;
    }

    return fallback?.trim() ?? '';
  }

  /// Resolves the algorithm enum from a UI or challenge label.
  DigestAlgorithm? _algorithmFromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) {
      return DigestAlgorithm.md5;
    }

    for (final candidate in DigestAlgorithm.values) {
      if (candidate.label.toLowerCase() == normalized) {
        return candidate;
      }
    }

    return null;
  }

  /// Hashes the input with the digest algorithm family as lowercase hex.
  String _hash(DigestAlgorithm algorithm, String input) {
    final bytes = utf8.encode(input);

    return switch (algorithm) {
      DigestAlgorithm.md5 || DigestAlgorithm.md5Sess => md5
          .convert(bytes)
          .toString(),
      DigestAlgorithm.sha256 || DigestAlgorithm.sha256Sess => sha256
          .convert(bytes)
          .toString(),
      DigestAlgorithm.sha512256 || DigestAlgorithm.sha512256Sess => sha512256
          .convert(bytes)
          .toString(),
    };
  }

  /// Generates a random hex client nonce when the user left it empty.
  String _generateCnonce() {
    if (_cnonceGenerator != null) {
      return _cnonceGenerator();
    }

    final random = Random.secure();

    return List<String>.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
