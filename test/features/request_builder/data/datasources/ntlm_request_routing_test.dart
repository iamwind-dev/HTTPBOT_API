import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/core/network/dio_client.dart';
import 'package:httpbot_api/core/network/ntlm_http_client.dart';
import 'package:httpbot_api/features/request_builder/data/repositories/request_execution_repository_impl.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/auth_applied_request.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/http_cookie_entity.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_auth_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_execution_result.dart';
import 'package:httpbot_api/features/request_builder/domain/repositories/http_cookie_repository.dart';

class _SpyNtlmHttpClient extends NtlmHttpClient {
  _SpyNtlmHttpClient();

  bool called = false;

  @override
  Future<RequestExecutionResult> execute(AuthAppliedRequest request) async {
    called = true;
    return RequestExecutionResult(request: request.request, statusCode: 200);
  }
}

class _NoopHttpCookieRepository implements HttpCookieRepository {
  @override
  Future<void> deleteCookie(String id) async {}

  @override
  Future<void> deleteExpiredCookies() async {}

  @override
  Future<List<HttpCookieEntity>> getAllCookies() async =>
      const <HttpCookieEntity>[];

  @override
  Future<List<HttpCookieEntity>> getCookiesForDomain(String domain) async =>
      const <HttpCookieEntity>[];

  @override
  Future<List<HttpCookieEntity>> getCookiesForRequestUrl(String url) async =>
      const <HttpCookieEntity>[];

  @override
  Future<void> saveCookie(HttpCookieEntity cookie) async {}

  @override
  Future<void> updateCookie(HttpCookieEntity cookie) async {}

  @override
  Future<void> upsertCookiesFromSetCookieHeaders(
    String requestUrl,
    List<String> setCookieHeaders,
  ) async {}
}

AuthAppliedRequest _request(
  AuthType type, {
  String url = 'https://example.com',
}) {
  final auth = type == AuthType.ntlm
      ? const RequestAuthDraft(
          type: AuthType.ntlm,
          ntlm: NtlmAuthDraft(username: 'user', password: 'pass'),
        )
      : RequestAuthDraft(type: type);

  return AuthAppliedRequest(
    request: RequestDraft(url: url, auth: auth),
    appliedAuthType: type,
  );
}

void main() {
  test('NTLM requests are delegated to NtlmHttpClient', () async {
    final spy = _SpyNtlmHttpClient();
    final repo = RequestExecutionRepositoryImpl(
      const DioClient(),
      httpCookieRepository: _NoopHttpCookieRepository(),
      ntlmHttpClient: spy,
    );

    final result = await repo.executeRequest(_request(AuthType.ntlm));

    expect(spy.called, isTrue);
    expect(result.statusCode, 200);
  });

  test(
    'invalid NTLM requests are blocked before delegating to NtlmHttpClient',
    () async {
      final spy = _SpyNtlmHttpClient();
      final repo = RequestExecutionRepositoryImpl(
        const DioClient(),
        httpCookieRepository: _NoopHttpCookieRepository(),
        ntlmHttpClient: spy,
      );

      final result = await repo.executeRequest(
        AuthAppliedRequest(
          request: RequestDraft(
            url: 'https://example.com',
            auth: const RequestAuthDraft(
              type: AuthType.ntlm,
              ntlm: NtlmAuthDraft(username: '', password: 'pass'),
            ),
          ),
          appliedAuthType: AuthType.ntlm,
        ),
      );

      expect(spy.called, isFalse);
      expect(result.wasBlocked, isTrue);
      expect(result.errorMessage, 'Username is required for NTLM.');
    },
  );

  test('non-NTLM requests are not delegated to NtlmHttpClient', () async {
    final spy = _SpyNtlmHttpClient();
    final repo = RequestExecutionRepositoryImpl(
      const DioClient(),
      httpCookieRepository: _NoopHttpCookieRepository(),
      ntlmHttpClient: spy,
    );

    // Unroutable port — the Dio path fails fast without a real network call.
    await repo.executeRequest(
      _request(AuthType.none, url: 'http://127.0.0.1:1'),
    );

    expect(spy.called, isFalse);
  });
}
