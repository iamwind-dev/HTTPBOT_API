import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';

class AwsAuthRequestFieldsResult {
  const AwsAuthRequestFieldsResult({
    this.headers = const <KeyValueItem>[],
    this.queryParameters = const <KeyValueItem>[],
  });

  final List<KeyValueItem> headers;
  final List<KeyValueItem> queryParameters;
}

class AwsSigningContext {
  /// Creates one immutable AWS timestamp bundle for a signing attempt.
  AwsSigningContext(DateTime timestamp)
    : timestampUtc = timestamp.toUtc(),
      amzDate = AwsAuthHeadersBuilder._formatAmzDate(timestamp.toUtc()),
      dateStamp = AwsAuthHeadersBuilder._formatDateStamp(timestamp.toUtc());

  final DateTime timestampUtc;
  final String amzDate;
  final String dateStamp;
}

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
    final result = buildRequestFields(
      queryParameters: const <KeyValueItem>[],
      headers: headers,
      auth: auth.copyWith(aws: auth.aws.copyWith(asHeader: true)),
      method: method,
      url: url,
      body: body,
    );
    if (auth.type != AuthType.awsSignature) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return null;
    }

    return result.headers;
  }

  /// Builds AWS-owned header or query rows for the selected signing location.
  AwsAuthRequestFieldsResult buildRequestFields({
    required List<KeyValueItem> queryParameters,
    required List<KeyValueItem> headers,
    required RequestAuthDraft auth,
    required HttpMethod method,
    required String url,
    required RequestBodyDraft body,
    AwsSigningContext? signingContext,
  }) {
    if (auth.type != AuthType.awsSignature) {
      return const AwsAuthRequestFieldsResult();
    }

    final accessKey = auth.aws.accessKey.trim();
    final secretKey = auth.aws.secretKey;
    final region = auth.aws.region.trim();
    final service = auth.aws.service.trim();
    final uri = _uriWithQueryRows(Uri.tryParse(url), queryParameters);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return const AwsAuthRequestFieldsResult();
    }

    final hasCompleteCredentials =
        accessKey.isNotEmpty &&
        secretKey.isNotEmpty &&
        region.isNotEmpty &&
        service.isNotEmpty;
    if (!hasCompleteCredentials) {
      return const AwsAuthRequestFieldsResult();
    }

    final context = signingContext ?? AwsSigningContext(_now());
    if (auth.aws.asHeader) {
      return AwsAuthRequestFieldsResult(
        headers: _buildHeaderRows(
          headers: headers,
          auth: auth,
          method: method,
          uri: uri,
          body: body,
          context: context,
          accessKey: accessKey,
          secretKey: secretKey,
          region: region,
          service: service,
        ),
      );
    }

    return AwsAuthRequestFieldsResult(
      queryParameters: _buildQueryRows(
        queryParameters: queryParameters,
        headers: headers,
        auth: auth,
        method: method,
        uri: uri,
        body: body,
        context: context,
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        service: service,
      ),
    );
  }

  /// Returns the current UTC time for runtime signing.
  static DateTime _systemNow() => DateTime.now().toUtc();

  /// Returns the user-owned value for a header key when present.
  String? _userDefinedHeaderValue(List<KeyValueItem> headers, String key) {
    for (final header in headers) {
      if (header.key.trim().toLowerCase() == key &&
          header.isComplete &&
          !header.isAnySystemGeneratedHeader) {
        return header.value;
      }
    }

    return null;
  }

  /// Builds generated rows for AWS header-mode signing.
  List<KeyValueItem> _buildHeaderRows({
    required List<KeyValueItem> headers,
    required RequestAuthDraft auth,
    required HttpMethod method,
    required Uri uri,
    required RequestBodyDraft body,
    required AwsSigningContext context,
    required String accessKey,
    required String secretKey,
    required String region,
    required String service,
  }) {
    final host =
        _userDefinedHeaderValue(headers, 'host') ?? _hostHeaderValue(uri);
    final amzDate =
        _userDefinedHeaderValue(headers, 'x-amz-date') ?? context.amzDate;
    final payloadHash =
        _userDefinedHeaderValue(headers, 'x-amz-content-sha256') ??
        _sha256Hex(_signableBodyText(body));
    final sessionToken =
        _userDefinedHeaderValue(headers, 'x-amz-security-token') ??
        auth.aws.sessionToken.trim();
    final canonicalHeaders = <String, String>{
      'host': host.trim(),
      'x-amz-content-sha256': payloadHash.trim(),
      'x-amz-date': amzDate.trim(),
      if (sessionToken.trim().isNotEmpty)
        'x-amz-security-token': sessionToken.trim(),
    };
    final signedHeaderNames = _sortedHeaderNames(canonicalHeaders);
    final signature = _signature(
      method: method,
      uri: uri,
      canonicalHeaders: canonicalHeaders,
      signedHeaderNames: signedHeaderNames,
      payloadHash: payloadHash,
      amzDate: amzDate,
      dateStamp: _dateStampFromAmzDate(amzDate, fallback: context.dateStamp),
      secretKey: secretKey,
      region: region,
      service: service,
    );

    return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      _awsRow('Host', host),
      _awsRow('X-Amz-Date', amzDate),
      _awsRow('X-Amz-Content-Sha256', payloadHash),
      if (sessionToken.trim().isNotEmpty)
        _awsRow('X-Amz-Security-Token', sessionToken.trim()),
      _awsRow(
        'Authorization',
        'AWS4-HMAC-SHA256 Credential=$accessKey/${signature.credentialScope}, '
            'SignedHeaders=${signedHeaderNames.join(';')}, '
            'Signature=${signature.value}',
      ),
    ]);
  }

  /// Builds generated rows for AWS presigned-query signing.
  List<KeyValueItem> _buildQueryRows({
    required List<KeyValueItem> queryParameters,
    required List<KeyValueItem> headers,
    required RequestAuthDraft auth,
    required HttpMethod method,
    required Uri uri,
    required RequestBodyDraft body,
    required AwsSigningContext context,
    required String accessKey,
    required String secretKey,
    required String region,
    required String service,
  }) {
    final host =
        _userDefinedHeaderValue(headers, 'host') ?? _hostHeaderValue(uri);
    final payloadHash = _sha256Hex(_signableBodyText(body));
    final canonicalHeaders = <String, String>{'host': host.trim()};
    final signedHeaderNames = _sortedHeaderNames(canonicalHeaders);
    final credentialScope =
        '${context.dateStamp}/$region/$service/aws4_request';
    final baseRows = <KeyValueItem>[
      _awsRow('X-Amz-Algorithm', 'AWS4-HMAC-SHA256'),
      _awsRow('X-Amz-Credential', '$accessKey/$credentialScope'),
      _awsRow('X-Amz-Date', context.amzDate),
      _awsRow('X-Amz-Expires', '900'),
      _awsRow('X-Amz-SignedHeaders', signedHeaderNames.join(';')),
      if (auth.aws.sessionToken.trim().isNotEmpty)
        _awsRow('X-Amz-Security-Token', auth.aws.sessionToken.trim()),
    ];
    final signingUri = _uriWithQueryRows(uri, baseRows)!;
    final signature = _signature(
      method: method,
      uri: signingUri,
      canonicalHeaders: canonicalHeaders,
      signedHeaderNames: signedHeaderNames,
      payloadHash: payloadHash,
      amzDate: context.amzDate,
      dateStamp: context.dateStamp,
      secretKey: secretKey,
      region: region,
      service: service,
    );
    final hasUserSignature = queryParameters.any(
      (item) =>
          item.isComplete &&
          item.key.trim().toLowerCase() == 'x-amz-signature' &&
          !item.isSystemGeneratedAwsQueryParameter,
    );

    return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      ...baseRows,
      if (!hasUserSignature) _awsRow('X-Amz-Signature', signature.value),
    ]);
  }

  /// Creates one generated AWS row with stable metadata.
  KeyValueItem _awsRow(String key, String value) => KeyValueItem(
    key: key,
    value: value,
    description: awsSystemGeneratedHeaderDescription,
    source: RequestHeaderSource.systemAws,
    systemTag: 'awsAuth',
  );

  /// Returns the URI plus complete query rows without collapsing duplicates.
  Uri? _uriWithQueryRows(Uri? uri, List<KeyValueItem> rows) {
    if (uri == null) {
      return null;
    }
    final query = rows
        .where((item) => item.isComplete)
        .map(
          (item) =>
              '${Uri.encodeQueryComponent(item.key)}='
              '${Uri.encodeQueryComponent(item.value)}',
        )
        .toList(growable: false);
    if (query.isEmpty) {
      return uri;
    }

    return uri.replace(
      query: <String>[if (uri.query.isNotEmpty) uri.query, ...query].join('&'),
    );
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
  static String _formatAmzDate(DateTime time) =>
      '${_formatDateStamp(time)}T'
      '${time.hour.toString().padLeft(2, '0')}'
      '${time.minute.toString().padLeft(2, '0')}'
      '${time.second.toString().padLeft(2, '0')}Z';

  /// Returns the AWS date stamp used in the credential scope.
  static String _formatDateStamp(DateTime time) =>
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

  /// Returns sorted signed header names from the canonical header map.
  List<String> _sortedHeaderNames(Map<String, String> canonicalHeaders) =>
      canonicalHeaders.keys.toList(growable: false)..sort();

  /// Builds the final SigV4 signature and credential scope.
  _AwsSignature _signature({
    required HttpMethod method,
    required Uri uri,
    required Map<String, String> canonicalHeaders,
    required List<String> signedHeaderNames,
    required String payloadHash,
    required String amzDate,
    required String dateStamp,
    required String secretKey,
    required String region,
    required String service,
  }) {
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
    final value = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();

    return _AwsSignature(value: value, credentialScope: credentialScope);
  }

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

class _AwsSignature {
  const _AwsSignature({required this.value, required this.credentialScope});

  final String value;
  final String credentialScope;
}
