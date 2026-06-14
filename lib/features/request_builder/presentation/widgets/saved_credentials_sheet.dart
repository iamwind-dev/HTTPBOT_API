import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/saved_credential.dart';
import '../../domain/usecases/apply_api_key_credential_to_auth_use_case.dart';
import '../cubit/manage_credentials_cubit.dart';
import '../cubit/manage_credentials_state.dart';
import '../cubit/request_editor_cubit.dart';
import 'create_auth_sheet.dart';
import 'request_modal_sheet.dart';

/// Opens the Saved Credentials sheet, preserving the editor cubit scope.
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
    child: const _SavedCredentialsSheet(),
  ),
);

class _SavedCredentialsSheet extends StatelessWidget {
  const _SavedCredentialsSheet();

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.savedCredentialsSheet),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            onClose: () => Navigator.of(context).pop(),
            onDeleteAll: () =>
                context.read<ManageCredentialsCubit>().deleteAll(),
            onAdd: () => _openCreateAuth(context),
          ),
          const SizedBox(height: AppSpacing.large),
          Expanded(
            child: BlocBuilder<ManageCredentialsCubit, ManageCredentialsState>(
              builder: (context, state) {
                if (state.credentials.isEmpty) {
                  return const _EmptyState();
                }
                return _CredentialsList(credentials: state.credentials);
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openCreateAuth(BuildContext context) => showCreateAuthSheet(
    context,
    cubit: context.read<ManageCredentialsCubit>(),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClose,
    required this.onDeleteAll,
    required this.onAdd,
  });

  final VoidCallback onClose;
  final VoidCallback onDeleteAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        IconButton(
          key: const ValueKey<String>(
            AppWidgetKeys.savedCredentialsCloseButton,
          ),
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: onClose,
        ),
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
            size: AppSpacing.xxLarge,
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
  const _CredentialsList({required this.credentials});

  final List<SavedCredential> credentials;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: credentials.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
    itemBuilder: (context, index) =>
        _CredentialTile(credential: credentials[index], index: index),
  );
}

class _CredentialTile extends StatelessWidget {
  const _CredentialTile({required this.credential, required this.index});

  final SavedCredential credential;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final location = credential.apiKey.location == ApiKeyLocation.header
        ? 'Header'
        : 'Query';
    final subtitle = credential.type == AuthType.apiKey
        ? '${credential.apiKey.name} • $location'
        : credential.type.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(AppWidgetKeys.savedCredentialsItemAt(index)),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
        onTap: () => _apply(context),
        onLongPress: () => _showDeleteSheet(context),
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
                        subtitle,
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

  void _apply(BuildContext context) {
    const applyUseCase = ApplyApiKeyCredentialToAuthUseCase();
    final editorCubit = context.read<RequestEditorCubit>();
    editorCubit.updateAuth(
      applyUseCase(editorCubit.state.draft.auth, credential),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showDeleteSheet(BuildContext context) async {
    final cubit = context.read<ManageCredentialsCubit>();
    final colors = context.appColors;
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.xxLarge),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.xxLarge),
                ),
                onTap: () => Navigator.of(sheetContext).pop(true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.medium,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Delete',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.methodDelete,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(CupertinoIcons.delete, color: colors.methodDelete),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (shouldDelete ?? false) {
      await cubit.delete(credential.id);
    }
  }
}
