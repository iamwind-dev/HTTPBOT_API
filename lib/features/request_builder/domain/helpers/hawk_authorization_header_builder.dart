import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/requests_method.dart';

class HawkSigningResult {
  /// Wraps a Hawk header build outcome so callers can short-circuit on failure.
  const HawkSigningResult._({
    required this.isValid,
    this.authorizationHeader = '',
    this.timestamp = '',
    this.nonce = '',
    this.payloadHash,
    this.errorMessage,
  });

  /// Creates a successful result carrying the full Authorization value.
  const HawkSigningResult.valid({
    required String authorizationHeader,
    required String timestamp,
    required String nonce,
    String? payloadHash,
  }) : this._(
         isValid: true,
         authorizationHeader: authorizationHeader,
         timestamp: timestamp,
         nonce: nonce,
         payloadHash: payloadHash,
       );

  /// Creates a failed result with a stable user-facing message.
  const HawkSigningResult.invalid(String message)
    : this._(isValid: false, errorMessage: message);

  final bool isValid;
  final String authorizationHeader;
  final String timestamp;
  final String nonce;
  final String? payloadHash;
  final String? errorMessage;
}

class HawkSigningContext {
  const HawkSigningContext({required this.timestamp, required this.nonce});

  final int timestamp;
  final String nonce;
}

class HawkAuthorizationHeaderBuilder {
  HawkAuthorizationHeaderBuilder({
    DateTime Function()? now,
    String Function()? nonceGenerator,
  }) : _now = now ?? DateTime.now,
       _nonceGenerator = nonceGenerator ?? _generateNonce;

  final DateTime Function() _now;
  final String Function() _nonceGenerator;

  /// Resolves manual or generated values once for a single signing attempt.
  HawkSigningContext createSigningContext(HawkAuthDraft hawk) {
    final manualTimestamp = hawk.timestamp.trim();
    return HawkSigningContext(
      timestamp: manualTimestamp.isEmpty
          ? _now().millisecondsSinceEpoch ~/ 1000
          : int.parse(manualTimestamp),
      nonce: hawk.nonce.trim().isEmpty
          ? _nonceGenerator()
          : hawk.nonce.trim(),
    );
  }

