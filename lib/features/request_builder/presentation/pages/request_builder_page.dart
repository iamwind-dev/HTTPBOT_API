import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/entities/requests_method.dart';
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
    Widget content = ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.xSmall,
        bottom: AppSpacing.xxxLarge + AppSpacing.medium,
      ),
      itemCount: state.visibleRequests.length,
      separatorBuilder: (_, _) => Divider(color: colors.divider, thickness: 1),
      itemBuilder: (context, index) => RequestListItemCard(
        key: ValueKey<String>(AppWidgetKeys.requestsListItemAt(index)),
        item: state.visibleRequests[index],
        onTap: () => _openRequestEditor(
          context,
          item: state.visibleRequests[index],
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

  /// Opens the tapped request in the modal editor while preserving list state underneath.
  void _openRequestEditor(
    BuildContext context, {
    required RequestListItem item,
    required RequestBuilderState state,
  }) {
    final draft = state.initialDraft;

    if (draft == null) {
      return;
    }

    showRequestEditorSheet(
      context,
      title: item.title,
      initialDraft: _buildDraftForListItem(item, draft),
      variableStore:
          state.initialVariableStore ?? const RequestVariableStore(),
    );
  }

  /// Merges the tapped list metadata into the persisted draft used as the editor baseline.
  RequestDraft _buildDraftForListItem(RequestListItem item, RequestDraft draft) =>
      draft.copyWith(
        method: _mapMethodLabel(item.method),
        url: item.url,
      );

  /// Maps the compact list method label back to the corresponding request method enum.
  HttpMethod _mapMethodLabel(String label) {
    for (final method in HttpMethod.values) {
      if (method.label == label) {
        return method;
      }
    }

    return HttpMethod.get;
  }
}
