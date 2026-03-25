import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/request_builder_cubit.dart';
import '../cubit/request_builder_state.dart';
import '../widgets/request_bottom_navigation.dart';
import '../widgets/request_empty_state.dart';
import '../widgets/request_header.dart';
import '../widgets/request_list_item_card.dart';
import '../widgets/request_shell_action_button.dart';

class RequestBuilderPage extends StatelessWidget {
  const RequestBuilderPage({super.key});

  static const _headerTopInset = AppSpacing.xxSmall;

  // Let the request list scroll underneath the fading header overlay.
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: const RequestShellActionButton(),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    bottomNavigationBar: const RequestBottomNavigation(),
    body: SafeArea(
      child: BlocListener<RequestBuilderCubit, RequestBuilderState>(
        listenWhen: (previous, current) =>
            previous.placeholderTab != current.placeholderTab &&
            current.placeholderTab != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(AppStrings.requestsSoonMessage)),
            );

          context.read<RequestBuilderCubit>().clearPlaceholderTab();
        },
        child: BlocBuilder<RequestBuilderCubit, RequestBuilderState>(
          builder: (context, state) {
            Widget content = ListView.separated(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.xxxLarge + AppSpacing.xLarge,
              ),
              itemCount: state.visibleRequests.length,
              separatorBuilder: (_, _) => const Divider(
                height: AppSpacing.large,
                thickness: 1,
                color: AppColors.border,
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

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: _headerTopInset + RequestHeader.height,
                    ),
                    child: content,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: _headerTopInset),
                    child: RequestHeader(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
