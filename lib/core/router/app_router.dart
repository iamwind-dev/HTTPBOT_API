import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/keys/widget_keys.dart';
import '../../core/theme/app_theme_context.dart';
import '../../core/widgets/app_page_header.dart';
import '../../core/widgets/app_shell_scaffold.dart';
import '../../features/collection/presentation/cubits/collection_cubit.dart';
import '../../features/collection/presentation/cubits/collection_state.dart';
import '../../features/collection/presentation/screens/collection_screens.dart';
import '../../features/collection/presentation/widget/collections_more_button.dart';
import '../../features/collection/presentation/widget/collections_search.dart';
import '../../features/collection/presentation/widget/collections_shell_action_button.dart';
import '../../features/postman/presentation/screens/postman_screens.dart';
import '../../features/postman/presentation/widget/postman_more_button.dart';
import '../../features/postman/presentation/widget/postman_shell_action_button.dart';
import '../../features/postman/presentation/widget/search_postman.dart';
import '../../features/request_builder/domain/entities/request_draft.dart';
import '../../features/request_builder/domain/entities/request_variable_store.dart';
import '../../features/request_builder/domain/entities/har_request_import_outcome.dart';
import '../../features/request_builder/domain/helpers/simple_curl_request_parser.dart';
import '../../features/request_builder/domain/repositories/request_transfer_gateway.dart';
import '../../features/request_builder/domain/usecases/clear_current_request_draft_session_use_case.dart';
import '../../features/request_builder/domain/usecases/get_current_request_draft_session_use_case.dart';
import '../../features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../../features/request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import '../../features/request_builder/domain/usecases/get_saved_request_drafts_use_case.dart';
import '../../features/request_builder/domain/usecases/import_har_requests_use_case.dart';
import '../../features/request_builder/domain/usecases/parse_curl_request_use_case.dart';
import '../../features/request_builder/domain/usecases/save_current_request_draft_session_use_case.dart';
import '../../features/request_builder/domain/usecases/save_saved_request_drafts_use_case.dart';
import '../../features/request_builder/presentation/cubit/request_builder_cubit.dart';
import '../../features/request_builder/presentation/cubit/request_builder_state.dart';
import '../../features/request_builder/presentation/pages/request_builder_page.dart';
import '../../features/request_builder/presentation/widgets/manage_environments_sheet.dart';
import '../../features/request_builder/presentation/widgets/global_variables_sheet.dart';
import '../../features/request_builder/presentation/widgets/request_cookies_sheet.dart';
import '../../features/request_builder/presentation/widgets/request_editor_sheet.dart';
import '../../features/request_builder/presentation/widgets/request_search_field.dart';
import '../../features/request_builder/presentation/widgets/request_shell_action_button.dart';
import '../../features/request_builder/presentation/widgets/saved_response_filters_sheet.dart';
import '../../features/postman/domain/usecases/clear_postman_account_usecase.dart';
import '../../features/postman/domain/usecases/clear_postman_api_key_usecase.dart';
import '../../features/postman/domain/usecases/clear_cached_postman_collections_usecase.dart';
import '../../features/postman/domain/usecases/clear_cached_postman_workspaces_usecase.dart';
import '../../features/postman/domain/usecases/get_postman_authenticated_user_usecase.dart';
import '../../features/postman/domain/usecases/get_postman_collection_detail_usecase.dart';
import '../../features/postman/domain/usecases/get_postman_collections_usecase.dart';
import '../../features/postman/domain/usecases/get_postman_workspace_detail_usecase.dart';
import '../../features/postman/domain/usecases/get_postman_workspaces_usecase.dart';
import '../../features/postman/domain/usecases/load_cached_postman_collections_usecase.dart';
import '../../features/postman/domain/usecases/load_cached_postman_workspaces_usecase.dart';
import '../../features/postman/domain/usecases/load_postman_account_usecase.dart';
import '../../features/postman/domain/usecases/load_postman_api_key_usecase.dart';
import '../../features/postman/domain/usecases/save_cached_postman_collections_usecase.dart';
import '../../features/postman/domain/usecases/save_cached_postman_workspaces_usecase.dart';
import '../../features/postman/domain/usecases/save_postman_account_usecase.dart';
import '../../features/postman/domain/usecases/save_postman_api_key_usecase.dart';
import '../../features/postman/presentation/cubit/postman_account_cubit.dart';
import '../../features/postman/presentation/cubit/postman_cubit.dart';
import '../../features/postman/presentation/cubit/postman_state.dart';
import '../../features/postman/presentation/screens/postman_account_screen.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/domain/entities/disk_usage_models.dart';
import '../../features/settings/domain/services/disk_usage_service.dart';
import '../../features/settings/presentation/cubit/disk_usage_cubit.dart';
import '../../features/settings/presentation/cubit/disk_usage_state.dart';
import '../../features/settings/presentation/models/settings_catalog.dart';
import '../../features/settings/presentation/pages/settings_cookies_page.dart';
import '../../features/settings/presentation/pages/settings_detail_page.dart';
import '../../features/settings/presentation/pages/settings_disk_usage_page.dart';
import '../../features/settings/presentation/pages/settings_graphql_page.dart';
import '../../features/settings/presentation/pages/settings_global_variables_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/settings_request_settings_page.dart';
import '../../features/settings/presentation/pages/settings_response_filters_page.dart';
import '../../features/settings/presentation/pages/settings_saved_credentials_page.dart';
import '../../features/web_sockets/presentation/cubits/web_socket_list_cubit.dart';
import '../../features/web_sockets/presentation/screens/websocket_screen.dart';
import '../../features/web_sockets/presentation/widget/search_websocket.dart';
import '../../features/web_sockets/presentation/widget/websocket_shell_action_button.dart';
import '../../injection/injection.dart';
import 'app_shell_tab.dart';

