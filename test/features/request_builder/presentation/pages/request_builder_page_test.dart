import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/core/keys/widget_keys.dart';
import 'package:httpbot_api/core/router/app_shell_tab.dart';
import 'package:httpbot_api/core/theme/app_theme.dart';
import 'package:httpbot_api/core/widgets/app_shell_scaffold.dart';
import 'package:httpbot_api/features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import 'package:httpbot_api/features/request_builder/presentation/cubit/request_builder_cubit.dart';
import 'package:httpbot_api/features/request_builder/presentation/models/request_list_item.dart';
import 'package:httpbot_api/features/request_builder/presentation/pages/request_builder_page.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/request_search_field.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/request_shell_action_button.dart';

import '../../../../shared/fakes/fake_request_builder_repository.dart';

void main() {
  group('RequestBuilderPage', () {
    testWidgets('renders the requests screen with seeded request items', (
      tester,
    ) async {
      final robot = _RequestBuilderPageRobot(tester);

      await robot.pumpScreen();

      robot.expectMethodVisible('GET');
      robot.expectMethodVisible('POST');
      robot.expectUrlVisible('https://api.example.com/users');
    });

    testWidgets('filters visible requests by url metadata', (tester) async {
      final robot = _RequestBuilderPageRobot(tester);

      await robot.pumpScreen();
      await robot.enterSearchText('users');

      robot.expectUrlVisible('https://api.example.com/users');
      robot.expectUrlNotVisible('https://api.example.com/posts');
    });

    testWidgets('shows an empty state when no requests are available', (
      tester,
    ) async {
      final robot = _RequestBuilderPageRobot(tester);

      await robot.pumpScreen(seedRequests: const []);

      robot.expectEmptyStateVisible();
      robot.expectEmptyStateMessageVisible();
    });

    testWidgets('shows a no results state when search does not match', (
      tester,
    ) async {
      final robot = _RequestBuilderPageRobot(tester);

      await robot.pumpScreen();
      await robot.enterSearchText('missing-value');

      robot.expectNoResultsStateVisible();
      robot.expectNoResultsMessageVisible();
    });

    testWidgets(
      'keeps app shell search and add action visible on android-sized layouts',
      (tester) async {
        final robot = _RequestBuilderPageRobot(tester);

        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await robot.pumpScreen();

        robot.expectSearchVisible();
        robot.expectFabVisible();
      },
    );

    testWidgets(
      'keeps a single request card below the shell header while overscrolling',
      (tester) async {
        final robot = _RequestBuilderPageRobot(tester);

        await robot.pumpScreen(
          platform: TargetPlatform.iOS,
          seedRequests: const [
            RequestListItem(
              method: 'GET',
              title: 'Only request',
              url: 'https://api.example.com/users',
            ),
          ],
        );
        await robot.dragShortList();

        robot.expectRequestCardBelowHeader('Only request');
      },
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.cubit, this.platform});

  final RequestBuilderCubit cubit;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: platform == null
        ? AppTheme.lightTheme
        : AppTheme.lightTheme.copyWith(platform: platform),
    home: BlocProvider.value(
      value: cubit,
      child: AppShellScaffold(
        currentTab: AppShellTab.requests,
        title: 'Requests',
        body: const RequestBuilderPage(),
        bottomSlot: const RequestSearchField(),
        floatingActionButton: const RequestShellActionButton(),
        onTabSelected: (_) {},
      ),
    ),
  );
}

class _RequestBuilderPageRobot {
  const _RequestBuilderPageRobot(this.tester);

  final WidgetTester tester;

  Future<void> pumpScreen({
    List<RequestListItem>? seedRequests,
    TargetPlatform? platform,
  }) async {
    await tester.pumpWidget(
      _TestApp(
        platform: platform,
        cubit: RequestBuilderCubit(
          GetRequestDraftUseCase(const FakeRequestBuilderRepository()),
          seedRequests: seedRequests,
        )..load(),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> dragShortList() async {
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();
  }

  Future<void> enterSearchText(String value) async {
    await tester.enterText(
      find.byKey(const ValueKey<String>(AppWidgetKeys.requestsSearchField)),
      value,
    );
    await tester.pumpAndSettle();
  }

  void expectTitleVisible() {
    expect(find.text('Requests'), findsWidgets);
  }

  void expectSearchVisible() {
    expect(find.text('Search'), findsOneWidget);
  }

  void expectMethodVisible(String method) {
    expect(find.text(method), findsAtLeastNWidgets(1));
  }

  void expectUrlVisible(String url) {
    expect(find.text(url), findsAtLeastNWidgets(1));
  }

  void expectUrlNotVisible(String url) {
    expect(find.text(url), findsNothing);
  }

  void expectFavoriteActionVisible() {
    expect(find.byType(RequestShellActionButton), findsOneWidget);
  }

  void expectFabVisible() {
    expect(find.byType(FloatingActionButton), findsOneWidget);
  }

  void expectEmptyStateVisible() {
    expect(find.text('No requests yet'), findsOneWidget);
  }

  void expectEmptyStateMessageVisible() {
    expect(
      find.text('Create your first request to start testing APIs.'),
      findsOneWidget,
    );
  }

  void expectNoResultsStateVisible() {
    expect(find.text('No matching requests'), findsOneWidget);
  }

  void expectNoResultsMessageVisible() {
    expect(
      find.text('Try a different search term or create a new request.'),
      findsOneWidget,
    );
  }

  void expectRequestCardBelowHeader(String title) {
    final headerBottom = tester.getBottomLeft(find.text('Search')).dy;
    final titleTop = tester.getTopLeft(find.text(title)).dy;

    expect(titleTop, greaterThanOrEqualTo(headerBottom));
  }
}
