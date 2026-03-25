import 'package:httpbot_api/features/request_builder/domain/entities/request_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/repositories/request_builder_repository.dart';

class FakeRequestBuilderRepository implements RequestBuilderRepository {
  const FakeRequestBuilderRepository();

  @override
  RequestDraft getInitialDraft() => const RequestDraft(
    method: 'GET',
    url: 'https://api.example.com/users',
    authMode: 'Bearer',
    bodyMode: 'JSON',
  );
}
