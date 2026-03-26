import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:httpbot_api/core/theme/app_theme.dart';
import 'package:httpbot_api/core/widgets/app_page_header.dart';

void main() {
  group('AppPageHeader', () {
    testWidgets(
      'should render centered title with trailing and bottom slots when provided',
      (tester) async {
        final robot = _AppPageHeaderRobot(tester);

        await robot.pumpHeader();

        robot.expectTitleVisible();
        robot.expectTrailingIconVisible();
        robot.expectBottomSlotVisible();
      },
    );

    testWidgets(
      'should keep the title horizontally centered when only a leading action is shown',
      (tester) async {
        final robot = _AppPageHeaderRobot(tester);

        await robot.pumpHeader(
          title: 'Settings',
          leading: const Icon(Icons.arrow_back_rounded),
        );

        robot.expectTitleCentered('Settings');
      },
    );

    testWidgets(
      'should keep the title horizontally centered when only a trailing action is shown',
      (tester) async {
        final robot = _AppPageHeaderRobot(tester);

        await robot.pumpHeader(
          title: 'Requests',
          trailing: const Icon(Icons.favorite_border_rounded),
        );

        robot.expectTitleCentered('Requests');
      },
    );

    testWidgets(
      'should use a more compact header height when no bottom slot is shown',
      (tester) async {
        final robot = _AppPageHeaderRobot(tester);

        await robot.pumpHeader(
          title: 'Settings',
          trailing: null,
          bottomSlot: null,
        );

        robot.expectHeaderHeightLessThan(AppPageHeader.defaultHeight);
      },
    );
  });
}

class _AppPageHeaderRobot {
  const _AppPageHeaderRobot(this.tester);

  final WidgetTester tester;

  Future<void> pumpHeader({
    String title = 'Requests',
    Widget? leading,
    Widget? trailing = const Icon(Icons.favorite_border_rounded),
    Widget? bottomSlot = const Text('Search'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppPageHeader(
            title: title,
            leading: leading,
            trailing: trailing,
            bottomSlot: bottomSlot,
          ),
        ),
      ),
    );
  }

  void expectTitleVisible() {
    expect(find.text('Requests'), findsOneWidget);
  }

  void expectTrailingIconVisible() {
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  }

  void expectBottomSlotVisible() {
    expect(find.text('Search'), findsOneWidget);
  }

  void expectTitleCentered(String title) {
    final headerCenter = tester.getCenter(find.byType(AppPageHeader));
    final titleCenter = tester.getCenter(find.text(title));

    expect(titleCenter.dx, closeTo(headerCenter.dx, 1));
  }

  void expectHeaderHeightLessThan(double height) {
    final headerHeight = tester.getSize(find.byType(AppPageHeader)).height;

    expect(headerHeight, lessThan(height));
  }
}