abstract final class AppRouter {
  /// Creates the application router with stateful tab branches so each tab preserves its stack.
  static GoRouter createRouter({
    required GetRequestDraftUseCase getRequestDraftUseCase,
    required GetRequestVariableStoreUseCase getRequestVariableStoreUseCase,
    required GetPostmanWorkspacesUseCase getPostmanWorkspacesUseCase,
    required GetPostmanWorkspaceDetailUseCase getPostmanWorkspaceDetailUseCase,
    required GetPostmanCollectionsUseCase getPostmanCollectionsUseCase,
    required GetPostmanCollectionDetailUseCase
    getPostmanCollectionDetailUseCase,
    required SavePostmanApiKeyUseCase savePostmanApiKeyUseCase,
    required SavePostmanAccountUseCase savePostmanAccountUseCase,
    required SaveCachedPostmanWorkspacesUseCase
    saveCachedPostmanWorkspacesUseCase,
    required SaveCachedPostmanCollectionsUseCase
    saveCachedPostmanCollectionsUseCase,
    required LoadPostmanApiKeyUseCase loadPostmanApiKeyUseCase,
    required LoadPostmanAccountUseCase loadPostmanAccountUseCase,
    required LoadCachedPostmanWorkspacesUseCase
    loadCachedPostmanWorkspacesUseCase,
    required LoadCachedPostmanCollectionsUseCase
    loadCachedPostmanCollectionsUseCase,
    required ClearPostmanApiKeyUseCase clearPostmanApiKeyUseCase,
    required ClearPostmanAccountUseCase clearPostmanAccountUseCase,
    required ClearCachedPostmanWorkspacesUseCase
    clearCachedPostmanWorkspacesUseCase,
    required ClearCachedPostmanCollectionsUseCase
    clearCachedPostmanCollectionsUseCase,
    required GetPostmanAuthenticatedUserUseCase
    getPostmanAuthenticatedUserUseCase,
    String? initialLocation,
  }) => GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (context, state) => BlocProvider(
                  create: (_) => RequestBuilderCubit(
                    getRequestDraftUseCase,
                    getRequestVariableStoreUseCase,
                    getCurrentRequestDraftSessionUseCase:
                        getIt<GetCurrentRequestDraftSessionUseCase>(),
                    saveCurrentRequestDraftSessionUseCase:
                        getIt<SaveCurrentRequestDraftSessionUseCase>(),
                    clearCurrentRequestDraftSessionUseCase:
                        getIt<ClearCurrentRequestDraftSessionUseCase>(),
                    getSavedRequestDraftsUseCase:
                        getIt<GetSavedRequestDraftsUseCase>(),
                    saveSavedRequestDraftsUseCase:
                        getIt<SaveSavedRequestDraftsUseCase>(),
                    importHarRequestsUseCase: getIt<ImportHarRequestsUseCase>(),
                    parseCurlRequestUseCase: getIt<ParseCurlRequestUseCase>(),
                  )..load(),
                  child: _RequestsShell(
                    onTabSelected: (tab) =>
                        _handleShellTabSelection(context, tab),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/websockets',
                builder: (context, state) => BlocProvider<WebSocketListCubit>(
                  create: (_) => getIt<WebSocketListCubit>()..load(),
                  child: _WebSocketsShell(
                    onTabSelected: (tab) =>
                        _handleShellTabSelection(context, tab),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/collections',
                builder: (context, state) => BlocProvider(
                  create: (_) => CollectionCubit()..load(),
                  child: _CollectionsShell(
                    onTabSelected: (tab) =>
                        _handleShellTabSelection(context, tab),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/postman',
                builder: (context, state) => BlocProvider(
                  create: (_) => PostmanCubit(
                    getPostmanWorkspacesUseCase: getPostmanWorkspacesUseCase,
                    getPostmanWorkspaceDetailUseCase:
                        getPostmanWorkspaceDetailUseCase,
                    getPostmanCollectionsUseCase: getPostmanCollectionsUseCase,
                    getPostmanCollectionDetailUseCase:
                        getPostmanCollectionDetailUseCase,
                    getPostmanAuthenticatedUserUseCase:
                        getPostmanAuthenticatedUserUseCase,
                    loadPostmanApiKeyUseCase: loadPostmanApiKeyUseCase,
                    loadCachedPostmanWorkspacesUseCase:
                        loadCachedPostmanWorkspacesUseCase,
                    loadCachedPostmanCollectionsUseCase:
                        loadCachedPostmanCollectionsUseCase,
                    savePostmanAccountUseCase: savePostmanAccountUseCase,
                    savePostmanApiKeyUseCase: savePostmanApiKeyUseCase,
                    saveCachedPostmanWorkspacesUseCase:
                        saveCachedPostmanWorkspacesUseCase,
                    saveCachedPostmanCollectionsUseCase:
                        saveCachedPostmanCollectionsUseCase,
                  )..load(),
                  child: _PostmanShell(
                    onTabSelected: (tab) =>
                        _handleShellTabSelection(context, tab),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                builder: (context, state) => BlocProvider(
                  create: (_) => SettingsCubit()..load(),
                  child: _SettingsShell(
                    onTabSelected: (tab) =>
                        _handleShellTabSelection(context, tab),
                    onItemSelected: (itemId) =>
                        context.push('/settings/$itemId'),
                  ),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':itemId',
                    builder: (context, state) {
                      final itemId = state.pathParameters['itemId'] ?? '';
                      if (itemId == 'disk-usage') {
                        return BlocProvider(
                          create: (_) =>
                              DiskUsageCubit(getIt<DiskUsageService>())..load(),
                          child: BlocBuilder<DiskUsageCubit, DiskUsageState>(
                            builder: (context, diskUsageState) =>
                                _SettingsDetailShell(
                                  itemTitle: diskUsageState.selectionMode
                                      ? '${diskUsageState.selectedCount} Selected'
                                      : diskUsageState.selectedTab ==
                                            DiskUsageTab.requests
                                      ? 'Request Disk Usage'
                                      : 'Files Disk Usage',
                                  onBack: () => _handleSettingsBack(context),
                                  trailing: const DiskUsageTabPicker(),
                                  centerTitle: false,
                                  body: const SettingsDiskUsagePage(),
                                  onTabSelected: (tab) =>
                                      _handleShellTabSelection(context, tab),
                                ),
                          ),
                        );
                      }

                      final item = SettingsCatalog.findItemById(itemId);
                      final cookiesController = SettingsCookiesController();
                      final responseFiltersController =
                          SavedResponseFiltersController();
                      final globalVariablesController =
                          GlobalVariablesController();

                      return _SettingsDetailShell(
                        itemTitle: item?.title ?? AppStrings.settingsTitle,
                        onBack: () => _handleSettingsBack(context),
                        headerHeight: _usesTightSettingsLayout(itemId)
                            ? AppPageHeader.tightHeight
                            : null,
                        trailing: _buildSettingsDetailTrailing(
                          context: context,
                          itemId: itemId,
                          cookiesController: cookiesController,
                          responseFiltersController: responseFiltersController,
                          globalVariablesController: globalVariablesController,
                        ),
                        body: _buildSettingsDetailBody(
                          itemId: itemId,
                          cookiesController: cookiesController,
                          responseFiltersController: responseFiltersController,
                          globalVariablesController: globalVariablesController,
                          loadPostmanApiKeyUseCase: loadPostmanApiKeyUseCase,
                          loadPostmanAccountUseCase: loadPostmanAccountUseCase,
                          clearPostmanApiKeyUseCase: clearPostmanApiKeyUseCase,
                          clearPostmanAccountUseCase:
                              clearPostmanAccountUseCase,
                          clearCachedPostmanWorkspacesUseCase:
                              clearCachedPostmanWorkspacesUseCase,
                          clearCachedPostmanCollectionsUseCase:
                              clearCachedPostmanCollectionsUseCase,
                        ),
                        onTabSelected: (tab) =>
                            _handleShellTabSelection(context, tab),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static final GoRouter router = createRouter(
    getRequestDraftUseCase: getIt<GetRequestDraftUseCase>(),
    getRequestVariableStoreUseCase: getIt<GetRequestVariableStoreUseCase>(),
    getPostmanWorkspacesUseCase: getIt<GetPostmanWorkspacesUseCase>(),
    getPostmanWorkspaceDetailUseCase: getIt<GetPostmanWorkspaceDetailUseCase>(),
    getPostmanCollectionsUseCase: getIt<GetPostmanCollectionsUseCase>(),
    getPostmanCollectionDetailUseCase:
        getIt<GetPostmanCollectionDetailUseCase>(),
    savePostmanApiKeyUseCase: getIt<SavePostmanApiKeyUseCase>(),
    savePostmanAccountUseCase: getIt<SavePostmanAccountUseCase>(),
    saveCachedPostmanWorkspacesUseCase:
        getIt<SaveCachedPostmanWorkspacesUseCase>(),
    saveCachedPostmanCollectionsUseCase:
        getIt<SaveCachedPostmanCollectionsUseCase>(),
    loadPostmanApiKeyUseCase: getIt<LoadPostmanApiKeyUseCase>(),
    loadPostmanAccountUseCase: getIt<LoadPostmanAccountUseCase>(),
    loadCachedPostmanWorkspacesUseCase:
        getIt<LoadCachedPostmanWorkspacesUseCase>(),
    loadCachedPostmanCollectionsUseCase:
        getIt<LoadCachedPostmanCollectionsUseCase>(),
    clearPostmanApiKeyUseCase: getIt<ClearPostmanApiKeyUseCase>(),
    clearPostmanAccountUseCase: getIt<ClearPostmanAccountUseCase>(),
    clearCachedPostmanWorkspacesUseCase:
        getIt<ClearCachedPostmanWorkspacesUseCase>(),
    clearCachedPostmanCollectionsUseCase:
        getIt<ClearCachedPostmanCollectionsUseCase>(),
    getPostmanAuthenticatedUserUseCase:
        getIt<GetPostmanAuthenticatedUserUseCase>(),
  );

  /// Switches tabs while restoring each branch's last active route.
  static void _handleShellTabSelection(BuildContext context, AppShellTab tab) {
    final navigationShell = StatefulNavigationShell.of(context);

    navigationShell.goBranch(
      tab.index,
      initialLocation: tab.index == navigationShell.currentIndex,
    );
  }

  /// Pops the settings branch when possible or resets it to the overview route.
  static void _handleSettingsBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final navigationShell = StatefulNavigationShell.of(context);

    navigationShell.goBranch(AppShellTab.settings.index, initialLocation: true);
  }

  static Widget _buildSettingsDetailBody({
    required String itemId,
    required SettingsCookiesController cookiesController,
    required SavedResponseFiltersController responseFiltersController,
    required GlobalVariablesController globalVariablesController,
    required LoadPostmanApiKeyUseCase loadPostmanApiKeyUseCase,
    required LoadPostmanAccountUseCase loadPostmanAccountUseCase,
    required ClearPostmanApiKeyUseCase clearPostmanApiKeyUseCase,
    required ClearPostmanAccountUseCase clearPostmanAccountUseCase,
    required ClearCachedPostmanWorkspacesUseCase
    clearCachedPostmanWorkspacesUseCase,
    required ClearCachedPostmanCollectionsUseCase
    clearCachedPostmanCollectionsUseCase,
  }) {
    if (itemId == 'request-settings') {
      return const SettingsRequestSettingsPage();
    }

    if (itemId == 'cookies') {
      return SettingsCookiesPage(controller: cookiesController);
    }

    if (itemId == 'environments') {
      return const ManageEnvironmentsView();
    }

    if (itemId == 'global-variables') {
      return SettingsGlobalVariablesPage(controller: globalVariablesController);
    }

    if (itemId == 'saved-auth') {
      return const SettingsSavedCredentialsPage();
    }

    if (itemId == 'response-filters') {
      return SettingsResponseFiltersPage(controller: responseFiltersController);
    }

    if (itemId == 'graphql') {
      return const SettingsGraphQlPage();
    }

    if (itemId == 'postman-account') {
      return BlocProvider(
        create: (_) => PostmanAccountCubit(
          loadPostmanApiKeyUseCase: loadPostmanApiKeyUseCase,
          loadPostmanAccountUseCase: loadPostmanAccountUseCase,
          clearPostmanApiKeyUseCase: clearPostmanApiKeyUseCase,
          clearPostmanAccountUseCase: clearPostmanAccountUseCase,
          clearCachedPostmanWorkspacesUseCase:
              clearCachedPostmanWorkspacesUseCase,
          clearCachedPostmanCollectionsUseCase:
              clearCachedPostmanCollectionsUseCase,
        )..load(),
        child: const PostmanAccountScreen(),
      );
    }

    return const SettingsDetailPage();
  }

  static bool _usesTightSettingsLayout(String itemId) => const {
    'graphql',
    'saved-auth',
    'environments',
    'global-variables',
  }.contains(itemId);

  static Widget? _buildSettingsDetailTrailing({
    required BuildContext context,
    required String itemId,
    required SettingsCookiesController cookiesController,
    required SavedResponseFiltersController responseFiltersController,
    required GlobalVariablesController globalVariablesController,
  }) {
    if (itemId == 'cookies') {
      return IconButton(
        key: const ValueKey<String>(AppWidgetKeys.requestsCookiesAddButton),
        onPressed: () async {
          final didSave = await showRequestCookieEditorSheet(
            context,
            initialDomain: cookiesController.selectedDomain,
          );
          if (didSave == true) {
            cookiesController.requestReload();
          }
        },
        icon: const Icon(CupertinoIcons.add),
      );
    }

    if (itemId == 'response-filters') {
      return SettingsResponseFiltersActions(
        controller: responseFiltersController,
      );
    }

    if (itemId == 'global-variables') {
      return IconButton(
        key: const ValueKey<String>(AppWidgetKeys.globalVariablesSaveButton),
        tooltip: 'Save global variables',
        onPressed: () => globalVariablesController.save?.call(),
        icon: const Icon(CupertinoIcons.check_mark),
      );
    }

    return null;
  }
}

class _RequestsShell extends StatelessWidget {
  const _RequestsShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: AppShellTab.requests,
    title: AppStrings.requestsTitle,
    trailing: const _RequestFavoriteButton(),
    bottomSlot: const RequestSearchField(),
    body: const RequestBuilderPage(),
    floatingActionButton: RequestShellActionButton(
      onImportHar: () => _importHar(context),
      onImportCurl: () => _importCurl(context),
      onNewRequest: () => _openNewRequestEditor(context),
    ),
    onTabSelected: onTabSelected,
  );

  Future<void> _openNewRequestEditor(BuildContext context) async {
    final requestBuilderCubit = context.read<RequestBuilderCubit>();
    final state = requestBuilderCubit.state;
    final result = await showRequestEditorSheet(
      context,
      title: AppStrings.requestsNewRequest,
      initialDraft: const RequestDraft(),
      variableStore: state.initialVariableStore ?? const RequestVariableStore(),
      onDraftChanged: (result) => requestBuilderCubit.saveCurrentDraftSession(
        title: result.title,
        draft: result.draft,
      ),
      onDraftDiscarded: requestBuilderCubit.discardCurrentDraftSession,
    );

    if (!context.mounted || result == null) {
      return;
    }

    await requestBuilderCubit.saveNewDraft(
      title: result.title,
      draft: result.draft,
    );
  }

  /// Selects a HAR file, then appends only its valid request entries.
  Future<void> _importHar(BuildContext context) async {
    final selection = await getIt<RequestTransferGateway>().selectHar();
    if (!context.mounted) {
      return;
    }
    switch (selection) {
      case HarSelectionCancelled():
        return;
      case HarSelectionFailure():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to import the HAR file.')),
        );
        return;
      case HarSelectionSuccess(:final content):
        try {
          final result = await context
              .read<RequestBuilderCubit>()
              .importHarContent(content);
          if (!context.mounted) {
            return;
          }
          switch (result) {
            case HarRequestImportSuccess(:final requests, :final skippedCount):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    skippedCount == 0
                        ? 'Imported ${requests.length} request(s).'
                        : 'Imported ${requests.length} request(s); skipped $skippedCount invalid entry(s).',
                  ),
                ),
              );
            case HarRequestImportFailure():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The selected file is not a valid HAR file.'),
                ),
              );
          }
        } catch (_) {
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to import the HAR file.')),
          );
        }
    }
  }

  /// Parses pasted cURL and opens the existing editor before any request is saved.
  Future<void> _importCurl(BuildContext context) async {
    final controller = TextEditingController();
    Future<void>? dialogClosed;
    final command = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        dialogClosed = ModalRoute.of(
          dialogContext,
        )?.completed.then<void>((_) {});

        return AlertDialog(
          title: const Text('Import cURL'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(hintText: 'Paste a curl command'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    // Keep the controller alive until the dialog's reverse transition unmounts its field.
    await (dialogClosed ?? Future<void>.value());
    controller.dispose();
    if (!context.mounted || command == null) {
      return;
    }

    final cubit = context.read<RequestBuilderCubit>();
    CurlParseResult parsed;
    try {
      parsed = cubit.importCurlCommand(command);
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a cURL command with an HTTP or HTTPS URL.'),
        ),
      );
      return;
    }
    final draft = parsed.draft;

    if (parsed.diagnostics.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some unsupported cURL options were ignored.'),
        ),
      );
    }

    final result = await showRequestEditorSheet(
      context,
      title: '${draft.method.wireName} ${draft.url}',
      initialDraft: draft,
      variableStore:
          cubit.state.initialVariableStore ?? const RequestVariableStore(),
    );
    if (result == null || cubit.isClosed) {
      return;
    }
    await cubit.saveNewDraft(title: result.title, draft: result.draft);
  }
}

class _WebSocketsShell extends StatelessWidget {
  const _WebSocketsShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  // Keep the WebSockets tab on the shared shell while leaving header actions disabled.
  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: AppShellTab.websockets,
    title: AppStrings.websocketsTabLabel,
    trailing: null,
    bottomSlot: const SearchWebsocket(),
    body: WebsocketScreen(),
    floatingActionButton: const WebSocketShellActionButton(),
    onTabSelected: onTabSelected,
  );
}

