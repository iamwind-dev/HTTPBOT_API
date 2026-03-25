import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_page_header.dart';
import 'request_search_field.dart';

class RequestHeader extends StatelessWidget {
  const RequestHeader({super.key});

  static const height = AppPageHeader.defaultHeight;

  // Compose the shared shell with request-builder-specific content and actions.
  @override
  Widget build(BuildContext context) => const AppPageHeader(
    title: AppStrings.requestsTitle,
    trailing: _RequestFavoriteButton(),
    bottomSlot: RequestSearchField(),
  );
}

class _RequestFavoriteButton extends StatelessWidget {
  const _RequestFavoriteButton();

  // Preserve the request-builder action while delegating the shell layout to core.
  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey<String>(AppWidgetKeys.requestsFavoriteButton),
    tooltip: AppStrings.requestsFavoriteTooltip,
    onPressed: () {},
    icon: const Icon(
      Icons.favorite_border_rounded,
      color: AppColors.textPrimary,
    ),
  );
}
