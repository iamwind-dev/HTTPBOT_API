import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_auth_draft.dart';

void main() {
  group('NtlmAuthDraft.canApplyNtlm', () {
    test('is true when username and password are present', () {
      const draft = NtlmAuthDraft(username: 'user', password: 'pass');
      expect(draft.canApplyNtlm, isTrue);
    });

    test('is false when username is empty or whitespace', () {
      const draft = NtlmAuthDraft(username: '   ', password: 'pass');
      expect(draft.canApplyNtlm, isFalse);
    });

    test('is false when password is empty', () {
      const draft = NtlmAuthDraft(username: 'user', password: '');
      expect(draft.canApplyNtlm, isFalse);
    });

    test('is true with empty domain when username and password present', () {
      const draft =
          NtlmAuthDraft(username: 'user', password: 'pass', domain: '');
      expect(draft.canApplyNtlm, isTrue);
    });

    test('copyWith overrides only the provided fields', () {
      const draft = NtlmAuthDraft(username: 'user', password: 'pass');
      final next = draft.copyWith(domain: 'CORP');
      expect(next.username, 'user');
      expect(next.password, 'pass');
      expect(next.domain, 'CORP');
      expect(next.workstation, '');
    });
  });
}
