import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/request_builder_cubit.dart';
import '../widgets/request_empty_state.dart';
import '../widgets/request_list_item_card.dart';

class RequestBuilderPage extends StatelessWidget {
  const RequestBuilderPage({super.key});

  // Keep short request lists clear of the shell chrome across platforms.
  @override
  Widget build(BuildContext context) {
    final state = context.watch<RequestBuilderCubit>().state;
    Widget content = ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.xSmall,
        bottom: AppSpacing.xxxLarge + AppSpacing.medium,
      ),
      itemCount: state.visibleRequests.length,
      separatorBuilder: (_, _) => const Divider(
        color: AppColors.border,
        thickness: 1,
      ),
      itemBuilder: (context, index) =>
          RequestListItemCard(item: state.visibleRequests[index]),
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
}
