import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import 'aws_auth_headers_builder.dart';

/// Synchronizes AWS SigV4 headers while preserving user-owned header rows.
List<KeyValueItem> syncAwsHeadersWithAuth({
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  required HttpMethod method,
  required String url,
  required RequestBodyDraft body,
  AwsAuthHeadersBuilder awsAuthHeadersBuilder = const AwsAuthHeadersBuilder(),
}) {
  final headersWithoutSystemAws = headers
      .where((header) => !header.isSystemGeneratedAwsHeader)
      .toList(growable: false);
  if (auth.type != AuthType.awsSignature) {
    return List<KeyValueItem>.unmodifiable(headersWithoutSystemAws);
  }

  final generatedHeaders = awsAuthHeadersBuilder.build(
    headers: headersWithoutSystemAws,
    auth: auth,
    method: method,
    url: url,
    body: body,
  );
  if (generatedHeaders == null) {
    return List<KeyValueItem>.unmodifiable(headersWithoutSystemAws);
  }

  final nextHeaders = <KeyValueItem>[...headersWithoutSystemAws];
  for (final generatedHeader in generatedHeaders) {
    if (_hasUserDefinedHeader(headersWithoutSystemAws, generatedHeader.key)) {
      continue;
    }

    nextHeaders.add(generatedHeader);
  }

  return List<KeyValueItem>.unmodifiable(nextHeaders);
}

/// Returns true when a user-managed row already owns the provided header key.
bool _hasUserDefinedHeader(List<KeyValueItem> headers, String key) {
  final normalizedKey = key.trim().toLowerCase();

  return headers.any(
    (header) =>
        header.key.trim().toLowerCase() == normalizedKey &&
        !header.isAnySystemGeneratedHeader,
  );
}
