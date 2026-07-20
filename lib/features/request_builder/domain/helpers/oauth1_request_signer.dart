import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import '../usecases/sync_request_query_parameters_use_case.dart';
import 'oauth1_percent_encoder.dart';

class OAuth1SigningResult {
  /// Carries the signed OAuth params or a stable validation error.
  const OAuth1SigningResult({
    required this.isValid,
    this.errorMessage,
    this.oauthParameters = const <String, String>{},
    this.authorizationHeader = '',
    this.authorizationHeaderPreview = '',
    this.signature = '',
    this.resolvedTimestamp = '',
    this.resolvedNonce = '',
  });

  final bool isValid;
  final String? errorMessage;
  final Map<String, String> oauthParameters;
  final String authorizationHeader;
  final String authorizationHeaderPreview;
  final String signature;
  final String resolvedTimestamp;
  final String resolvedNonce;
}

class OAuth1RequestSigner {
  OAuth1RequestSigner({
    DateTime Function()? now,
    String Function()? nonceGenerator,
  }) : _now = now ?? DateTime.now,
       _nonceGenerator = nonceGenerator ?? _generateNonce;

  final DateTime Function() _now;
  final String Function() _nonceGenerator;

  /// Signs the request pieces for OAuth 1.0a and returns either generated params or a validation error.
  OAuth1SigningResult sign({
    required HttpMethod method,
    required String url,
    required List<KeyValueItem> queryParameters,
    required RequestBodyDraft body,
    required OAuth1AuthDraft auth,
  }) {
    final consumerKey = auth.consumerKey.trim();
    if (consumerKey.isEmpty) {
      return const OAuth1SigningResult(
        isValid: false,
        errorMessage: 'Consumer Key is required for OAuth 1.0a.',
      );
    }

    if (auth.usesRsaSignature) {
      return const OAuth1SigningResult(
        isValid: false,
        errorMessage: 'RSA signature methods are not implemented yet.',
      );
    }

    if (auth.consumerSecret.isEmpty) {
      return const OAuth1SigningResult(
        isValid: false,
        errorMessage: 'Consumer Secret is required for OAuth 1.0a.',
      );
    }

    final normalizedBaseUrl = normalizeOAuth1BaseUrl(
      SyncRequestQueryParametersUseCase().extractBaseUrl(
        url: url,
        queryParameters: queryParameters,
      ),
    );
    final baseUrlWithEmbeddedQuery = SyncRequestQueryParametersUseCase()
        .extractBaseUrl(url: url, queryParameters: queryParameters);
    if (normalizedBaseUrl.isEmpty) {
      return const OAuth1SigningResult(
        isValid: false,
        errorMessage: 'Could not build OAuth 1.0a signature.',
      );
    }

    final timestamp = auth.timestamp.trim().isNotEmpty
        ? auth.timestamp.trim()
        : (_now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = auth.nonce.trim().isNotEmpty
        ? auth.nonce.trim()
        : _nonceGenerator();
    final oauthParameters = _buildOAuthParameters(
      auth: auth,
      timestamp: timestamp,
      nonce: nonce,
      body: body,
    );
    final signingParameters = <MapEntry<String, String>>[
      ..._collectUrlQueryParameters(
        baseUrlWithEmbeddedQuery,
        includeEmptyParameters: auth.includeEmptyParameters,
      ),
      ..._collectQueryParameters(
        queryParameters,
        includeEmptyParameters: auth.includeEmptyParameters,
      ),
      ..._collectOAuthParametersForSignature(
        oauthParameters,
        includeEmptyParameters: auth.includeEmptyParameters,
      ),
      ..._collectUrlEncodedBodyParameters(
        body,
        includeEmptyParameters: auth.includeEmptyParameters,
      ),
    ];
    final normalizedParameters = _normalizeParameters(signingParameters);
    final baseString =
        '${method.wireName.toUpperCase()}&'
        '${oauth1PercentEncode(normalizedBaseUrl)}&'
        '${oauth1PercentEncode(normalizedParameters)}';
    final signature = _buildSignature(auth: auth, baseString: baseString);
    if (signature == null) {
      return const OAuth1SigningResult(
        isValid: false,
        errorMessage: 'Could not build OAuth 1.0a signature.',
      );
    }

    final signedParameters = Map<String, String>.from(oauthParameters)
      ..['oauth_signature'] = signature;
    final authorizationHeader = auth.asHeader
        ? _buildAuthorizationHeader(
            signedParameters,
            realm: auth.realm,
            encodeSignature: auth.encodeSignature,
          )
        : '';

    return OAuth1SigningResult(
      isValid: true,
      oauthParameters: signedParameters,
      authorizationHeader: authorizationHeader,
      authorizationHeaderPreview: authorizationHeader.isEmpty
          ? ''
          : _buildHeaderPreview(authorizationHeader),
      signature: signature,
      resolvedTimestamp: timestamp,
      resolvedNonce: nonce,
    );
  }

  Map<String, String> _buildOAuthParameters({
    required OAuth1AuthDraft auth,
    required String timestamp,
    required String nonce,
    required RequestBodyDraft body,
  }) {
    final parameters = <String, String>{
      'oauth_consumer_key': auth.consumerKey.trim(),
      'oauth_signature_method': auth.signatureMethod.trim(),
      'oauth_timestamp': timestamp,
      'oauth_nonce': nonce,
      'oauth_version': auth.version.trim().isEmpty
          ? '1.0'
          : auth.version.trim(),
    };

    _addOptionalParameter(
      parameters,
      key: 'oauth_token',
      value: auth.token,
      includeEmptyParameters: auth.includeEmptyParameters,
    );
    _addOptionalParameter(
      parameters,
      key: 'oauth_verifier',
      value: auth.verifier,
      includeEmptyParameters: auth.includeEmptyParameters,
    );
    _addOptionalParameter(
      parameters,
      key: 'oauth_callback',
      value: auth.callback,
      includeEmptyParameters: auth.includeEmptyParameters,
    );

    if (auth.includeBodyHash &&
        auth.signatureMethod != 'PLAINTEXT' &&
        body.type != RequestBodyType.xWwwFormUrlEncoded) {
      parameters['oauth_body_hash'] = _buildBodyHash(
        body: body,
        signatureMethod: auth.signatureMethod,
      );
    }

    return parameters;
  }
}

/// Normalizes the request URL for OAuth 1.0a signing.
String normalizeOAuth1BaseUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
    return '';
  }

  final isDefaultPort =
      (uri.scheme.toLowerCase() == 'http' && uri.port == 80) ||
      (uri.scheme.toLowerCase() == 'https' && uri.port == 443);
  final portSegment = isDefaultPort ? '' : ':${uri.port}';
  final normalizedPath = uri.path.isEmpty ? '/' : uri.path;

  return '${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}$portSegment$normalizedPath';
}

