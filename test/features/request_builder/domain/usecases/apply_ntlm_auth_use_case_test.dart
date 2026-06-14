import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_auth_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_auth_issue.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_key_value.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/resolved_request.dart';
import 'package:httpbot_api/features/request_builder/domain/usecases/apply_request_auth_use_case.dart';

ResolvedRequest _resolved(
  RequestAuthDraft auth, {
  List<KeyValueItem>? headers,
}) {
  return ResolvedRequest(
    request: RequestDraft(
      url: 'https://example.com',
      headers: headers ?? const <KeyValueItem>[],
      auth: auth,
    ),
  );
}

void main() {
  const useCase = ApplyRequestAuthUseCase();

  test('valid NTLM keeps auth on the request and adds no issues', () {
    const auth = RequestAuthDraft(
      type: AuthType.ntlm,
      ntlm: NtlmAuthDraft(username: 'user', password: 'pass'),
    );
    final result = useCase(resolvedRequest: _resolved(auth));

    expect(result.appliedAuthType, AuthType.ntlm);
    expect(result.request.auth.type, AuthType.ntlm);
    expect(result.authIssues, isEmpty);
    expect(
      result.request.headers.where(
        (h) => h.key.toLowerCase() == 'authorization',
      ),
      isEmpty,
    );
  });

  test('preserves Content-Type and user headers', () {
    const auth = RequestAuthDraft(
      type: AuthType.ntlm,
      ntlm: NtlmAuthDraft(username: 'user', password: 'pass'),
    );
    const headers = [
      KeyValueItem(key: 'Content-Type', value: 'application/json'),
      KeyValueItem(key: 'X-Custom', value: 'keep-me'),
    ];
    final result = useCase(resolvedRequest: _resolved(auth, headers: headers));

    expect(result.request.headers, headers);
  });

  test('missing username yields a blocking missing-credentials issue', () {
    const auth = RequestAuthDraft(
      type: AuthType.ntlm,
      ntlm: NtlmAuthDraft(username: '', password: 'pass'),
    );
    final result = useCase(resolvedRequest: _resolved(auth));

    expect(
      result.authIssues.any(
        (i) =>
            i.type == RequestAuthIssueType.missingCredentials &&
            i.fieldName == 'username',
      ),
      isTrue,
    );
  });

  test('missing password yields a blocking missing-credentials issue', () {
    const auth = RequestAuthDraft(
      type: AuthType.ntlm,
      ntlm: NtlmAuthDraft(username: 'user', password: ''),
    );
    final result = useCase(resolvedRequest: _resolved(auth));

    expect(
      result.authIssues.any(
        (i) =>
            i.type == RequestAuthIssueType.missingCredentials &&
            i.fieldName == 'password',
      ),
      isTrue,
    );
  });

  test('NTLM missing-credential issues are blocking', () {
    const auth = RequestAuthDraft(
      type: AuthType.ntlm,
      ntlm: NtlmAuthDraft(username: '', password: ''),
    );
    final result = useCase(resolvedRequest: _resolved(auth));

    expect(result.hasBlockingIssues, isTrue);
  });
}
