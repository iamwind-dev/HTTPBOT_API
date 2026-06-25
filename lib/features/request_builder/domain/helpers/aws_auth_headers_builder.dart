import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';

class AwsAuthHeadersBuilder {
  const AwsAuthHeadersBuilder({DateTime Function()? now})
    : _now = now ?? _systemNow;

  final DateTime Function() _now;

  /// Builds AWS SigV4 headers using user-owned overrides where present.
  ///
  /// With a valid URL but incomplete credentials, the derivable headers
  /// (Host, X-Amz-Date, X-Amz-Content-Sha256, X-Amz-Security-Token) are still
  /// returned so the editor fills immediately; Authorization is only added
  /// once every signing field is present, never with a stale signature.
  List<KeyValueItem>? build({
    required List<KeyValueItem> headers,
    required RequestAuthDraft auth,
    required HttpMethod method,
    required String url,
    required RequestBodyDraft body,
  }) {
    if (auth.type != AuthType.awsSignature) {
      return null;
    }

    final accessKey = auth.aws.accessKey.trim();
    final secretKey = auth.aws.secretKey.trim();
    final region = auth.aws.region.trim();
    final service = auth.aws.service.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return null;
    }

    final hasCompleteCredentials =
        accessKey.isNotEmpty &&
        secretKey.isNotEmpty &&
        region.isNotEmpty &&
        service.isNotEmpty;
    final currentTime = _now().toUtc();
    final host =
        _userDefinedHeaderValue(headers, 'host') ?? _hostHeaderValue(uri);
    final amzDate =
        _userDefinedHeaderValue(headers, 'x-amz-date') ??
        _formatAmzDate(currentTime);
    final payloadHash =
        _userDefinedHeaderValue(headers, 'x-amz-content-sha256') ??
        _sha256Hex(_signableBodyText(body));
    final sessionToken =
        _userDefinedHeaderValue(headers, 'x-amz-security-token') ??
        auth.aws.sessionToken.trim();
    String? authorizationValue;
    if (hasCompleteCredentials) {
      final canonicalHeaders = <String, String>{
        'host': host.trim(),
        'x-amz-content-sha256': payloadHash.trim(),
        'x-amz-date': amzDate.trim(),
        if (sessionToken.trim().isNotEmpty)
          'x-amz-security-token': sessionToken.trim(),
      };
      final signedHeaderNames = canonicalHeaders.keys.toList(growable: false)
        ..sort();
      final canonicalHeadersText = signedHeaderNames
          .map((key) => '$key:${canonicalHeaders[key]!.trim()}\n')
          .join();
      final canonicalRequest = [
        method.wireName,
        _canonicalUri(uri),
        _canonicalQueryString(uri),
        canonicalHeadersText,
        signedHeaderNames.join(';'),
        payloadHash,
      ].join('\n');
      final dateStamp = _dateStampFromAmzDate(
        amzDate,
        fallback: _formatDateStamp(currentTime),
      );
      final credentialScope = '$dateStamp/$region/$service/aws4_request';
      final stringToSign = [
        'AWS4-HMAC-SHA256',
        amzDate,
        credentialScope,
        _sha256Hex(canonicalRequest),
      ].join('\n');
      final signingKey = _deriveSigningKey(
        secretKey: secretKey,
        dateStamp: dateStamp,
        region: region,
        service: service,
      );
      final signature = Hmac(
        sha256,
        signingKey,
      ).convert(utf8.encode(stringToSign)).toString();
      authorizationValue =
          'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
          'SignedHeaders=${signedHeaderNames.join(';')}, Signature=$signature';
    }

