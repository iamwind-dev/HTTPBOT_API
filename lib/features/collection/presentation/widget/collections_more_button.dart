import 'package:flutter/material.dart';

import '../../../../../core/keys/widget_keys.dart';
import '../../../../../core/help/help_topic.dart';
import '../../../../../core/router/help_router.dart';
import '../../../../../core/theme/app_theme_context.dart';

enum CollectionsHeaderAction { help }

class CollectionsMoreButton extends StatelessWidget {
  const CollectionsMoreButton({super.key});

  /// Opens the Collections header menu and handles its selected action.
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CollectionsHeaderAction>(
      key: const ValueKey<String>(AppWidgetKeys.collectionsMoreButton),
      tooltip: 'More Collections actions',
      icon: Icon(
        Icons.more_horiz_rounded,
        color: context.appColors.iconPrimary,
      ),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (_) => const [
        PopupMenuItem<CollectionsHeaderAction>(
          key: ValueKey<String>(AppWidgetKeys.collectionsHelpMenuAction),
          value: CollectionsHeaderAction.help,
          child: Row(
            children: [
              Icon(Icons.help_outline_rounded),
              SizedBox(width: 12),
              Text('Help'),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens Help after the popup route has dismissed itself.
  void _handleAction(BuildContext context, CollectionsHeaderAction action) {
    switch (action) {
      case CollectionsHeaderAction.help:
        HelpRouter.open(context, HelpTopic.collectionsFolders);
    }
  }
}
