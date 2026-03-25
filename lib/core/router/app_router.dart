import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/keys/widget_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_section_placeholder.dart';
import '../../core/widgets/app_shell_scaffold.dart';
import '../../features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../../features/request_builder/presentation/cubit/request_builder_cubit.dart';
import '../../features/request_builder/presentation/pages/request_builder_page.dart';
import '../../features/request_builder/presentation/widgets/request_search_field.dart';
import '../../features/request_builder/presentation/widgets/request_shell_action_button.dart';
import '../../injection/injection.dart';
import 'app_shell_tab.dart';

abstract final class AppRouter {
  static GoRouter createRouter({
    required GetRequestDraftUseCase getRequestDraftUseCase,
    String? initialLocation,
  }) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) => RequestBuilderCubit(getRequestDraftUseCase)..load(),
          child: _RequestsShell(
            onTabSelected: (tab) => context.go(tab.location),
          ),
        ),
      ),
      GoRoute(
        path: '/websockets',
        builder: (context, state) => _PlaceholderShell(
          currentTab: AppShellTab.websockets,
          onTabSelected: (tab) => context.go(tab.location),
        ),
      ),
      GoRoute(
        path: '/collections',
        builder: (context, state) => _PlaceholderShell(
          currentTab: AppShellTab.collections,
          onTabSelected: (tab) => context.go(tab.location),
        ),
      ),
      GoRoute(
        path: '/postman',
        builder: (context, state) => _PlaceholderShell(
          currentTab: AppShellTab.postman,
          onTabSelected: (tab) => context.go(tab.location),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _PlaceholderShell(
          currentTab: AppShellTab.settings,
          onTabSelected: (tab) => context.go(tab.location),
        ),
      ),
    ],
  );

  static final GoRouter router = createRouter(
    getRequestDraftUseCase: getIt<GetRequestDraftUseCase>(),
  );
}

class _RequestsShell extends StatelessWidget {
  const _RequestsShell({required this.onTabSelected});

  final ValueChanged<AppShellTab> onTabSelected;

  // Wrap the Requests content with the app-wide shell while keeping request state local.
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

class _PlaceholderShell extends StatelessWidget {
  const _PlaceholderShell({
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppShellTab currentTab;
  final ValueChanged<AppShellTab> onTabSelected;

  // Render non-request sections through the same app shell until their feature pages exist.
  @override
  Widget build(BuildContext context) => AppShellScaffold(
    currentTab: currentTab,
    title: currentTab.title,
    body: AppSectionPlaceholder(
      title: currentTab.title,
      message: AppStrings.sectionUnavailableMessage,
    ),
    onTabSelected: onTabSelected,
  );
}

class _RequestFavoriteButton extends StatelessWidget {
  const _RequestFavoriteButton();

  // Preserve the request-specific trailing action while the shell is now router-owned.
  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey<String>(AppWidgetKeys.requestsFavoriteButton),
    tooltip: AppStrings.requestsFavoriteTooltip,
    onPressed: () {},
    icon: const Icon(
      Icons.favorite_border_rounded,
      color: AppColors.textPrimary,
    ),
  );
}
