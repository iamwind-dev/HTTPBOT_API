import 'package:flutter/material.dart';

import '../../../../core/help/help_topic.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/router/help_router.dart';
import '../../../../core/theme/app_theme_context.dart';

enum PostmanHeaderAction { help }

class PostmanMoreButton extends StatelessWidget {
  const PostmanMoreButton({super.key});

  /// Opens the Postman header menu and handles its selected action.
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PostmanHeaderAction>(
      key: const ValueKey<String>(AppWidgetKeys.postmanMoreButton),
      tooltip: 'More Postman actions',
      icon: Icon(
        Icons.more_horiz_rounded,
        color: context.appColors.iconPrimary,
      ),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (_) => const [
        PopupMenuItem<PostmanHeaderAction>(
          key: ValueKey<String>(AppWidgetKeys.postmanHelpMenuAction),
          value: PostmanHeaderAction.help,
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

  /// Opens Postman Sync Help after the popup route has closed.
  void _handleAction(BuildContext context, PostmanHeaderAction action) {
    switch (action) {
      case PostmanHeaderAction.help:
        HelpRouter.open(context, HelpTopic.postmanSync);
    }
  }
}
