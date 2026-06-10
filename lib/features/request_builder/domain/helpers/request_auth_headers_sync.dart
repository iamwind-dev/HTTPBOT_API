import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import 'auth_headers_updater.dart';
import 'aws_auth_headers_builder.dart';
import 'aws_headers_updater.dart';

/// Synchronizes every auth-derived header row shown in the request editor.
List<KeyValueItem> syncRequestAuthHeaders({
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  required HttpMethod method,
  required String url,
  required RequestBodyDraft body,
  AwsAuthHeadersBuilder awsAuthHeadersBuilder = const AwsAuthHeadersBuilder(),
}) {
  final authorizationSyncedHeaders = syncAuthorizationHeaderWithAuth(
    headers: headers,
    auth: auth,
  );

  return syncAwsHeadersWithAuth(
    headers: authorizationSyncedHeaders,
    auth: auth,
    method: method,
    url: url,
    body: body,
    awsAuthHeadersBuilder: awsAuthHeadersBuilder,
  );
}
