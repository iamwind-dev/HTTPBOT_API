import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/core/help/help_article_page.dart';
import 'package:http_client/core/help/help_article_widgets.dart';
import 'package:http_client/core/keys/widget_keys.dart';
import 'package:http_client/core/theme/app_theme.dart';
import 'package:http_client/features/collection/presentation/widget/collections_more_button.dart';

void main() {
  testWidgets('opens Collections Help from header menu and renders article', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _openCollectionsHelp(tester);

    expect(
      find.byKey(
        ValueKey<String>(AppWidgetKeys.helpPage('collectionsFolders')),
      ),
      findsOneWidget,
    );
    expect(find.text('Collections & Folders'), findsWidgets);
    for (final heading in _importantHeadings) {
      expect(find.text(heading), findsOneWidget);
    }

    final scrollableFinder = find.descendant(
      of: find.byKey(
        ValueKey<String>(AppWidgetKeys.helpScrollView('collectionsFolders')),
      ),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(scrollableFinder);
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>(AppWidgetKeys.helpProBadge)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>(AppWidgetKeys.helpProCallout)),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);

    final firstLink = find.byType(HelpLink).first;
    await tester.ensureVisible(firstLink);
    await tester.pumpAndSettle();
    await tester.tap(firstLink);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>(AppWidgetKeys.helpCloseButton)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HelpArticlePage), findsNothing);
  });

  testWidgets('fits a small phone without header overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await _openCollectionsHelp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Browse all topics'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// Opens Collections Help through the same header menu used by the app.
Future<void> _openCollectionsHelp(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>(AppWidgetKeys.collectionsMoreButton)),
  );
  await tester.pumpAndSettle();
  expect(find.text('Help'), findsOneWidget);
  await tester.tap(
    find.byKey(const ValueKey<String>(AppWidgetKeys.collectionsHelpMenuAction)),
  );
  await tester.pumpAndSettle();
}

/// Builds the minimal themed navigator used by Collections Help widget tests.
Widget _testApp() {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: const [CollectionsMoreButton()],
      ),
    ),
  );
}

const _importantHeadings = [
  'What a Collection can hold',
  'Creating a Collection',
  'Adding requests and folders',
  'Searching',
  'Collection-level authentication & Inherit',
  'Request Documentation',
  'Two Collection areas: yours and Postman',
  'Related',
];
