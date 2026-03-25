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
  });
}

class _AppPageHeaderRobot {
  const _AppPageHeaderRobot(this.tester);

  final WidgetTester tester;

  Future<void> pumpHeader() async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppPageHeader(
            title: 'Requests',
            trailing: Icon(Icons.favorite_border_rounded),
            bottomSlot: Text('Search'),
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
}
