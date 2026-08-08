import 'package:flutter/material.dart';

import '../../features/collection/presentation/model/collections_help_article.dart';
import '../../features/postman/presentation/model/postman_sync_help_article.dart';
import '../help/help_article.dart';
import '../help/help_article_page.dart';
import '../help/help_topic.dart';

abstract final class HelpRouter {
  /// Opens a registered article or safely reports an unfinished topic.
  static Future<void> open(BuildContext context, HelpTopic topic) async {
    final article = _articleFor(topic);
    if (article == null) {
      _showUnavailable(context, topic);
      return;
    }

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (pageContext) => HelpArticlePage(
          article: article,
          onTopicSelected: (nextTopic) => open(pageContext, nextTopic),
        ),
      ),
    );
  }

  /// Resolves the structured article registered for a Help topic.
  static HelpArticle? _articleFor(HelpTopic topic) => switch (topic) {
    HelpTopic.collectionsFolders => collectionsHelpArticle,
    HelpTopic.postmanSync => postmanSyncHelpArticle,
    _ => null,
  };

  /// Keeps links to future Help articles tappable without throwing.
  static void _showUnavailable(BuildContext context, HelpTopic topic) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${topic.label} documentation is coming soon.')),
      );
  }
}
