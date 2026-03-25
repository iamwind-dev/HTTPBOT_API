import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:httpbot_api/core/theme/app_theme.dart';
import 'package:httpbot_api/core/widgets/app_bottom_navigation.dart';

void main() {
  group('AppBottomNavigation', () {
    testWidgets(
      'should render items and report taps when a new item is selected',
      (tester) async {
        final robot = _AppBottomNavigationRobot(tester);

        await robot.pumpNavigation();
        await robot.tapSettings();

        robot.expectSettingsSelection();
      },
    );
  });
}

class _AppBottomNavigationRobot {
  _AppBottomNavigationRobot(this.tester);

  final WidgetTester tester;
  int? selectedValue;

  Future<void> pumpNavigation() async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigation<int>(
            items: const [
              AppBottomNavigationItem<int>(
                value: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                widgetKey: 'home',
              ),
              AppBottomNavigationItem<int>(
                value: 1,
                icon: Icons.settings_rounded,
                label: 'Settings',
                widgetKey: 'settings',
              ),
            ],
            selectedValue: 0,
            onItemSelected: (value) => selectedValue = value,
          ),
        ),
      ),
    );
  }

  Future<void> tapSettings() async {
    await tester.tap(find.byKey(const ValueKey<String>('settings')));
    await tester.pumpAndSettle();
  }

  void expectSettingsSelection() {
    expect(selectedValue, 1);
  }
}