    return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      KeyValueItem(
        key: 'Host',
        value: host,
        description: awsSystemGeneratedHeaderDescription,
      ),
      KeyValueItem(
        key: 'X-Amz-Date',
        value: amzDate,
        description: awsSystemGeneratedHeaderDescription,
      ),
      KeyValueItem(
        key: 'X-Amz-Content-Sha256',
        value: payloadHash,
        description: awsSystemGeneratedHeaderDescription,
      ),
      if (sessionToken.trim().isNotEmpty)
        KeyValueItem(
          key: 'X-Amz-Security-Token',
          value: sessionToken.trim(),
          description: awsSystemGeneratedHeaderDescription,
        ),
      if (authorizationValue != null)
        KeyValueItem(
          key: 'Authorization',
          value: authorizationValue,
          description: awsSystemGeneratedHeaderDescription,
        ),
    ]);
  }

  /// Returns the current UTC time for runtime signing.
  static DateTime _systemNow() => DateTime.now().toUtc();

  /// Returns the user-owned value for a header key when present.
  String? _userDefinedHeaderValue(List<KeyValueItem> headers, String key) {
    for (final header in headers) {
      if (header.key.trim().toLowerCase() == key &&
          !header.isAnySystemGeneratedHeader) {
        return header.value;
      }
    }

    return null;
  }

  /// Returns the host header value for a URI, including non-default ports.
  String _hostHeaderValue(Uri uri) {
    final isDefaultPort =
        !uri.hasPort ||
        (uri.scheme == 'https' && uri.port == 443) ||
        (uri.scheme == 'http' && uri.port == 80);

    if (isDefaultPort) {
      return uri.host;
    }

    return '${uri.host}:${uri.port}';
  }

  /// Returns the AWS timestamp string in basic UTC format.
  String _formatAmzDate(DateTime time) =>
      '${_formatDateStamp(time)}T'
      '${time.hour.toString().padLeft(2, '0')}'
      '${time.minute.toString().padLeft(2, '0')}'
      '${time.second.toString().padLeft(2, '0')}Z';

  /// Returns the AWS date stamp used in the credential scope.
  String _formatDateStamp(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}'
      '${time.month.toString().padLeft(2, '0')}'
      '${time.day.toString().padLeft(2, '0')}';

  /// Returns the leading date stamp from x-amz-date when it looks usable.
  String _dateStampFromAmzDate(String amzDate, {required String fallback}) {
    final trimmed = amzDate.trim();
    if (RegExp(r'^\d{8}T\d{6}Z$').hasMatch(trimmed)) {
      return trimmed.substring(0, 8);
    }

    return fallback;
  }

  /// Returns the canonical URI path for AWS SigV4 signing.
  String _canonicalUri(Uri uri) {
    if (uri.path.isEmpty || uri.path == '/') {
      return '/';
    }

    final encodedSegments = uri.pathSegments.map(_awsUriEncode).join('/');
    return uri.path.startsWith('/') ? '/$encodedSegments' : encodedSegments;
  }

  /// Returns the canonical query string sorted by encoded key then encoded value.
  String _canonicalQueryString(Uri uri) {
    final parts = <MapEntry<String, String>>[];

    uri.queryParametersAll.forEach((key, values) {
      if (values.isEmpty) {
        parts.add(MapEntry(_awsUriEncode(key), ''));
        return;
      }

      for (final value in values) {
        parts.add(MapEntry(_awsUriEncode(key), _awsUriEncode(value)));
      }
    });

    parts.sort((left, right) {
      final keyComparison = left.key.compareTo(right.key);
      if (keyComparison != 0) {
        return keyComparison;
      }

      return left.value.compareTo(right.value);
    });

    return parts.map((entry) => '${entry.key}=${entry.value}').join('&');
  }

  /// Returns an RFC3986-encoded component for AWS canonical requests.
  String _awsUriEncode(String value) => Uri.encodeQueryComponent(
    value,
  ).replaceAll('+', '%20').replaceAll('*', '%2A').replaceAll('%7E', '~');

  /// Returns the deterministic body text used for request signing.
  String _signableBodyText(RequestBodyDraft body) {
    return switch (body.type) {
      RequestBodyType.none => '',
      RequestBodyType.raw => body.raw.content,
      RequestBodyType.graphql => jsonEncode(<String, Object?>{
        'query': body.graphQl.query,
        if (body.graphQl.variables.trim().isNotEmpty)
          'variables': _graphQlVariablesForSigning(body.graphQl.variables),
        if (body.graphQl.operationName?.trim().isNotEmpty ?? false)
          'operationName': body.graphQl.operationName!.trim(),
      }),
      RequestBodyType.xWwwFormUrlEncoded =>
        body.urlEncoded
            .where((item) => item.isEnabled && item.hasKey)
            .map(
              (item) =>
                  '${Uri.encodeQueryComponent(item.key)}=${Uri.encodeQueryComponent(item.value)}',
            )
            .join('&'),
      RequestBodyType.formData =>
        body.formData
            .where((item) => item.isEnabled && item.hasKey)
            .map((item) => '${item.key}=${item.value}|${item.type.name}')
            .join('&'),
    };
  }

  /// Returns GraphQL variables in a signable stable structure without throwing.
  Object _graphQlVariablesForSigning(String variables) {
    final trimmed = variables.trim();
    if (trimmed.isEmpty) {
      return <String, Object?>{};
    }

    try {
      return jsonDecode(trimmed);
    } on FormatException {
      return trimmed;
    }
  }

  /// Returns the lowercase SHA-256 hash for a UTF-8 string payload.
  String _sha256Hex(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  /// Derives the AWS SigV4 signing key from the secret and request scope.
  List<int> _deriveSigningKey({
    required String secretKey,
    required String dateStamp,
    required String region,
    required String service,
  }) {
    final dateKey = _hmacSha256(
      utf8.encode('AWS4$secretKey'),
      utf8.encode(dateStamp),
    );
    final regionKey = _hmacSha256(dateKey, utf8.encode(region));
    final serviceKey = _hmacSha256(regionKey, utf8.encode(service));
    return _hmacSha256(serviceKey, utf8.encode('aws4_request'));
  }

  /// Returns the raw HMAC-SHA256 bytes for the provided key and payload.
  List<int> _hmacSha256(List<int> key, List<int> value) =>
      Hmac(sha256, key).convert(value).bytes;
}
