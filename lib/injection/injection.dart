import 'package:get_it/get_it.dart';

import '../core/network/dio_client.dart';
import '../core/theme/cubit/theme_cubit.dart';
import '../core/theme/shared_preferences_theme_mode_store.dart';
import '../core/theme/theme_mode_store.dart';
import '../features/request_builder/data/repositories/request_builder_repository_impl.dart';
import '../features/request_builder/domain/repositories/request_builder_repository.dart';
import '../features/request_builder/domain/usecases/get_request_draft_use_case.dart';

final getIt = GetIt.instance;

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
    ..registerLazySingleton(
      () => GetRequestDraftUseCase(getIt<RequestBuilderRepository>()),
    );
}
