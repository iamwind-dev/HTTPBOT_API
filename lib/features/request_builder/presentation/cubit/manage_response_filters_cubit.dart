import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/response_filter.dart';
import '../../domain/usecases/get_saved_response_filters_use_case.dart';
import '../../domain/usecases/save_saved_response_filters_use_case.dart';
import 'manage_response_filters_state.dart';

class ManageResponseFiltersCubit extends Cubit<ManageResponseFiltersState> {
  ManageResponseFiltersCubit({
    required GetSavedResponseFiltersUseCase getSavedResponseFiltersUseCase,
    required SaveSavedResponseFiltersUseCase saveSavedResponseFiltersUseCase,
  }) : _getSavedResponseFiltersUseCase = getSavedResponseFiltersUseCase,
       _saveSavedResponseFiltersUseCase = saveSavedResponseFiltersUseCase,
       super(const ManageResponseFiltersState());

  final GetSavedResponseFiltersUseCase _getSavedResponseFiltersUseCase;
  final SaveSavedResponseFiltersUseCase _saveSavedResponseFiltersUseCase;

  Future<void> load() async {
    emit(state.copyWith(status: ManageResponseFiltersStatus.loading));
    try {
      final filters = await _getSavedResponseFiltersUseCase();
      emit(
        state.copyWith(
          status: ManageResponseFiltersStatus.ready,
          filters: filters.reversed.toList(growable: false),
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ManageResponseFiltersStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> saveFilter(ResponseFilter filter) async {
    final next = List<ResponseFilter>.from(state.filters);
    final existingIndex = next.indexWhere((item) => item.id == filter.id);
    if (existingIndex >= 0) {
      next[existingIndex] = filter;
    } else {
      next.insert(0, filter);
    }
    await _persist(next);
  }

  Future<void> delete(String id) async {
    final next = state.filters
        .where((filter) => filter.id != id)
        .toList(growable: false);
    await _persist(next);
  }

  Future<void> deleteAll() => _persist(const <ResponseFilter>[]);

  Future<void> _persist(List<ResponseFilter> filters) async {
    emit(state.copyWith(status: ManageResponseFiltersStatus.saving));
    try {
      await _saveSavedResponseFiltersUseCase(
        filters.reversed.toList(growable: false),
      );
      emit(
        state.copyWith(
          status: ManageResponseFiltersStatus.ready,
          filters: filters,
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ManageResponseFiltersStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
