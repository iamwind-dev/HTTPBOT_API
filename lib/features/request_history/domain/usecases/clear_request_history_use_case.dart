import '../repositories/request_history_repository.dart';

class ClearRequestHistoryUseCase {
  const ClearRequestHistoryUseCase(this._repository);

  final RequestHistoryRepository _repository;

  /// Removes every saved history entry so the history view can start clean again.
  Future<void> call() => _repository.clearRequestHistory();
}
