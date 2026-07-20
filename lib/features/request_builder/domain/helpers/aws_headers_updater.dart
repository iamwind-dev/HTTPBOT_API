import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import 'aws_auth_headers_builder.dart';

class AwsAuthSyncedFields {
  const AwsAuthSyncedFields({
    required this.queryParameters,
    required this.headers,
  });

  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
}

/// Synchronizes AWS SigV4 headers while preserving user-owned header rows.
List<KeyValueItem> syncAwsHeadersWithAuth({
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  required HttpMethod method,
  required String url,
  required RequestBodyDraft body,
  AwsAuthHeadersBuilder awsAuthHeadersBuilder = const AwsAuthHeadersBuilder(),
}) {
  return syncAwsAuthToRequestFields(
    queryParameters: const <KeyValueItem>[],
    headers: headers,
    auth: auth,
    method: method,
    url: url,
    body: body,
    awsAuthHeadersBuilder: awsAuthHeadersBuilder,
  ).headers;
}

/// Synchronizes AWS SigV4 headers or query params while preserving user rows.
AwsAuthSyncedFields syncAwsAuthToRequestFields({
  required List<KeyValueItem> queryParameters,
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  required HttpMethod method,
  required String url,
  required RequestBodyDraft body,
  AwsAuthHeadersBuilder awsAuthHeadersBuilder = const AwsAuthHeadersBuilder(),
  AwsSigningContext? signingContext,
}) {
  final headersWithoutSystemAws = headers
      .where((header) => !header.isSystemGeneratedAwsHeader)
      .toList(growable: false);
  final queryWithoutSystemAws = queryParameters
      .where((parameter) => !parameter.isSystemGeneratedAwsQueryParameter)
      .toList(growable: false);
  if (auth.type != AuthType.awsSignature) {
    return AwsAuthSyncedFields(
      queryParameters: List<KeyValueItem>.unmodifiable(queryWithoutSystemAws),
      headers: List<KeyValueItem>.unmodifiable(headersWithoutSystemAws),
    );
  }

  final generated = awsAuthHeadersBuilder.buildRequestFields(
    queryParameters: queryWithoutSystemAws,
    headers: headersWithoutSystemAws,
    auth: auth,
    method: method,
    url: url,
    body: body,
    signingContext: signingContext,
  );
  final nextHeaders = <KeyValueItem>[...headersWithoutSystemAws];
  for (final generatedHeader in generated.headers) {
    if (_hasUserDefinedHeader(headersWithoutSystemAws, generatedHeader.key)) {
      continue;
    }

    nextHeaders.add(generatedHeader);
  }

  final nextQueryParameters = <KeyValueItem>[...queryWithoutSystemAws];
  for (final generatedParameter in generated.queryParameters) {
    if (_hasUserDefinedQueryParameter(
      queryWithoutSystemAws,
      generatedParameter.key,
    )) {
      continue;
    }

    nextQueryParameters.add(generatedParameter);
  }

  return AwsAuthSyncedFields(
    queryParameters: List<KeyValueItem>.unmodifiable(nextQueryParameters),
    headers: List<KeyValueItem>.unmodifiable(nextHeaders),
  );
}

/// Returns true when a user-managed row already owns the provided header key.
bool _hasUserDefinedHeader(List<KeyValueItem> headers, String key) {
  final normalizedKey = key.trim().toLowerCase();

  return headers.any(
    (header) =>
        header.key.trim().toLowerCase() == normalizedKey &&
        header.isComplete &&
        !header.isAnySystemGeneratedHeader,
  );
}

/// Returns true when a user-managed row already owns the provided query key.
bool _hasUserDefinedQueryParameter(List<KeyValueItem> parameters, String key) {
  final normalizedKey = key.trim().toLowerCase();

  return parameters.any(
    (parameter) =>
        parameter.key.trim().toLowerCase() == normalizedKey &&
        parameter.isComplete &&
        !parameter.isSystemGeneratedAwsQueryParameter,
  );
}
