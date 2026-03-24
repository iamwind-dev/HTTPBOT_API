import '../../domain/entities/request_draft.dart';
import '../../domain/repositories/request_builder_repository.dart';

class RequestBuilderRepositoryImpl implements RequestBuilderRepository {
  const RequestBuilderRepositoryImpl();

  @override
  RequestDraft getInitialDraft() => const RequestDraft(
    method: 'GET',
    url: 'https://api.example.com',
    authMode: 'None',
    bodyMode: 'None',
  );
}
