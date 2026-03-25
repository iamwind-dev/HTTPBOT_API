import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/core/keys/widget_keys.dart';
import 'package:httpbot_api/core/theme/app_theme.dart';
import 'package:httpbot_api/features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import 'package:httpbot_api/features/request_builder/presentation/cubit/request_builder_cubit.dart';
import 'package:httpbot_api/features/request_builder/presentation/models/request_list_item.dart';
import 'package:httpbot_api/features/request_builder/presentation/pages/request_builder_page.dart';

import '../../../../shared/fakes/fake_request_builder_repository.dart';

void main() {
  group('RequestBuilderPage', () {
    testWidgets('renders the requests screen with seeded request items', (
      tester,
    ) async {
      final robot = _RequestBuilderPageRobot(tester);

      await robot.pumpScreen();

      robot.expectTitleVisible();
      robot.expectSearchVisible();
      robot.expectMethodVisible('GET');
      robot.expectMethodVisible('POST');
      robot.expectUrlVisible('https://api.example.com/users');
      robot.expectFavoriteActionVisible();
      robot.expectFabVisible();
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
      'keeps bottom navigation and add action visible on android-sized layouts',
      (tester) async {
        final robot = _RequestBuilderPageRobot(tester);

        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await robot.pumpScreen();

        robot.expectFabVisible();
        robot.expectTabVisible(AppWidgetKeys.requestsTab);
        robot.expectTabVisible(AppWidgetKeys.settingsTab);
      },
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.cubit});

  final RequestBuilderCubit cubit;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: BlocProvider.value(value: cubit, child: const RequestBuilderPage()),
  );
}

class _RequestBuilderPageRobot {
  const _RequestBuilderPageRobot(this.tester);

  final WidgetTester tester;

  Future<void> pumpScreen({
    List<RequestListItem>? seedRequests,
  }) async {
    await tester.pumpWidget(
      _TestApp(
        cubit: RequestBuilderCubit(
          GetRequestDraftUseCase(const FakeRequestBuilderRepository()),
          seedRequests: seedRequests,
        )..load(),
      ),
    );

    await tester.pumpAndSettle();
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
    expect(find.text(method), findsOneWidget);
  }

  void expectUrlVisible(String url) {
    expect(find.text(url), findsOneWidget);
  }

  void expectUrlNotVisible(String url) {
    expect(find.text(url), findsNothing);
  }

  void expectFavoriteActionVisible() {
    expect(
      find.byKey(const ValueKey<String>(AppWidgetKeys.requestsFavoriteButton)),
      findsOneWidget,
    );
  }

  void expectFabVisible() {
    expect(
      find.byKey(const ValueKey<String>(AppWidgetKeys.requestsFab)),
      findsOneWidget,
    );
  }

  void expectTabVisible(String widgetKey) {
    expect(find.byKey(ValueKey<String>(widgetKey)), findsOneWidget);
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
}
