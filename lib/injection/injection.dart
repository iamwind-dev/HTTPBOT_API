import 'package:get_it/get_it.dart';

import '../core/network/dio_client.dart';
import '../core/theme/cubit/theme_cubit.dart';
import '../core/theme/shared_preferences_theme_mode_store.dart';
import '../core/theme/theme_mode_store.dart';
import '../features/postman/data/datasources/postman_remote_datasource.dart';
import '../features/postman/data/repositories_impl/collection_repository_impl.dart';
import '../features/postman/data/repositories_impl/postman_session_repository_impl.dart';
import '../features/postman/domain/repositories/collection_repository.dart';
import '../features/postman/domain/repositories/postman_session_repository.dart';
import '../features/postman/domain/usecases/clear_postman_account_usecase.dart';
import '../features/postman/domain/usecases/clear_postman_api_key_usecase.dart';
import '../features/postman/domain/usecases/get_postman_authenticated_user_usecase.dart';
import '../features/postman/domain/usecases/get_postman_collection_detail_usecase.dart';
import '../features/postman/domain/usecases/get_postman_collections_usecase.dart';
import '../features/postman/domain/usecases/load_postman_account_usecase.dart';
import '../features/postman/domain/usecases/load_postman_api_key_usecase.dart';
import '../features/postman/domain/usecases/save_postman_account_usecase.dart';
import '../features/postman/domain/usecases/save_postman_api_key_usecase.dart';
import '../features/postman/domain/usecases/get_postman_workspace_detail_usecase.dart';
import '../features/postman/domain/usecases/get_postman_workspaces_usecase.dart';
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
    ..registerLazySingleton<PostmanRemoteDataSource>(
      () => PostmanRemoteDataSourceImpl(getIt<DioClient>().create()),
    )
    ..registerLazySingleton<CollectionRepository>(
      () => CollectionRepositoryImpl(getIt<PostmanRemoteDataSource>()),
    )
    ..registerLazySingleton<PostmanSessionRepository>(
      PostmanSessionRepositoryImpl.new,
    )
    ..registerLazySingleton(
      () => GetPostmanAuthenticatedUserUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => GetPostmanCollectionsUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => GetPostmanWorkspacesUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => GetPostmanWorkspaceDetailUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => GetPostmanCollectionDetailUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => LoadPostmanApiKeyUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => LoadPostmanAccountUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => SavePostmanApiKeyUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => SavePostmanAccountUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => ClearPostmanApiKeyUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => ClearPostmanAccountUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton<RequestBuilderRepository>(
      RequestBuilderRepositoryImpl.new,
    )
    ..registerLazySingleton(
      () => GetRequestDraftUseCase(getIt<RequestBuilderRepository>()),
    );
}
