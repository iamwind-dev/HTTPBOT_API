import 'package:equatable/equatable.dart';

/// Parsed parameters of a `WWW-Authenticate: Digest ...` challenge.
class DigestChallenge extends Equatable {
  const DigestChallenge({
    this.realm = '',
    this.nonce = '',
    this.opaque = '',
    this.algorithm = '',
    this.qopOptions = const <String>[],
    this.stale = false,
  });

  final String realm;
  final String nonce;
  final String opaque;
  final String algorithm;
  final List<String> qopOptions;
  final bool stale;

  /// Returns the qop the client should answer with, preferring `auth`.
  String get preferredQop {
    if (qopOptions.contains('auth')) {
      return 'auth';
    }

    return qopOptions.isEmpty ? '' : qopOptions.first;
  }

  @override
  List<Object> get props => [
    realm,
    nonce,
    opaque,
    algorithm,
    qopOptions,
    stale,
  ];
}

final _parameterPattern = RegExp(r'(\w[\w-]*)\s*=\s*(?:"([^"]*)"|([^\s,]+))');

/// Parses a Digest challenge header value, returning null for non-Digest schemes.
DigestChallenge? parseDigestChallenge(String headerValue) {
  final trimmed = headerValue.trim();
  if (!trimmed.toLowerCase().startsWith('digest')) {
    return null;
  }

  final parameters = <String, String>{};
  for (final match in _parameterPattern.allMatches(trimmed.substring(6))) {
    final key = match.group(1)!.toLowerCase();
    final value = match.group(2) ?? match.group(3) ?? '';
    parameters[key] = value;
  }

  final qopOptions = (parameters['qop'] ?? '')
      .split(',')
      .map((option) => option.trim())
      .where((option) => option.isNotEmpty)
      .toList(growable: false);

  return DigestChallenge(
    realm: parameters['realm'] ?? '',
    nonce: parameters['nonce'] ?? '',
    opaque: parameters['opaque'] ?? '',
    algorithm: parameters['algorithm'] ?? '',
    qopOptions: List<String>.unmodifiable(qopOptions),
    stale: (parameters['stale'] ?? '').toLowerCase() == 'true',
  );
}
