import '../entities/response_filter.dart';
import '../repositories/response_filters_repository.dart';

class SaveSavedResponseFiltersUseCase {
  const SaveSavedResponseFiltersUseCase(this._repository);

  final ResponseFiltersRepository _repository;

  Future<void> call(List<ResponseFilter> filters) =>
      _repository.saveSavedFilters(filters);
}
