import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../cubit/request_builder_cubit.dart';
import '../cubit/request_builder_state.dart';

class RequestBottomNavigation extends StatelessWidget {
  const RequestBottomNavigation({super.key});

  static const _items = <AppBottomNavigationItem<RequestBottomTab>>[
    AppBottomNavigationItem<RequestBottomTab>(
      value: RequestBottomTab.requests,
      icon: Icons.sync_alt_rounded,
      label: AppStrings.requestsTabLabel,
      widgetKey: AppWidgetKeys.requestsTab,
    ),
    AppBottomNavigationItem<RequestBottomTab>(
      value: RequestBottomTab.websockets,
      icon: Icons.compare_arrows_rounded,
      label: AppStrings.websocketsTabLabel,
      widgetKey: AppWidgetKeys.websocketsTab,
    ),
    AppBottomNavigationItem<RequestBottomTab>(
      value: RequestBottomTab.collections,
      icon: Icons.folder_rounded,
      label: AppStrings.collectionsTabLabel,
      widgetKey: AppWidgetKeys.collectionsTab,
    ),
    AppBottomNavigationItem<RequestBottomTab>(
      value: RequestBottomTab.postman,
      icon: Icons.adjust_rounded,
      label: AppStrings.postmanTabLabel,
      widgetKey: AppWidgetKeys.postmanTab,
    ),
    AppBottomNavigationItem<RequestBottomTab>(
      value: RequestBottomTab.settings,
      icon: Icons.settings_rounded,
      label: AppStrings.settingsTabLabel,
      widgetKey: AppWidgetKeys.settingsTab,
    ),
  ];

  // Bridge the request-builder tab state into the shared bottom navigation shell.
  @override
  Widget build(BuildContext context) {
    final selectedTab = context.select(
      (RequestBuilderCubit cubit) => cubit.state.selectedTab,
    );

    return AppBottomNavigation<RequestBottomTab>(
      items: _items,
      selectedValue: selectedTab,
      onItemSelected: context.read<RequestBuilderCubit>().showPlaceholderTab,
    );
  }
}
