import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/app_popup_menu.dart';
import '../models/request_list_item.dart';

enum RequestListItemAction {
  edit,
  duplicate,
  viewCurl,
  exportHar,
  favourite,
  delete,
}

extension RequestListItemActionLabel on RequestListItemAction {
  String get label => switch (this) {
    RequestListItemAction.edit => 'Edit',
    RequestListItemAction.duplicate => 'Duplicate',
    RequestListItemAction.viewCurl => 'View curl',
    RequestListItemAction.exportHar => 'Export as HAR',
    RequestListItemAction.favourite => 'Favourite',
    RequestListItemAction.delete => 'Delete',
  };

  IconData get icon => switch (this) {
    RequestListItemAction.edit => CupertinoIcons.pencil,
    RequestListItemAction.duplicate => CupertinoIcons.doc_on_doc,
    RequestListItemAction.viewCurl =>
      CupertinoIcons.chevron_left_slash_chevron_right,
    RequestListItemAction.exportHar => CupertinoIcons.arrow_up_doc,
    RequestListItemAction.favourite => CupertinoIcons.star,
    RequestListItemAction.delete => CupertinoIcons.trash,
  };
}

class RequestListItemCard extends StatelessWidget {
  const RequestListItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onActionSelected,
  });

  final RequestListItem item;
  final ValueChanged<RequestListItemAction> onActionSelected;
  final VoidCallback onTap;

  /// Builds a tappable request summary card for the requests list.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
        splashFactory: NoSplash.splashFactory,
        highlightColor: colors.primarySoft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequestMethodBadge(method: item.method),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(item.url, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xSmall),
              _RequestListItemMoreButton(onSelected: onActionSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestListItemMoreButton extends StatelessWidget {
  const _RequestListItemMoreButton({required this.onSelected});

  final ValueChanged<RequestListItemAction> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<RequestListItemAction>(
    tooltip: 'More request actions',
    icon: const Icon(CupertinoIcons.ellipsis),
    constraints: const BoxConstraints(minWidth: 180),
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final action in RequestListItemAction.values) ...[
        if (action == RequestListItemAction.delete) const PopupMenuDivider(),
        PopupMenuItem<RequestListItemAction>(
          value: action,
          child: _RequestListItemActionRow(action: action),
        ),
      ],
    ],
  );
}

class _RequestListItemActionRow extends StatelessWidget {
  const _RequestListItemActionRow({required this.action});

  final RequestListItemAction action;

  @override
  Widget build(BuildContext context) => AppPopupMenuRow(
    icon: action.icon,
    label: action.label,
    destructive: action == RequestListItemAction.delete,
  );
}

class _RequestMethodBadge extends StatelessWidget {
  const _RequestMethodBadge({required this.method});

  final String method;

  // Keep every method badge aligned to a shared four-character width.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      width: AppSpacing.xxxLarge + AppSpacing.xSmall,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xSmall,
        vertical: AppSpacing.xxSmall,
      ),
      decoration: BoxDecoration(
        color: colors.methodColor(method),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(
        method,
        style: theme.textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
