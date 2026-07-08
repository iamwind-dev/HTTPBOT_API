import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/saved_credential.dart';
import '../../domain/usecases/apply_api_key_credential_to_auth_use_case.dart';
import '../cubit/manage_credentials_cubit.dart';
import '../cubit/manage_credentials_state.dart';
import '../cubit/request_editor_cubit.dart';
import 'create_auth_sheet.dart';
import 'request_modal_sheet.dart';

enum SavedCredentialsMode { manage, select }

Future<void> showSavedCredentialsSheet(
  BuildContext context, {
  required RequestEditorCubit editorCubit,
}) => showRequestModalSheet<void>(
  context,
  builder: (sheetContext) => MultiBlocProvider(
    providers: [
      BlocProvider<RequestEditorCubit>.value(value: editorCubit),
      BlocProvider<ManageCredentialsCubit>(
        create: (_) => getIt<ManageCredentialsCubit>()..load(),
      ),
    ],
    child: const _SavedCredentialsSheet(mode: SavedCredentialsMode.select),
  ),
);

class SavedCredentialsPage extends StatelessWidget {
  const SavedCredentialsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ManageCredentialsCubit>(
    create: (_) => getIt<ManageCredentialsCubit>()..load(),
    child: const SavedCredentialsView(mode: SavedCredentialsMode.manage),
  );
}

class _SavedCredentialsSheet extends StatelessWidget {
  const _SavedCredentialsSheet({required this.mode});

  final SavedCredentialsMode mode;

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.savedCredentialsSheet),
    child: SavedCredentialsView(mode: mode, useSheetScaffold: true),
  );
}

class SavedCredentialsView extends StatelessWidget {
  const SavedCredentialsView({
    super.key,
    required this.mode,
    this.useSheetScaffold = false,
  });

  final SavedCredentialsMode mode;
  final bool useSheetScaffold;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            mode: mode,
            onClose: () => Navigator.of(context).maybePop(),
            onDeleteAll: () => context.read<ManageCredentialsCubit>().deleteAll(),
            onAdd: () => _openCreateAuth(context),
          ),
          const SizedBox(height: AppSpacing.large),
          Expanded(
            child: BlocBuilder<ManageCredentialsCubit, ManageCredentialsState>(
              builder: (context, state) {
                if (state.status == ManageCredentialsStatus.loading &&
                    state.credentials.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.credentials.isEmpty) {
                  return const _EmptyState();
                }
                return _CredentialsList(mode: mode, credentials: state.credentials);
              },
            ),
          ),
        ],
      ),
    );

    if (useSheetScaffold) {
      return content;
    }

    return content;
  }

  Future<void> _openCreateAuth(BuildContext context) => showCreateAuthSheet(
    context,
    cubit: context.read<ManageCredentialsCubit>(),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.onClose,
    required this.onDeleteAll,
    required this.onAdd,
  });

  final SavedCredentialsMode mode;
  final VoidCallback onClose;
  final VoidCallback onDeleteAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        if (mode == SavedCredentialsMode.select)
          IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.savedCredentialsCloseButton,
            ),
            icon: const Icon(CupertinoIcons.xmark),
            onPressed: onClose,
          ),
        if (mode == SavedCredentialsMode.select)
          const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            AppStrings.savedCredentialsTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        PopupMenuButton<String>(
          key: const ValueKey<String>(AppWidgetKeys.savedCredentialsMoreButton),
          tooltip: 'More credential actions',
          icon: const Icon(CupertinoIcons.ellipsis),
          color: colors.surface,
          position: PopupMenuPosition.under,
          onSelected: (_) => onDeleteAll(),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'delete_all',
              child: Text(
                AppStrings.savedCredentialsDeleteAll,
                style: TextStyle(
                  color: colors.methodDelete,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          key: const ValueKey<String>(AppWidgetKeys.savedCredentialsAddButton),
          icon: const Icon(CupertinoIcons.add),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.lock_shield,
            size: AppSpacing.xxxLarge,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            AppStrings.savedCredentialsEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
            child: Text(
              AppStrings.savedCredentialsEmptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialsList extends StatelessWidget {
  const _CredentialsList({required this.mode, required this.credentials});

  final SavedCredentialsMode mode;
  final List<SavedCredential> credentials;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: credentials.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
    itemBuilder: (context, index) => _CredentialTile(
      credential: credentials[index],
      index: index,
      mode: mode,
    ),
  );
}

class _CredentialTile extends StatelessWidget {
  const _CredentialTile({
    required this.credential,
    required this.index,
    required this.mode,
  });

  final SavedCredential credential;
  final int index;
  final SavedCredentialsMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(AppWidgetKeys.savedCredentialsItemAt(index)),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
        onTap: () => _onTap(context),
        onLongPress: () => _showActions(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.medium,
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.lock, color: colors.iconSecondary),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        credential.type.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, color: colors.iconSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (mode == SavedCredentialsMode.select) {
      const applyUseCase = ApplyApiKeyCredentialToAuthUseCase();
      final editorCubit = context.read<RequestEditorCubit>();
      editorCubit.updateAuth(
        applyUseCase(editorCubit.state.draft.auth, credential),
      );
      Navigator.of(context).pop();
      return;
    }

    unawaited(
      showCreateAuthSheet(
        context,
        cubit: context.read<ManageCredentialsCubit>(),
        initialCredentialName: credential.name,
        initialAuth: credential.auth,
        editingCredential: credential,
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.xxLarge),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Edit'),
                  onTap: () => Navigator.of(sheetContext).pop('edit'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Delete'),
                  onTap: () => Navigator.of(sheetContext).pop('delete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (action == 'edit') {
      _onTap(context);
      return;
    }

    if (action == 'delete') {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Credential'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this credential?'),
              SizedBox(height: AppSpacing.small),
              Text('This credential will be removed from saved credentials.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete == true && context.mounted) {
        await context.read<ManageCredentialsCubit>().delete(credential.id);
      }
    }
  }
}