  /// Builds the Hawk Authorization header for the request pieces.
  ///
  /// The MAC covers the `hawk.1.header` normalized string; the optional
  /// payload hash covers the `hawk.1.payload` normalized string. The User
  /// field is editor state only and never enters the header.
  HawkSigningResult build({
    required HttpMethod method,
    required String url,
    required RequestBodyDraft body,
    required HawkAuthDraft hawk,
    HawkSigningContext? signingContext,
  }) {
    final identifier = hawk.identifier.trim();
    if (identifier.isEmpty) {
      return const HawkSigningResult.invalid('Auth ID is required for Hawk.');
    }
    if (hawk.key.isEmpty) {
      return const HawkSigningResult.invalid('Auth Key is required for Hawk.');
    }

    final manualTimestamp = hawk.timestamp.trim();
    if (manualTimestamp.isNotEmpty && int.tryParse(manualTimestamp) == null) {
      return const HawkSigningResult.invalid('Invalid Hawk timestamp.');
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return const HawkSigningResult.invalid(
        'Could not build Hawk Authorization header.',
      );
    }

    final timestamp = signingContext?.timestamp.toString() ??
        (manualTimestamp.isNotEmpty
            ? manualTimestamp
            : (_now().millisecondsSinceEpoch ~/ 1000).toString());
    final nonce = signingContext?.nonce ??
        (hawk.nonce.trim().isNotEmpty ? hawk.nonce.trim() : _nonceGenerator());
    final algorithm = hawk.selectedAlgorithm;

    String? payloadHash;
    if (hawk.includePayloadHash) {
      if (body.type == RequestBodyType.formData) {
        return const HawkSigningResult.invalid(
          'Hawk payload hash is not supported for multipart bodies yet.',
        );
      }

      final payloadText = _extractPayloadText(body);
      if (payloadText == null) {
        return const HawkSigningResult.invalid(
          'Could not build Hawk Authorization header.',
        );
      }

      payloadHash = base64Encode(
        _hashAlgorithm(algorithm)
            .convert(
              utf8.encode(
                'hawk.1.payload\n${_payloadContentType(body)}\n$payloadText\n',
              ),
            )
            .bytes,
      );
    }

    final host = uri.host.toLowerCase();
    final port = uri.hasPort
        ? uri.port.toString()
        : (uri.scheme == 'https' ? '443' : '80');
    final path = uri.path.isEmpty ? '/' : uri.path;
    final resource = uri.hasQuery ? '$path?${uri.query}' : path;
    final ext = hawk.ext.trim();
    final app = hawk.app.trim();
    final dlg = hawk.delegation.trim();

    var normalized =
        'hawk.1.header\n'
        '$timestamp\n'
        '$nonce\n'
        '${method.wireName.toUpperCase()}\n'
        '$resource\n'
        '$host\n'
        '$port\n'
        '${payloadHash ?? ''}\n'
        '$ext\n';
    if (app.isNotEmpty) {
      normalized += '$app\n$dlg\n';
    }

    final mac = base64Encode(
      Hmac(_hashAlgorithm(algorithm), utf8.encode(hawk.key))
          .convert(utf8.encode(normalized))
          .bytes,
    );

    final attributes = <String>[
      'id="$identifier"',
      'ts="$timestamp"',
      'nonce="$nonce"',
      if (payloadHash != null) 'hash="$payloadHash"',
      if (ext.isNotEmpty) 'ext="$ext"',
      'mac="$mac"',
      if (app.isNotEmpty) 'app="$app"',
      if (app.isNotEmpty && dlg.isNotEmpty) 'dlg="$dlg"',
    ];

    return HawkSigningResult.valid(
      authorizationHeader: 'Hawk ${attributes.join(', ')}',
      timestamp: timestamp,
      nonce: nonce,
      payloadHash: payloadHash,
    );
  }

  /// Returns the crypto hash backing the selected Hawk algorithm.
  Hash _hashAlgorithm(HawkAlgorithm algorithm) => switch (algorithm) {
    HawkAlgorithm.sha256 => sha256,
    HawkAlgorithm.sha1 => sha1,
  };

  /// Returns the lower-cased media type used in the payload normalized string.
  String _payloadContentType(RequestBodyDraft body) => switch (body.type) {
    RequestBodyType.none => '',
    RequestBodyType.raw => body.raw.subtype.contentType.toLowerCase(),
    RequestBodyType.xWwwFormUrlEncoded => 'application/x-www-form-urlencoded',
    RequestBodyType.graphql => 'application/json',
    RequestBodyType.formData => '',
  };

  /// Returns the payload text to hash, or null when it cannot be derived.
  String? _extractPayloadText(RequestBodyDraft body) {
    switch (body.type) {
      case RequestBodyType.none:
        return '';
      case RequestBodyType.raw:
        return body.raw.content;
      case RequestBodyType.xWwwFormUrlEncoded:
        return body.urlEncoded
            .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
            .map((item) => '${item.key}=${item.value}')
            .join('&');
      case RequestBodyType.graphql:
        if (!body.graphQl.hasContent) {
          return '';
        }
        try {
          return jsonEncode({
            'query': body.graphQl.query,
            'variables': body.graphQl.variables.trim().isEmpty
                ? <String, String>{}
                : jsonDecode(body.graphQl.variables),
          });
        } on FormatException {
          return null;
        }
      case RequestBodyType.formData:
        return null;
    }
  }
}

String _generateNonce() {
  final random = Random.secure();
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final buffer = StringBuffer();

  for (var index = 0; index < 12; index++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }

  return buffer.toString();
}
