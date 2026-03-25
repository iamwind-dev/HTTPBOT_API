import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:httpbot_api/core/keys/widget_keys.dart';
import 'package:httpbot_api/injection/injection.dart';
import 'package:httpbot_api/main.dart';

void main() {
  testWidgets('should show requests screen when app boots', (
    WidgetTester tester,
  ) async {
    configureDependencies();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Requests'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>(AppWidgetKeys.requestsFab)),
      findsOneWidget,
    );
  });
}
