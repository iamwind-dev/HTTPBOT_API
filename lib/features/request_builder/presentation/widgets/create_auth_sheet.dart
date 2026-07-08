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
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/saved_credential.dart';
import '../cubit/manage_credentials_cubit.dart';
import '../cubit/request_editor_cubit.dart';
import '../cubit/request_editor_state.dart';
import 'request_editor_sheet.dart';
import 'request_modal_sheet.dart';

Future<void> showCreateAuthSheet(
  BuildContext context, {
  ManageCredentialsCubit? cubit,
  String initialCredentialName = '',
  RequestAuthDraft initialAuth = const RequestAuthDraft.none(),
  SavedCredential? editingCredential,
}) => showRequestModalSheet<void>(
  context,
  builder: (sheetContext) => MultiBlocProvider(
    providers: [
      if (cubit != null)
        BlocProvider<ManageCredentialsCubit>.value(value: cubit)
      else
        BlocProvider<ManageCredentialsCubit>(
          create: (_) => getIt<ManageCredentialsCubit>()..load(),
        ),
      BlocProvider<RequestEditorCubit>(
        create: (_) => RequestEditorCubit(
          title: editingCredential == null
              ? AppStrings.createAuthTitle
              : 'Edit Auth',
          initialDraft: RequestDraft(auth: initialAuth),
        ),
      ),
    ],
    child: _CreateAuthSheet(
      initialCredentialName: initialCredentialName,
      editingCredential: editingCredential,
    ),
  ),
);

class _CreateAuthSheet extends StatefulWidget {
  const _CreateAuthSheet({
    required this.initialCredentialName,
    required this.editingCredential,
  });

  final String initialCredentialName;
  final SavedCredential? editingCredential;

  @override
  State<_CreateAuthSheet> createState() => _CreateAuthSheetState();
}

class _CreateAuthSheetState extends State<_CreateAuthSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialCredentialName,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Name is required.');
      return;
    }

    final editorCubit = context.read<RequestEditorCubit>();
    final now = DateTime.now();
    final credential = SavedCredential(
      id: widget.editingCredential?.id ?? now.microsecondsSinceEpoch.toString(),
      name: name,
      auth: editorCubit.state.draft.auth,
      createdAt: widget.editingCredential?.createdAt ?? now,
      updatedAt: now,
    );

    context.read<ManageCredentialsCubit>().saveCredential(credential);
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.createAuthSheet),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: BlocBuilder<RequestEditorCubit, RequestEditorState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: widget.editingCredential == null
                    ? AppStrings.createAuthTitle
                    : 'Edit Auth',
                onClose: () => Navigator.of(context).pop(),
                onSave: _save,
              ),
              const SizedBox(height: AppSpacing.large),
              _TextField(
                fieldKey: AppWidgetKeys.createAuthNameField,
                controller: _nameController,
                label: AppStrings.createAuthNameHint,
              ),
              const SizedBox(height: AppSpacing.large),
              RequestAuthEditorSection(
                auth: state.draft.auth,
                queryParameters: state.draft.queryParameters,
                headers: state.draft.headers,
                showCredentialActions: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        IconButton(
          key: const ValueKey<String>(AppWidgetKeys.createAuthCloseButton),
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: onClose,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey<String>(AppWidgetKeys.createAuthSaveButton),
          icon: const Icon(CupertinoIcons.check_mark),
          onPressed: onSave,
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.fieldKey,
    required this.controller,
    required this.label,
  });

  final String fieldKey;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      border: Border.all(color: context.appColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: TextField(
        key: ValueKey<String>(fieldKey),
        controller: controller,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    ),
  );
}
