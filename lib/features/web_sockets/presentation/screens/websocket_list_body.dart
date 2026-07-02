import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../generated/assets.gen.dart';
import '../../domain/entities/web_socket_request_entity.dart';
import '../cubits/web_socket_list_cubit.dart';
import 'websocket_editor_sheet.dart';

class WebSocketListBody extends StatelessWidget {
  const WebSocketListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return BlocBuilder<WebSocketListCubit, WebSocketListState>(
      builder: (context, state) {
        if (state.isEmptyState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: 64,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'No WebSocket Requests',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Tap the + button to create your first WebSocket request.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final visibleRequests = state.filteredRequests;

        if (visibleRequests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 64,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'No Matching Requests',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Try a different search query.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          key: const ValueKey<String>(AppWidgetKeys.websocketsList),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppSpacing.xxxSmall,
            bottom: AppSpacing.xxxLarge + AppSpacing.medium,
          ),
          itemCount: visibleRequests.length,
          separatorBuilder: (context, index) => Divider(
            color: colors.divider.withValues(alpha: 0.5),
            thickness: 0.5,
            indent: AppSpacing.xxxLarge + AppSpacing.medium,
          ),
          itemBuilder: (context, index) {
            final request = visibleRequests[index];
            return _WebSocketItemRow(
              request: request,
              onTap: () => _openRequest(context, request),
              onDelete: () => context
                  .read<WebSocketListCubit>()
                  .deleteRequest(request.id),
            );
          },
        );
      },
    );
  }

  void _openRequest(BuildContext context, WebSocketRequestEntity request) {
    // Open the bottom editor sheet with the selected request.
    showWebSocketEditorSheet(
      context,
      request: request,
    );
  }
}

class _WebSocketItemRow extends StatelessWidget {
  const _WebSocketItemRow({
    required this.request,
    required this.onTap,
    required this.onDelete,
  });

  final WebSocketRequestEntity request;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(request.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        color: colors.methodDelete,
        child: const Icon(
          CupertinoIcons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.xxSmall,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Assets.icons.websocketIc.svg(
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          title: Text(
            request.name.isNotEmpty ? request.name : 'Untitled Request',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            request.url.isNotEmpty ? request.url : 'wss://',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
