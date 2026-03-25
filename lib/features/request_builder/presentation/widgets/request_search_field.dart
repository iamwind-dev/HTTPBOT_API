import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/request_builder_cubit.dart';

class RequestSearchField extends StatelessWidget {
  const RequestSearchField({super.key});

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey<String>(AppWidgetKeys.requestsSearchField),
    onChanged: context.read<RequestBuilderCubit>().updateSearchQuery,
    textInputAction: TextInputAction.search,
    decoration: const InputDecoration(
      isDense: true,
      hintText: AppStrings.requestsSearchHint,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xxSmall,
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: AppSpacing.xxLarge,
        minHeight: AppSpacing.xxLarge,
      ),
      prefixIcon: Icon(Icons.search_rounded),
    ),
  );
}
