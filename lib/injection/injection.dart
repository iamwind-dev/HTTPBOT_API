import 'package:app_links/app_links.dart';
import 'package:get_it/get_it.dart';

import '../core/network/dio_client.dart';
import '../core/network/ntlm_http_client.dart';
import '../core/services/external_uri_launcher.dart';
import '../core/services/oauth2_callback_service.dart';
import '../core/theme/cubit/theme_cubit.dart';
import '../core/theme/shared_preferences_theme_mode_store.dart';
import '../core/theme/theme_mode_store.dart';
import '../features/postman/data/datasources/postman_local_datasource.dart';
import '../features/postman/data/datasources/postman_local_datasource_impl.dart';
import '../features/postman/data/datasources/postman_remote_datasource.dart';
import '../features/postman/data/datasources/postman_remote_datasource_impl.dart';
import '../features/postman/data/repositories_impl/collection_repository_impl.dart';
import '../features/postman/data/repositories_impl/postman_session_repository_impl.dart';
import '../features/postman/domain/repositories/collection_repository.dart';
import '../features/postman/domain/repositories/postman_session_repository.dart';
import '../features/postman/domain/usecases/clear_cached_postman_collections_usecase.dart';
import '../features/postman/domain/usecases/clear_cached_postman_workspaces_usecase.dart';
import '../features/postman/domain/usecases/clear_postman_account_usecase.dart';
import '../features/postman/domain/usecases/clear_postman_api_key_usecase.dart';
import '../features/postman/domain/usecases/get_postman_authenticated_user_usecase.dart';
import '../features/postman/domain/usecases/get_postman_collection_detail_usecase.dart';
import '../features/postman/domain/usecases/get_postman_collections_usecase.dart';
import '../features/postman/domain/usecases/load_cached_postman_collections_usecase.dart';
import '../features/postman/domain/usecases/load_cached_postman_workspaces_usecase.dart';
import '../features/postman/domain/usecases/load_postman_account_usecase.dart';
import '../features/postman/domain/usecases/load_postman_api_key_usecase.dart';
import '../features/postman/domain/usecases/save_cached_postman_collections_usecase.dart';
import '../features/postman/domain/usecases/save_cached_postman_workspaces_usecase.dart';
import '../features/postman/domain/usecases/save_postman_account_usecase.dart';
import '../features/postman/domain/usecases/save_postman_api_key_usecase.dart';
import '../features/postman/domain/usecases/get_postman_workspace_detail_usecase.dart';
import '../features/postman/domain/usecases/get_postman_workspaces_usecase.dart';
import '../features/request_history/data/repositories/request_history_repository_impl.dart';
import '../features/request_history/domain/repositories/request_history_repository.dart';
import '../features/request_history/domain/usecases/clear_request_history_use_case.dart';
import '../features/request_history/domain/usecases/get_request_history_entries_use_case.dart';
import '../features/request_history/domain/usecases/save_request_history_entry_use_case.dart';
import '../features/request_history/presentation/cubit/request_history_cubit.dart';
import '../features/request_builder/data/repositories/request_execution_repository_impl.dart';
import '../features/request_builder/data/repositories/response_filter_repository_impl.dart';
import '../features/request_builder/domain/repositories/response_filter_repository.dart';
import '../features/request_builder/data/repositories/http_cookie_repository_impl.dart';
import '../features/request_builder/data/repositories/request_builder_repository_impl.dart';
import '../features/request_builder/data/datasources/oauth2_remote_datasource.dart';
import '../features/request_builder/data/repositories/oauth2_repository_impl.dart';
import '../features/request_builder/data/repositories/graphql_repository_impl.dart';
import '../features/request_builder/data/repositories/saved_credentials_repository_impl.dart';
import '../features/request_builder/domain/repositories/graphql_repository.dart';
import '../features/request_builder/domain/repositories/http_cookie_repository.dart';
import '../features/request_builder/domain/repositories/oauth2_repository.dart';
import '../features/request_builder/domain/repositories/request_execution_repository.dart';
import '../features/request_builder/domain/repositories/request_builder_repository.dart';
import '../features/request_builder/domain/repositories/saved_credentials_repository.dart';
import '../features/request_builder/domain/usecases/exchange_oauth2_authorization_code_use_case.dart';
import '../features/request_builder/domain/usecases/fetch_graphql_schema_use_case.dart';
import '../features/request_builder/domain/usecases/request_oauth2_client_credentials_token_use_case.dart';
import '../features/request_builder/domain/usecases/request_oauth2_password_credentials_token_use_case.dart';
import '../features/request_builder/domain/usecases/get_saved_graphql_queries_use_case.dart';
import '../features/request_builder/domain/usecases/get_saved_graphql_variables_use_case.dart';
import '../features/request_builder/domain/usecases/get_saved_credentials_use_case.dart';
import '../features/request_builder/domain/usecases/save_saved_graphql_queries_use_case.dart';
import '../features/request_builder/domain/usecases/save_saved_graphql_variables_use_case.dart';
import '../features/request_builder/domain/usecases/save_saved_credentials_use_case.dart';
import '../features/request_builder/presentation/cubit/manage_credentials_cubit.dart';
import '../features/request_builder/domain/usecases/clear_current_request_draft_session_use_case.dart';
import '../features/request_builder/domain/usecases/execute_request_use_case.dart';
import '../features/request_builder/domain/usecases/evaluate_request_tests_use_case.dart';
import '../features/request_builder/domain/usecases/get_current_request_draft_session_use_case.dart';
import '../features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../features/request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import '../features/request_builder/domain/usecases/get_saved_request_drafts_use_case.dart';
import '../features/request_builder/domain/usecases/parse_response_use_case.dart';
import '../features/request_builder/domain/usecases/apply_request_auth_use_case.dart';
import '../features/request_builder/domain/usecases/save_current_request_draft_session_use_case.dart';
import '../features/request_builder/domain/usecases/save_request_draft_use_case.dart';
import '../features/request_builder/domain/usecases/save_request_variable_store_use_case.dart';
import '../features/request_builder/domain/usecases/save_saved_request_drafts_use_case.dart';
import '../features/request_builder/domain/usecases/resolve_request_use_case.dart';
import '../features/request_builder/presentation/bloc/request_send_bloc.dart';
import '../features/web_sockets/data/datasources/io_web_socket_client.dart';
import '../features/web_sockets/domain/repositories/web_socket_client.dart';
import '../features/web_sockets/domain/repositories/web_socket_repository.dart';
import '../features/web_sockets/data/repositories_impl/web_socket_repository_impl.dart';
import '../features/web_sockets/presentation/cubits/web_socket_list_cubit.dart';

