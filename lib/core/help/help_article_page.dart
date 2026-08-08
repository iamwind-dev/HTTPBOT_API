import 'package:flutter/material.dart';

import '../keys/widget_keys.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_context.dart';
import 'help_article.dart';
import 'help_article_widgets.dart';
import 'help_topic.dart';

class HelpArticlePage extends StatelessWidget {
  const HelpArticlePage({
    super.key,
    required this.article,
    required this.onTopicSelected,
  });

  final HelpArticle article;
  final ValueChanged<HelpTopic> onTopicSelected;

  /// Builds the shared full-screen documentation article layout.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey<String>(AppWidgetKeys.helpPage(article.topic.name)),
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _HelpHeader(
              title: article.title,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey<String>(
                  AppWidgetKeys.helpScrollView(article.topic.name),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  AppSpacing.large,
                  AppSpacing.medium,
                  AppSpacing.xxxLarge,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: HelpArticleBody(
                      article: article,
                      onTopicTap: onTopicSelected,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  /// Builds the same responsive Help header for every article topic.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final closeButton = Material(
      color: colors.headerActionSurface,
      shape: const CircleBorder(),
      child: IconButton(
        key: const ValueKey<String>(AppWidgetKeys.helpCloseButton),
        tooltip: 'Close Help',
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
      ),
    );
    final titleWidget = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          closeButton,
          const SizedBox(width: AppSpacing.small),
          Expanded(child: titleWidget),
        ],
      ),
    );
  }
}
