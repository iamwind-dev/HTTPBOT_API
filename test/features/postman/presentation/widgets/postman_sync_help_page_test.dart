import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/core/help/help_article_page.dart';
import 'package:http_client/core/help/help_article_widgets.dart';
import 'package:http_client/core/keys/widget_keys.dart';
import 'package:http_client/core/theme/app_theme.dart';
import 'package:http_client/features/postman/presentation/widget/postman_more_button.dart';

void main() {
  testWidgets('opens Postman Sync Help from the Postman header menu', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(
      find.byKey(const ValueKey<String>(AppWidgetKeys.postmanMoreButton)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Help'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>(AppWidgetKeys.postmanHelpMenuAction)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>(AppWidgetKeys.helpPage('postmanSync'))),
      findsOneWidget,
    );
    expect(find.text('Postman Sync'), findsNWidgets(2));
    expect(find.text('Connecting an account'), findsOneWidget);
    expect(find.text('Unlinking'), findsOneWidget);
    expect(find.text('Related'), findsOneWidget);
    _expectArticleText(tester, 'Nothing is synced until you import it');
    _expectArticleText(tester, 'Collections');
    _expectArticleText(tester, 'Environments');
    _expectArticleText(tester, 'Import from Postman...');
    _expectArticleText(tester, 'Settings → Postman Account');
    expect(find.text('Importing'), findsWidgets);
    expect(find.text('Collections & Folders'), findsWidgets);
    expect(find.text('Environments & Variables'), findsWidgets);
    expect(find.byType(Image), findsNothing);

    final scrollableFinder = find.descendant(
      of: find.byKey(
        ValueKey<String>(AppWidgetKeys.helpScrollView('postmanSync')),
      ),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(scrollableFinder);
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));
    scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
    await tester.pump();
    expect(
      scrollableState.position.pixels,
      moreOrLessEquals(scrollableState.position.maxScrollExtent),
    );

    final firstLink = find.byType(HelpLink).first;
    await tester.ensureVisible(firstLink);
    await tester.pumpAndSettle();
    await tester.tap(firstLink);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    expect(find.text('Browse all topics'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>(AppWidgetKeys.helpCloseButton)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HelpArticlePage), findsNothing);
  });
}

/// Verifies text that may be split across rich inline article spans.
void _expectArticleText(WidgetTester tester, String text) {
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().contains(text),
    ),
    findsWidgets,
  );
}

/// Builds a minimal Postman header using the production menu component.
Widget _testApp() {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Postman'),
        actions: const [PostmanMoreButton()],
      ),
    ),
  );
}