List<MapEntry<String, String>> _collectQueryParameters(
  List<KeyValueItem> queryParameters, {
  required bool includeEmptyParameters,
}) {
  return queryParameters
      .where(
        (item) =>
            item.isEnabled &&
            item.key.trim().isNotEmpty &&
            !item.isSystemGeneratedOAuth1QueryParameter &&
            (includeEmptyParameters || item.value.isNotEmpty),
      )
      .map((item) => MapEntry(item.key, item.value))
      .toList(growable: false);
}

List<MapEntry<String, String>> _collectUrlQueryParameters(
  String url, {
  required bool includeEmptyParameters,
}) {
  final uri = Uri.tryParse(url.trim());
  final query = uri?.query ?? '';
  if (query.isEmpty) {
    return const <MapEntry<String, String>>[];
  }

  return query
      .split('&')
      .where((part) => part.isNotEmpty)
      .map((part) {
        final separatorIndex = part.indexOf('=');
        if (separatorIndex == -1) {
          return MapEntry(Uri.decodeQueryComponent(part), '');
        }

        return MapEntry(
          Uri.decodeQueryComponent(part.substring(0, separatorIndex)),
          Uri.decodeQueryComponent(part.substring(separatorIndex + 1)),
        );
      })
      .where(
        (entry) =>
            entry.key.trim().isNotEmpty &&
            (includeEmptyParameters || entry.value.isNotEmpty),
      )
      .toList(growable: false);
}

List<MapEntry<String, String>> _collectOAuthParametersForSignature(
  Map<String, String> parameters, {
  required bool includeEmptyParameters,
}) {
  return parameters.entries
      .where(
        (entry) =>
            entry.key != 'oauth_signature' &&
            (includeEmptyParameters || entry.value.isNotEmpty),
      )
      .map((entry) => MapEntry(entry.key, entry.value))
      .toList(growable: false);
}

List<MapEntry<String, String>> _collectUrlEncodedBodyParameters(
  RequestBodyDraft body, {
  required bool includeEmptyParameters,
}) {
  if (body.type != RequestBodyType.xWwwFormUrlEncoded) {
    return const <MapEntry<String, String>>[];
  }

  return body.urlEncoded
      .where(
        (item) =>
            item.isEnabled &&
            item.key.trim().isNotEmpty &&
            (includeEmptyParameters || item.value.isNotEmpty),
      )
      .map((item) => MapEntry(item.key, item.value))
      .toList(growable: false);
}

