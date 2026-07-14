import '../entities/response_filter.dart';
import '../repositories/response_filters_repository.dart';

class GetSavedResponseFiltersUseCase {
  const GetSavedResponseFiltersUseCase(this._repository);

  final ResponseFiltersRepository _repository;

  Future<List<ResponseFilter>> call() => _repository.getSavedFilters();
}
