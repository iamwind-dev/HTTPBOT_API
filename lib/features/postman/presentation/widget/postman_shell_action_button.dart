import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubit/postman_cubit.dart';
import 'link_postman_bottom_sheet_body.dart';
import 'workspace_collection_picker_screen.dart';

class PostmanShellActionButton extends StatelessWidget {
  const PostmanShellActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FloatingActionButton(
      key: const ValueKey<String>(AppWidgetKeys.postmanFab),
      heroTag: AppWidgetKeys.postmanFab,
      tooltip: AppStrings.requestsAddTooltip,
      onPressed: () => _handlePressed(context),
      backgroundColor: colors.methodGet,
      foregroundColor: colors.textOnPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded),
    );
  }

  /// Continues the import flow with a saved key or asks for a new key.
  Future<void> _handlePressed(BuildContext context) async {
    final cubit = context.read<PostmanCubit>();
    await cubit.load();
    if (!context.mounted) {
      return;
    }
    final state = cubit.state;

    if (state.hasLinkedApi) {
      final didLink = await cubit.linkPostman(apiKey: state.apiKey);
      if (!context.mounted) {
        return;
      }
      if (!didLink) {
        _showSavedKeyError(context, cubit.state.errorMessage);
        return;
      }
      return _showWorkspacePicker(context);
    }

    return _showLinkSheet(context);
  }

  /// Reports a saved-key failure without discarding locally imported data.
  void _showSavedKeyError(BuildContext context, String? message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message?.trim().isNotEmpty == true
                ? message!
                : 'Unable to load Postman data with the saved API key.',
          ),
        ),
      );
  }

  Future<void> _showLinkSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<PostmanCubit>(),
          child: const LinkPostmanBottomSheetBody(),
        );
      },
    );
  }

  Future<void> _showWorkspacePicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<PostmanCubit>(),
          child: const WorkspaceCollectionPickerScreen(),
        );
      },
    );
  }
}
