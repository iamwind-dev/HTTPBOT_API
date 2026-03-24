import 'package:flutter_test/flutter_test.dart';

import 'package:httpbot_api/injection/injection.dart';
import 'package:httpbot_api/main.dart';

void main() {
  testWidgets('should show request builder screen when app boots', (
    WidgetTester tester,
  ) async {
    configureDependencies();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('HTTPBot API'), findsOneWidget);
    expect(find.text('Request Builder'), findsOneWidget);
  });
}
