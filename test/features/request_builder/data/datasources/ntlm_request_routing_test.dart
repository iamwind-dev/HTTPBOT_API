import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/core/network/dio_client.dart';
import 'package:httpbot_api/core/network/ntlm_http_client.dart';
import 'package:httpbot_api/features/request_builder/data/repositories/request_execution_repository_impl.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/auth_applied_request.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_auth_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_execution_result.dart';

class _SpyNtlmHttpClient extends NtlmHttpClient {
  _SpyNtlmHttpClient();

  bool called = false;

  @override
  Future<RequestExecutionResult> execute(AuthAppliedRequest request) async {
    called = true;
    return RequestExecutionResult(request: request.request, statusCode: 200);
  }
}

AuthAppliedRequest _request(AuthType type, {String url = 'https://example.com'}) =>
    AuthAppliedRequest(
      request: RequestDraft(url: url, auth: RequestAuthDraft(type: type)),
      appliedAuthType: type,
    );

void main() {
  test('NTLM requests are delegated to NtlmHttpClient', () async {
    final spy = _SpyNtlmHttpClient();
    final repo =
        RequestExecutionRepositoryImpl(const DioClient(), ntlmHttpClient: spy);

    final result = await repo.executeRequest(_request(AuthType.ntlm));

    expect(spy.called, isTrue);
    expect(result.statusCode, 200);
  });

  test('non-NTLM requests are not delegated to NtlmHttpClient', () async {
    final spy = _SpyNtlmHttpClient();
    final repo =
        RequestExecutionRepositoryImpl(const DioClient(), ntlmHttpClient: spy);

    // Unroutable port — the Dio path fails fast without a real network call.
    await repo.executeRequest(
      _request(AuthType.none, url: 'http://127.0.0.1:1'),
    );

    expect(spy.called, isFalse);
  });
}