String _normalizeParameters(List<MapEntry<String, String>> parameters) {
  final encoded =
      parameters
          .map(
            (entry) => (
              key: oauth1PercentEncode(entry.key),
              value: oauth1PercentEncode(entry.value),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) {
          final keyComparison = left.key.compareTo(right.key);
          if (keyComparison != 0) {
            return keyComparison;
          }

          return left.value.compareTo(right.value);
        });

  return encoded.map((entry) => '${entry.key}=${entry.value}').join('&');
}

String? _buildSignature({
  required OAuth1AuthDraft auth,
  required String baseString,
}) {
  final method = auth.signatureMethod.trim();
  if (method == 'PLAINTEXT') {
    return '${oauth1PercentEncode(auth.consumerSecret)}&${oauth1PercentEncode(auth.tokenSecret)}';
  }

  final signingKey =
      '${oauth1PercentEncode(auth.consumerSecret)}&${oauth1PercentEncode(auth.tokenSecret)}';
  final keyBytes = utf8.encode(signingKey);
  final messageBytes = utf8.encode(baseString);

  final digestBytes = switch (method) {
    'HMAC-SHA1' => Hmac(sha1, keyBytes).convert(messageBytes).bytes,
    'HMAC-SHA256' => Hmac(sha256, keyBytes).convert(messageBytes).bytes,
    'HMAC-SHA512' => Hmac(sha512, keyBytes).convert(messageBytes).bytes,
    _ => null,
  };

  if (digestBytes == null) {
    return null;
  }

  return base64Encode(digestBytes);
}

void _addOptionalParameter(
  Map<String, String> parameters, {
  required String key,
  required String value,
  required bool includeEmptyParameters,
}) {
  final trimmedValue = value.trim();
  if (trimmedValue.isEmpty && !includeEmptyParameters) {
    return;
  }

  parameters[key] = trimmedValue;
}

String _buildBodyHash({
  required RequestBodyDraft body,
  required String signatureMethod,
}) {
  final bytes = utf8.encode(_extractBodyText(body));
  final digestBytes = switch (signatureMethod) {
    'HMAC-SHA1' => sha1.convert(bytes).bytes,
    'HMAC-SHA256' => sha256.convert(bytes).bytes,
    'HMAC-SHA512' => sha512.convert(bytes).bytes,
    _ => sha1.convert(bytes).bytes,
  };

  return base64Encode(digestBytes);
}

String _extractBodyText(RequestBodyDraft body) => switch (body.type) {
  RequestBodyType.none => '',
  RequestBodyType.raw => body.raw.content,
  RequestBodyType.graphql =>
    body.graphQl.query.trim().isEmpty &&
            body.graphQl.variables.trim().isEmpty &&
            (body.graphQl.operationName?.trim().isEmpty ?? true)
        ? ''
        : jsonEncode({
            'query': body.graphQl.query,
            if (body.graphQl.variables.trim().isNotEmpty)
              'variables': jsonDecode(body.graphQl.variables),
            if (body.graphQl.operationName?.trim().isNotEmpty ?? false)
              'operationName': body.graphQl.operationName!.trim(),
          }),
  RequestBodyType.xWwwFormUrlEncoded =>
    body.urlEncoded
        .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
        .map((item) => '${item.key}=${item.value}')
        .join('&'),
  RequestBodyType.formData =>
    body.formData
        .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
        .map((item) => '${item.key}=${item.value}')
        .join('&'),
};

String _buildAuthorizationHeader(
  Map<String, String> oauthParameters, {
  required String realm,
  required bool encodeSignature,
}) {
  final headerSegments = <String>[];
  final trimmedRealm = realm.trim();
  if (trimmedRealm.isNotEmpty) {
    headerSegments.add('realm="${oauth1PercentEncode(trimmedRealm)}"');
  }

  final entries = oauthParameters.entries.toList(growable: false)
    ..sort((left, right) => left.key.compareTo(right.key));

  for (final entry in entries) {
    final encodedValue = entry.key == 'oauth_signature' && !encodeSignature
        ? entry.value
        : oauth1PercentEncode(entry.value);
    headerSegments.add('${entry.key}="$encodedValue"');
  }

  return 'OAuth ${headerSegments.join(', ')}';
}

String _buildHeaderPreview(String authorizationHeader) {
  if (authorizationHeader.length <= 96) {
    return authorizationHeader;
  }

  return '${authorizationHeader.substring(0, 96)}...';
}

String _generateNonce() {
  final random = Random.secure();
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final buffer = StringBuffer();

  for (var index = 0; index < 24; index++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }

  return buffer.toString();
}
