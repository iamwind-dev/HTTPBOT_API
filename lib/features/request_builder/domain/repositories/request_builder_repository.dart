import '../entities/request_draft.dart';

abstract interface class RequestBuilderRepository {
  RequestDraft getInitialDraft();
}
