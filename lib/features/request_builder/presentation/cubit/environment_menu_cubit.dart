import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_environment.dart';
import '../../domain/entities/request_variable.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/usecases/get_request_variable_store_use_case.dart';
import '../../domain/usecases/save_request_variable_store_use_case.dart';
import 'environment_menu_state.dart';

/// Owns the live variable store backing the Environment menu and request sending.
class EnvironmentMenuCubit extends Cubit<EnvironmentMenuState> {
  EnvironmentMenuCubit(
    this._getRequestVariableStoreUseCase,
    this._saveRequestVariableStoreUseCase, {
    RequestVariableStore? initialStore,
  }) : super(
         EnvironmentMenuState(
           status: initialStore == null
               ? EnvironmentMenuStatus.initial
               : EnvironmentMenuStatus.ready,
           store: initialStore ?? const RequestVariableStore(),
         ),
       );

  final GetRequestVariableStoreUseCase _getRequestVariableStoreUseCase;
  final SaveRequestVariableStoreUseCase _saveRequestVariableStoreUseCase;

  /// Reloads the persisted store and clears a selection that no longer exists.
  Future<void> loadAvailableEnvironments() async {
    emit(state.copyWith(status: EnvironmentMenuStatus.loading));

    try {
      final store = await _getRequestVariableStoreUseCase();
      final sanitizedStore = _clearStaleSelection(store);
      if (sanitizedStore != store) {
        await _saveRequestVariableStoreUseCase(sanitizedStore);
      }

      emit(
        state.copyWith(
          status: EnvironmentMenuStatus.ready,
          store: sanitizedStore,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: EnvironmentMenuStatus.failure));
    }
  }

  /// Applies the environment to the current request and persists the choice.
  Future<void> selectEnvironment(String environmentId) =>
      _persist(_withSelection(environmentId));

  /// Removes the selected environment so resolution falls back to globals only.
  Future<void> deactivateEnvironment() => _persist(_withSelection(''));

  /// Replaces the global variables while keeping environments untouched.
  Future<void> saveGlobalVariables(List<RequestVariable> variables) => _persist(
    RequestVariableStore(
      globalVariables: List<RequestVariable>.unmodifiable(variables),
      environments: state.store.environments,
      selectedEnvironmentId: state.store.selectedEnvironmentId,
    ),
  );

  /// Replaces the environment list and drops the selection when it was deleted.
  Future<void> saveEnvironments(List<RequestEnvironment> environments) =>
      _persist(
        _clearStaleSelection(
          RequestVariableStore(
            globalVariables: state.store.globalVariables,
            environments: List<RequestEnvironment>.unmodifiable(environments),
            selectedEnvironmentId: state.store.selectedEnvironmentId,
          ),
        ),
      );

  RequestVariableStore _withSelection(String environmentId) =>
      RequestVariableStore(
        globalVariables: state.store.globalVariables,
        environments: state.store.environments,
        selectedEnvironmentId: environmentId,
      );

  RequestVariableStore _clearStaleSelection(RequestVariableStore store) {
    if (store.selectedEnvironmentId.isEmpty ||
        store.selectedEnvironment != null) {
      return store;
    }

    return RequestVariableStore(
      globalVariables: store.globalVariables,
      environments: store.environments,
      selectedEnvironmentId: '',
    );
  }

  Future<void> _persist(RequestVariableStore store) async {
    emit(state.copyWith(status: EnvironmentMenuStatus.ready, store: store));

    try {
      await _saveRequestVariableStoreUseCase(store);
    } catch (_) {
      emit(state.copyWith(status: EnvironmentMenuStatus.failure));
    }
  }
}
