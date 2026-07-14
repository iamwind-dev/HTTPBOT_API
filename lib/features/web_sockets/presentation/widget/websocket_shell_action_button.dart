import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubits/web_socket_list_cubit.dart';
import '../screens/websocket_editor_sheet.dart';

class WebSocketShellActionButton extends StatelessWidget {
  const WebSocketShellActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FloatingActionButton(
      key: const ValueKey<String>(AppWidgetKeys.websocketsFab),
      heroTag: AppWidgetKeys.websocketsFab,
      tooltip: AppStrings.requestsAddTooltip,
      onPressed: () async {
        final listCubit = context.read<WebSocketListCubit>();
        final newRequest = await listCubit.createRequest();
        if (context.mounted) {
          showWebSocketEditorSheet(context, request: newRequest);
        }
      },
      backgroundColor: colors.primary,
      foregroundColor: colors.textOnPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded),
    );
  }
}
