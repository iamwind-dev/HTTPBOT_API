import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubits/web_socket_list_cubit.dart';

class SearchWebsocket extends StatelessWidget {
  const SearchWebsocket({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextField(
      key: const ValueKey<String>(AppWidgetKeys.requestsSearchField),
      onChanged: context.read<WebSocketListCubit>().updateSearchQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: AppStrings.requestsSearchHint,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide.none,
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide.none,
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xxSmall,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppSpacing.xxLarge,
          minHeight: AppSpacing.xxLarge,
        ),
        fillColor: colors.card,
        prefixIcon: Icon(Icons.search_rounded, color: colors.iconSecondary),
      ),
    );
  }
}