class _CollectionsShell extends StatelessWidget {
  const _CollectionsShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  /// Builds the Collections tab shell with its contextual header actions.
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CollectionCubit, CollectionState>(
        builder: (context, state) => AppShellScaffold(
          currentTab: AppShellTab.collections,
          title:
              state.selectedCollection?.name ?? AppStrings.collectionsTabLabel,
          leading: state.selectedCollection == null
              ? null
              : IconButton(
                  onPressed: () =>
                      context.read<CollectionCubit>().clearSelectedCollection(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
          trailing: const CollectionsMoreButton(),
          bottomSlot: state.selectedCollection == null
              ? const CollectionSearch()
              : null,
          body: const CollectionScreen(),
          floatingActionButton: state.selectedCollection == null
              ? const CollectionsShellActionButton()
              : null,
          onTabSelected: onTabSelected,
        ),
      );
}

class _PostmanShell extends StatelessWidget {
  const _PostmanShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  /// Builds the Postman tab shell with its contextual header actions.
  @override
  Widget build(BuildContext context) => BlocBuilder<PostmanCubit, PostmanState>(
    builder: (context, state) => AppShellScaffold(
      currentTab: AppShellTab.postman,
      title: state.selectedCollection?.name ?? AppStrings.postmanTabLabel,
      leading: state.selectedCollection == null
          ? null
          : IconButton(
              onPressed: () =>
                  context.read<PostmanCubit>().clearSelectedCollection(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
      trailing: const PostmanMoreButton(),
      bottomSlot: state.selectedCollection == null
          ? const PostmanSearch()
          : null,
      body: const PostmanScreen(),
      floatingActionButton: const PostmanShellActionButton(),
      onTabSelected: onTabSelected,
    ),
  );
}

class _SettingsShell extends StatelessWidget {
  const _SettingsShell({
    required this.onTabSelected,
    required this.onItemSelected,
  });

  final ValueChanged<AppShellTab> onTabSelected;
  final ValueChanged<String> onItemSelected;

  // Render the dedicated settings overview inside the shared application shell.
  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: AppShellTab.settings,
    title: AppStrings.settingsTitle,
    bodyHorizontalPadding: 0,
    body: SettingsPage(onItemSelected: onItemSelected),
    onTabSelected: onTabSelected,
  );
}

class _SettingsDetailShell extends StatelessWidget {
  const _SettingsDetailShell({
    required this.itemTitle,
    required this.onBack,
    required this.body,
    required this.onTabSelected,
    this.trailing,
    this.centerTitle = true,
    this.headerHeight,
  });

  final String itemTitle;
  final VoidCallback onBack;
  final Widget body;
  final ValueChanged<AppShellTab> onTabSelected;
  final Widget? trailing;
  final bool centerTitle;
  final double? headerHeight;

  // Keep placeholder settings destinations inside the shared shell and preserve back navigation.
  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: AppShellTab.settings,
    title: itemTitle,
    leading: _SettingsBackButton(onPressed: onBack),
    trailing: trailing,
    centerTitle: centerTitle,
    headerHeight: headerHeight,
    body: body,
    onTabSelected: onTabSelected,
  );
}

class _RequestFavoriteButton extends StatelessWidget {
  const _RequestFavoriteButton();

  /// Toggles the Requests list favourites-only filter from the shared shell.
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RequestBuilderCubit, RequestBuilderState>(
        builder: (context, state) => IconButton(
          key: const ValueKey<String>(AppWidgetKeys.requestsFavoriteButton),
          tooltip: state.showFavouritesOnly
              ? AppStrings.requestsShowAllTooltip
              : AppStrings.requestsFavoriteTooltip,
          onPressed: context.read<RequestBuilderCubit>().toggleFavouritesOnly,
          icon: Icon(
            state.showFavouritesOnly
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: context.appColors.iconPrimary,
          ),
        ),
      );
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onPressed});

  final VoidCallback onPressed;

  // Expose an in-shell back action for pushed settings detail placeholders.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return IconButton(
      key: const ValueKey<String>(AppWidgetKeys.settingsBackButton),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed,
      icon: Icon(Icons.arrow_back_rounded, color: colors.iconPrimary),
    );
  }
}
