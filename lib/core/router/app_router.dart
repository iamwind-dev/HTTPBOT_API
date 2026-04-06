import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/keys/widget_keys.dart';
import '../../core/theme/app_theme_context.dart';
import '../../core/widgets/app_section_placeholder.dart';
import '../../core/widgets/app_shell_scaffold.dart';
import '../../features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../../features/request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import '../../features/request_builder/presentation/cubit/request_builder_cubit.dart';
import '../../features/request_builder/presentation/pages/request_builder_page.dart';
import '../../features/request_builder/presentation/widgets/request_search_field.dart';
import '../../features/request_builder/presentation/widgets/request_shell_action_button.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/models/settings_catalog.dart';
import '../../features/settings/presentation/pages/settings_detail_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../injection/injection.dart';
import 'app_shell_tab.dart';

abstract final class AppRouter {
  /// Creates the application router with stateful tab branches so each tab preserves its stack.
  static GoRouter createRouter({
    required GetRequestDraftUseCase getRequestDraftUseCase,
    required GetRequestVariableStoreUseCase getRequestVariableStoreUseCase,
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
                builder: (context, state) => _WebSocketsShell(
                  onTabSelected: (tab) =>
                      _handleShellTabSelection(context, tab),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/collections',
                builder: (context, state) => _CollectionsShell(
                  onTabSelected: (tab) =>
                      _handleShellTabSelection(context, tab),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/postman',
                builder: (context, state) => _PostmanShell(
                  onTabSelected: (tab) =>
                      _handleShellTabSelection(context, tab),
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
                      final item = SettingsCatalog.findItemById(
                        state.pathParameters['itemId'] ?? '',
                      );

                      return _SettingsDetailShell(
                        itemTitle: item?.title ?? AppStrings.settingsTitle,
                        onBack: () => _handleSettingsBack(context),
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
    floatingActionButton: const RequestShellActionButton(),
    onTabSelected: onTabSelected,
  );
}

class _WebSocketsShell extends StatelessWidget {
  const _WebSocketsShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  // Keep the WebSockets tab on the shared shell while leaving header actions disabled.
  @override
  Widget build(BuildContext context) => _StaticTabShell(
    currentTab: AppShellTab.websockets,
    title: AppStrings.websocketsTabLabel,
    message: AppStrings.sectionUnavailableMessage,
    onTabSelected: onTabSelected,
  );
}

class _CollectionsShell extends StatelessWidget {
  const _CollectionsShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  // Keep the Collections tab on the shared shell while leaving header actions disabled.
  @override
  Widget build(BuildContext context) => _StaticTabShell(
    currentTab: AppShellTab.collections,
    title: AppStrings.collectionsTabLabel,
    message: AppStrings.sectionUnavailableMessage,
    onTabSelected: onTabSelected,
  );
}

class _PostmanShell extends StatelessWidget {
  const _PostmanShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  // Keep the Postman tab on the shared shell while leaving header actions disabled.
  @override
  Widget build(BuildContext context) => _StaticTabShell(
    currentTab: AppShellTab.postman,
    title: AppStrings.postmanTabLabel,
    message: AppStrings.sectionUnavailableMessage,
    onTabSelected: onTabSelected,
  );
}

class _StaticTabShell extends StatelessWidget {
  const _StaticTabShell({
    required this.currentTab,
    required this.title,
    required this.message,
    required this.onTabSelected,
  });

  final AppShellTab currentTab;
  final String title;
  final String message;
  final ValueChanged<AppShellTab> onTabSelected;

  // Provide the same shell structure as Requests while allowing screens to omit header actions.
  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: currentTab,
    title: title,
    body: AppSectionPlaceholder(title: title, message: message),
    onTabSelected: onTabSelected,
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
    required this.onTabSelected,
  });

  final String itemTitle;
  final VoidCallback onBack;
  final ValueChanged<AppShellTab> onTabSelected;

  // Keep placeholder settings destinations inside the shared shell and preserve back navigation.
  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: AppShellTab.settings,
    title: itemTitle,
    leading: _SettingsBackButton(onPressed: onBack),
    body: const SettingsDetailPage(),
    onTabSelected: onTabSelected,
  );
}

class _RequestFavoriteButton extends StatelessWidget {
  const _RequestFavoriteButton();

  // Preserve the request-specific trailing action while the shell is now router-owned.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return IconButton(
      key: const ValueKey<String>(AppWidgetKeys.requestsFavoriteButton),
      tooltip: AppStrings.requestsFavoriteTooltip,
      onPressed: () {},
      icon: Icon(Icons.favorite_border_rounded, color: colors.iconPrimary),
    );
  }
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
