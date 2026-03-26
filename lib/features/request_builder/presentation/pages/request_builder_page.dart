import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubit/request_builder_cubit.dart';
import '../cubit/request_builder_state.dart';
import '../models/request_list_item.dart';
import '../models/request_editor_sheet_data.dart';
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
      data: RequestEditorSheetData.fromRequest(item: item, draft: draft),
    );
  }
}
