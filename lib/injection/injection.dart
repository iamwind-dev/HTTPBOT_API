import 'package:get_it/get_it.dart';

import '../core/network/dio_client.dart';
import '../core/theme/cubit/theme_cubit.dart';
import '../core/theme/shared_preferences_theme_mode_store.dart';
import '../core/theme/theme_mode_store.dart';
import '../features/request_history/data/repositories/request_history_repository_impl.dart';
import '../features/request_history/domain/repositories/request_history_repository.dart';
import '../features/request_history/domain/usecases/clear_request_history_use_case.dart';
import '../features/request_history/domain/usecases/get_request_history_entries_use_case.dart';
import '../features/request_history/domain/usecases/save_request_history_entry_use_case.dart';
import '../features/request_history/presentation/cubit/request_history_cubit.dart';
import '../features/request_builder/data/repositories/request_execution_repository_impl.dart';
import '../features/request_builder/data/repositories/request_builder_repository_impl.dart';
import '../features/request_builder/domain/repositories/request_execution_repository.dart';
import '../features/request_builder/domain/repositories/request_builder_repository.dart';
import '../features/request_builder/domain/usecases/clear_current_request_draft_session_use_case.dart';
import '../features/request_builder/domain/usecases/execute_request_use_case.dart';
import '../features/request_builder/domain/usecases/get_current_request_draft_session_use_case.dart';
import '../features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../features/request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import '../features/request_builder/domain/usecases/get_saved_request_drafts_use_case.dart';
import '../features/request_builder/domain/usecases/parse_response_use_case.dart';
import '../features/request_builder/domain/usecases/apply_request_auth_use_case.dart';
import '../features/request_builder/domain/usecases/save_current_request_draft_session_use_case.dart';
import '../features/request_builder/domain/usecases/save_request_draft_use_case.dart';
import '../features/request_builder/domain/usecases/save_saved_request_drafts_use_case.dart';
import '../features/request_builder/domain/usecases/resolve_request_use_case.dart';
import '../features/request_builder/presentation/bloc/request_send_bloc.dart';

final getIt = GetIt.instance;

/// Registers the runtime dependencies used across the app.
void configureDependencies() {
  if (getIt.isRegistered<DioClient>()) {
    return;
  }

  getIt
    ..registerLazySingleton<DioClient>(DioClient.new)
    ..registerLazySingleton<ThemeModeStore>(SharedPreferencesThemeModeStore.new)
    ..registerFactory(() => ThemeCubit(getIt<ThemeModeStore>()))
    ..registerLazySingleton<RequestBuilderRepository>(
      RequestBuilderRepositoryImpl.new,
    )
    ..registerLazySingleton<RequestExecutionRepository>(
      () => RequestExecutionRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton<RequestHistoryRepository>(
      RequestHistoryRepositoryImpl.new,
    )
    ..registerLazySingleton(
      () => GetRequestDraftUseCase(getIt<RequestBuilderRepository>()),
    )
    ..registerLazySingleton(
      () => SaveRequestDraftUseCase(getIt<RequestBuilderRepository>()),
    )
    ..registerLazySingleton(
      () => GetCurrentRequestDraftSessionUseCase(
        getIt<RequestBuilderRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => SaveCurrentRequestDraftSessionUseCase(
        getIt<RequestBuilderRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => ClearCurrentRequestDraftSessionUseCase(
        getIt<RequestBuilderRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => GetSavedRequestDraftsUseCase(getIt<RequestBuilderRepository>()),
    )
    ..registerLazySingleton(
      () => SaveSavedRequestDraftsUseCase(getIt<RequestBuilderRepository>()),
    );
  getIt.registerLazySingleton(
    () => GetRequestVariableStoreUseCase(getIt<RequestBuilderRepository>()),
  );
  getIt.registerLazySingleton(
    () => ExecuteRequestUseCase(getIt<RequestExecutionRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetRequestHistoryEntriesUseCase(getIt<RequestHistoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => ClearRequestHistoryUseCase(getIt<RequestHistoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveRequestHistoryEntryUseCase(getIt<RequestHistoryRepository>()),
  );
  getIt.registerLazySingleton(ResolveRequestUseCase.new);
  getIt.registerLazySingleton(ApplyRequestAuthUseCase.new);
  getIt.registerLazySingleton(ParseResponseUseCase.new);
  getIt.registerFactory(
    () => RequestSendBloc(
      resolveRequestUseCase: getIt<ResolveRequestUseCase>(),
      applyRequestAuthUseCase: getIt<ApplyRequestAuthUseCase>(),
      executeRequestUseCase: getIt<ExecuteRequestUseCase>(),
      parseResponseUseCase: getIt<ParseResponseUseCase>(),
      saveRequestHistoryEntryUseCase: getIt<SaveRequestHistoryEntryUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => RequestHistoryCubit(
      getIt<GetRequestHistoryEntriesUseCase>(),
      getIt<ClearRequestHistoryUseCase>(),
    ),
  );
}
