import '../entities/response_filter.dart';

abstract interface class ResponseFiltersRepository {
  Future<List<ResponseFilter>> getSavedFilters();

  Future<void> saveSavedFilters(List<ResponseFilter> filters);
}
