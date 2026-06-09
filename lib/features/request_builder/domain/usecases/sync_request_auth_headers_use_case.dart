import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import '../helpers/aws_auth_headers_builder.dart';
import '../helpers/request_auth_headers_sync.dart';

class SyncRequestAuthHeadersUseCase {
  const SyncRequestAuthHeadersUseCase({
    AwsAuthHeadersBuilder awsAuthHeadersBuilder = const AwsAuthHeadersBuilder(),
  }) : _awsAuthHeadersBuilder = awsAuthHeadersBuilder;

  final AwsAuthHeadersBuilder _awsAuthHeadersBuilder;

  /// Synchronizes editor headers with the currently selected auth mode.
  List<KeyValueItem> call({
    required List<KeyValueItem> headers,
    required RequestAuthDraft auth,
    required HttpMethod method,
    required String url,
    required RequestBodyDraft body,
  }) => syncRequestAuthHeaders(
    headers: headers,
    auth: auth,
    method: method,
    url: url,
    body: body,
    awsAuthHeadersBuilder: _awsAuthHeadersBuilder,
  );
}
