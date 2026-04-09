import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_variable_store.dart';
import '../cubit/request_builder_cubit.dart';
import '../cubit/request_builder_state.dart';
import '../models/request_list_item.dart';
import '../widgets/request_empty_state.dart';
import '../widgets/request_editor_sheet.dart';
import '../widgets/request_list_item_card.dart';

class RequestBuilderPage extends StatelessWidget {
  const RequestBuilderPage({super.key});

  // Keep short request lists clear of the shell chrome across platforms.
  @override
  Widget build(BuildContext context) {
    final state = context.watch<RequestBuilderCubit>().state;
    final colors = context.appColors;
    final visibleEntries = state.requests
        .asMap()
        .entries
        .where((entry) => entry.value.matches(state.searchQuery))
        .toList(growable: false);
    Widget content = ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.xSmall,
        bottom: AppSpacing.xxxLarge + AppSpacing.medium,
      ),
      itemCount: visibleEntries.length,
      separatorBuilder: (_, _) => Divider(color: colors.divider, thickness: 1),
      itemBuilder: (context, index) => RequestListItemCard(
        key: ValueKey<String>(AppWidgetKeys.requestsListItemAt(index)),
        item: visibleEntries[index].value,
        onTap: () => _openRequestEditor(
          context,
          requestIndex: visibleEntries[index].key,
          item: visibleEntries[index].value,
          state: state,
        ),
        onActionSelected: (action) => _handleRequestAction(
          context,
          action: action,
          requestIndex: visibleEntries[index].key,
          item: visibleEntries[index].value,
          state: state,
        ),
      ),
    );

    if (state.isEmptyState) {
      content = const RequestEmptyState(
        title: AppStrings.requestsEmptyTitle,
        message: AppStrings.requestsEmptyMessage,
      );
    } else if (state.isNoResultsState) {
      content = const RequestEmptyState(
        title: AppStrings.requestsNoResultsTitle,
        message: AppStrings.requestsNoResultsMessage,
      );
    }

    return content;
  }

  Future<void> _handleRequestAction(
    BuildContext context, {
    required RequestListItemAction action,
    required int requestIndex,
    required RequestListItem item,
    required RequestBuilderState state,
  }) async {
    switch (action) {
      case RequestListItemAction.edit:
        await _openRequestEditor(
          context,
          requestIndex: requestIndex,
          item: item,
          state: state,
        );
      case RequestListItemAction.duplicate:
        await context.read<RequestBuilderCubit>().duplicateRequest(
          requestIndex,
        );
      case RequestListItemAction.viewCurl:
        await context.read<RequestBuilderCubit>().viewCurl(requestIndex);
      case RequestListItemAction.exportHar:
        await context.read<RequestBuilderCubit>().exportHar(requestIndex);
      case RequestListItemAction.favourite:
        await context.read<RequestBuilderCubit>().toggleFavourite(requestIndex);
      case RequestListItemAction.delete:
        await context.read<RequestBuilderCubit>().deleteRequest(requestIndex);
    }
  }

  /// Opens the tapped request in the modal editor while preserving list state underneath.
  Future<void> _openRequestEditor(
    BuildContext context, {
    required int requestIndex,
    required RequestListItem item,
    required RequestBuilderState state,
  }) async {
    final draft = state.initialDraft;
    final savedRequest =
        requestIndex >= 0 && requestIndex < state.savedRequests.length
        ? state.savedRequests[requestIndex]
        : null;

    if (draft == null && savedRequest == null) {
      return;
    }

    final requestBuilderCubit = context.read<RequestBuilderCubit>();
    final updatedResult = await showRequestEditorSheet(
      context,
      title: savedRequest?.title ?? item.title,
      initialDraft: savedRequest?.draft ?? draft!,
      variableStore: state.initialVariableStore ?? const RequestVariableStore(),
      onDraftChanged: (result) => requestBuilderCubit.saveCurrentDraftSession(
        title: result.title,
        draft: result.draft,
        requestIndex: requestIndex,
      ),
      onDraftDiscarded: requestBuilderCubit.discardCurrentDraftSession,
    );

    if (!context.mounted || updatedResult == null) {
      return;
    }

    await requestBuilderCubit.saveEditedDraft(
      requestIndex: requestIndex,
      title: updatedResult.title,
      draft: updatedResult.draft,
    );
  }
}
