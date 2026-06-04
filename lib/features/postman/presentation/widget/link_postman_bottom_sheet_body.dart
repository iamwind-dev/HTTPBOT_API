import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubit/postman_cubit.dart';
import 'workspace_collection_picker_screen .dart';

class LinkPostmanBottomSheetBody extends StatefulWidget {
  const LinkPostmanBottomSheetBody({super.key});

  @override
  State<LinkPostmanBottomSheetBody> createState() =>
      _LinkPostmanBottomSheetBodyState();
}

class _LinkPostmanBottomSheetBodyState
    extends State<LinkPostmanBottomSheetBody> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    final cubit = context.read<PostmanCubit>();
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    setState(() => _isSubmitting = true);
    try {
      final didLink = await cubit.linkPostman(apiKey: apiKey);
      if (!mounted) return;
      if (!didLink) {
        final message =
            cubit.state.errorMessage ?? 'Unable to load Postman workspaces.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
      Navigator.pop(context);
      await Future<void>.delayed(Duration.zero);
      await showModalBottomSheet<void>(
        context: rootContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return BlocProvider.value(
            value: cubit,
            child: const WorkspaceCollectionPickerScreen(),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: screenHeight * 0.9,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.large,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xLarge),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: colors.headerActionSurface,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Postman',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: colors.headerActionSurface,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {},
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.more_horiz_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xSmall),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(80, 48),
                                shape: const StadiumBorder(),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Link'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'API Key',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: TextField(
                          controller: _apiKeyController,
                          textAlign: TextAlign.end,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter Value',
                            hintStyle: theme.textTheme.titleMedium?.copyWith(
                              color: colors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