final getIt = GetIt.instance;

/// Registers the runtime dependencies used across the app.
void configureDependencies() {
  if (getIt.isRegistered<DioClient>()) {
    return;
  }

  getIt
    ..registerLazySingleton<DioClient>(DioClient.new)
    ..registerLazySingleton<NtlmHttpClient>(NtlmHttpClient.new)
    ..registerLazySingleton(AppLinks.new)
    ..registerLazySingleton<OAuth2CallbackService>(
      () => AppLinksOAuth2CallbackService(appLinks: getIt<AppLinks>()),
    )
    ..registerLazySingleton<ExternalUriLauncher>(
      UrlLauncherExternalUriLauncher.new,
    )
    ..registerLazySingleton<WebSocketClient>(IoWebSocketClient.new)
    ..registerLazySingleton<WebSocketRepository>(WebSocketRepositoryImpl.new)
    ..registerFactory(() => WebSocketListCubit(getIt<WebSocketRepository>()))
    ..registerLazySingleton<ThemeModeStore>(SharedPreferencesThemeModeStore.new)
    ..registerFactory(() => ThemeCubit(getIt<ThemeModeStore>()))
    ..registerLazySingleton<PostmanLocalDataSource>(
      PostmanLocalDataSourceImpl.new,
    )
    ..registerLazySingleton<PostmanRemoteDataSource>(
      () => PostmanRemoteDataSourceImpl(getIt<DioClient>().create()),
    )
    ..registerLazySingleton<CollectionRepository>(
      () => CollectionRepositoryImpl(
        getIt<PostmanRemoteDataSource>(),
        getIt<PostmanLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<PostmanSessionRepository>(
      () => PostmanSessionRepositoryImpl(getIt<PostmanLocalDataSource>()),
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
      () => LoadCachedPostmanWorkspacesUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => LoadCachedPostmanCollectionsUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => SavePostmanApiKeyUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => SavePostmanAccountUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => SaveCachedPostmanWorkspacesUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => SaveCachedPostmanCollectionsUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => ClearPostmanApiKeyUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => ClearPostmanAccountUseCase(getIt<PostmanSessionRepository>()),
    )
    ..registerLazySingleton(
      () => ClearCachedPostmanWorkspacesUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton(
      () => ClearCachedPostmanCollectionsUseCase(getIt<CollectionRepository>()),
    )
    ..registerLazySingleton<RequestBuilderRepository>(
      RequestBuilderRepositoryImpl.new,
    )
    ..registerLazySingleton<HttpCookieRepository>(HttpCookieRepositoryImpl.new)
    ..registerLazySingleton<RequestExecutionRepository>(
      () => RequestExecutionRepositoryImpl(
        getIt<DioClient>(),
        httpCookieRepository: getIt<HttpCookieRepository>(),
        ntlmHttpClient: getIt<NtlmHttpClient>(),
      ),
    )
    ..registerLazySingleton(
      () => OAuth2RemoteDataSource(dio: getIt<DioClient>().create()),
    )
    ..registerLazySingleton<OAuth2Repository>(
      () => OAuth2RepositoryImpl(getIt<OAuth2RemoteDataSource>()),
    )
    ..registerLazySingleton<RequestHistoryRepository>(
      RequestHistoryRepositoryImpl.new,
    )
    ..registerLazySingleton<ResponseFilterRepository>(
      ResponseFilterRepositoryImpl.new,
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
    () => SaveRequestVariableStoreUseCase(getIt<RequestBuilderRepository>()),
  );
  getIt.registerLazySingleton(
    () => ExecuteRequestUseCase(getIt<RequestExecutionRepository>()),
  );
  getIt.registerLazySingleton(EvaluateRequestTestsUseCase.new);
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
  getIt.registerLazySingleton<GraphQlRepository>(
    () => GraphQlRepositoryImpl(
      getIt<DioClient>(),
      getIt<ResolveRequestUseCase>(),
      getIt<ApplyRequestAuthUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => FetchGraphQlSchemaUseCase(getIt<GraphQlRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSavedGraphQlQueriesUseCase(getIt<GraphQlRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveSavedGraphQlQueriesUseCase(getIt<GraphQlRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSavedGraphQlVariablesUseCase(getIt<GraphQlRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveSavedGraphQlVariablesUseCase(getIt<GraphQlRepository>()),
  );
  getIt.registerLazySingleton(
    () => ExchangeOAuth2AuthorizationCodeUseCase(getIt<OAuth2Repository>()),
  );
  getIt.registerLazySingleton(
    () =>
        RequestOAuth2PasswordCredentialsTokenUseCase(getIt<OAuth2Repository>()),
  );
  getIt.registerLazySingleton(
    () => RequestOAuth2ClientCredentialsTokenUseCase(getIt<OAuth2Repository>()),
  );
  getIt.registerFactory(
    () => RequestSendBloc(
      resolveRequestUseCase: getIt<ResolveRequestUseCase>(),
      applyRequestAuthUseCase: getIt<ApplyRequestAuthUseCase>(),
      executeRequestUseCase: getIt<ExecuteRequestUseCase>(),
      evaluateRequestTestsUseCase: getIt<EvaluateRequestTestsUseCase>(),
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
  getIt.registerLazySingleton<SavedCredentialsRepository>(
    SavedCredentialsRepositoryImpl.new,
  );
  getIt.registerLazySingleton(
    () => GetSavedCredentialsUseCase(getIt<SavedCredentialsRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveSavedCredentialsUseCase(getIt<SavedCredentialsRepository>()),
  );
  getIt.registerFactory(
    () => ManageCredentialsCubit(
      getSavedCredentialsUseCase: getIt<GetSavedCredentialsUseCase>(),
      saveSavedCredentialsUseCase: getIt<SaveSavedCredentialsUseCase>(),
    ),
  );
}
