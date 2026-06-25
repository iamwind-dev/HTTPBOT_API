import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import 'hawk_authorization_header_builder.dart';

class HawkAuthSyncResult {
  const HawkAuthSyncResult({required this.headers, this.errorMessage});

  final List<KeyValueItem> headers;
  final String? errorMessage;
}

/// Synchronizes Hawk auth with the editor-managed Authorization header row.
HawkAuthSyncResult syncHawkAuthToRequestFields({
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  required HttpMethod method,
  required String url,
  required RequestBodyDraft body,
  HawkAuthorizationHeaderBuilder? builder,
}) {
  final sanitizedHeaders = headers
      .where((item) => !item.isSystemGeneratedHawkHeader)
      .toList(growable: false);

  if (auth.type != AuthType.hawk) {
    return HawkAuthSyncResult(
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  final hasUserDefinedAuthorization = sanitizedHeaders.any(
    (item) =>
        item.isEnabled &&
        item.key.trim().toLowerCase() == 'authorization' &&
        !item.isSystemGeneratedAuthorizationHeader,
  );
  if (hasUserDefinedAuthorization) {
    return HawkAuthSyncResult(
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
      errorMessage: 'Authorization header already exists as user-defined.',
    );
  }

  final signingResult = (builder ?? HawkAuthorizationHeaderBuilder()).build(
    method: method,
    url: url,
    body: body,
    hawk: auth.hawk,
  );
  if (!signingResult.isValid) {
    return HawkAuthSyncResult(
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
      errorMessage: signingResult.errorMessage,
    );
  }

  return HawkAuthSyncResult(
    headers: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      ...sanitizedHeaders,
      KeyValueItem(
        key: 'Authorization',
        value: signingResult.authorizationHeader,
        description: hawkSystemGeneratedHeaderDescription,
      ),
    ]),
  );
}
