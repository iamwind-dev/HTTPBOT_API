import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/saved_credential.dart';
import '../cubit/manage_credentials_cubit.dart';
import 'api_key_presets.dart';
import 'request_modal_sheet.dart';

/// Auth types selectable when creating a credential (excludes "No Auth").
final List<AuthType> _selectableAuthTypes = AuthType.values
    .where((type) => type != AuthType.none)
    .toList(growable: false);

/// Opens the Create Auth sheet, sharing the credentials cubit.
Future<void> showCreateAuthSheet(
  BuildContext context, {
  required ManageCredentialsCubit cubit,
}) => showRequestModalSheet<void>(
  context,
  builder: (sheetContext) => BlocProvider<ManageCredentialsCubit>.value(
    value: cubit,
    child: const _CreateAuthSheet(),
  ),
);

class _CreateAuthSheet extends StatefulWidget {
  const _CreateAuthSheet();

  @override
  State<_CreateAuthSheet> createState() => _CreateAuthSheetState();
}

class _CreateAuthSheetState extends State<_CreateAuthSheet> {
  final TextEditingController _nameController = TextEditingController();
  AuthType _type = AuthType.apiKey;
  ApiKeyAuthDraft _apiKey = const ApiKeyAuthDraft();

  bool get _isCustomKeyName => !apiKeyNamePresets.contains(_apiKey.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return RequestModalSheetCard(
      key: const ValueKey<String>(AppWidgetKeys.createAuthSheet),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onClose: () => Navigator.of(context).pop(), onSave: _save),
            const SizedBox(height: AppSpacing.large),
            _TextField(
              fieldKey: AppWidgetKeys.createAuthNameField,
              controller: _nameController,
              label: AppStrings.createAuthNameHint,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              AppStrings.requestEditorAuth,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.small),
            _card(
              context,
              child: DropdownButtonFormField<AuthType>(
                key: const ValueKey<String>(AppWidgetKeys.createAuthTypeField),
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                items: _selectableAuthTypes
                    .map(
                      (type) => DropdownMenuItem<AuthType>(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (type) {
                  if (type != null) {
                    setState(() => _type = type);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            if (_type == AuthType.apiKey)
              _buildApiKeyForm(context)
            else
              _InfoCard(
                message:
                    '${_type.label} credentials are not supported in this version.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyForm(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _card(
        context,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _isCustomKeyName
              ? apiKeyCustomNameSentinel
              : _apiKey.name,
          decoration: InputDecoration(
            labelText: AppStrings.requestEditorApiKeyName,
            border: InputBorder.none,
          ),
          items: <DropdownMenuItem<String>>[
            ...apiKeyNamePresets.map(
              (name) =>
                  DropdownMenuItem<String>(value: name, child: Text(name)),
            ),
            const DropdownMenuItem<String>(
              value: apiKeyCustomNameSentinel,
              child: Text(AppStrings.requestEditorApiKeyCustomOption),
            ),
          ],
          onChanged: (selected) {
            if (selected == null) {
              return;
            }
            setState(() {
              _apiKey = ApiKeyAuthDraft(
                name: selected == apiKeyCustomNameSentinel ? '' : selected,
                value: _apiKey.value,
                location: _apiKey.location,
              );
            });
          },
        ),
      ),
      if (_isCustomKeyName) ...[
        const SizedBox(height: AppSpacing.small),
        _card(
          context,
          child: TextField(
            decoration: InputDecoration(
              labelText: AppStrings.requestEditorApiKeyCustomName,
              border: InputBorder.none,
            ),
            onChanged: (value) => _apiKey = ApiKeyAuthDraft(
              name: value,
              value: _apiKey.value,
              location: _apiKey.location,
            ),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.small),
      _card(
        context,
        child: TextField(
          decoration: InputDecoration(
            labelText: AppStrings.requestEditorApiKeyValue,
            border: InputBorder.none,
          ),
          onChanged: (value) => _apiKey = ApiKeyAuthDraft(
            name: _apiKey.name,
            value: value,
            location: _apiKey.location,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.small),
      _card(
        context,
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.requestEditorApiKeySendAsHeader,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch.adaptive(
              value: _apiKey.location == ApiKeyLocation.header,
              onChanged: (sendAsHeader) => setState(() {
                _apiKey = ApiKeyAuthDraft(
                  name: _apiKey.name,
                  value: _apiKey.value,
                  location: sendAsHeader
                      ? ApiKeyLocation.header
                      : ApiKeyLocation.query,
                );
              }),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _card(BuildContext context, {required Widget child}) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      border: Border.all(color: context.appColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.xSmall,
      ),
      child: child,
    ),
  );

  void _save() {
    if (_type != AuthType.apiKey) {
      _showMessage(AppStrings.credentialsOnlyApiKeySupported);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Name is required.');
      return;
    }
    if (_apiKey.name.trim().isEmpty) {
      _showMessage('Key name is required.');
      return;
    }
    if (_apiKey.value.trim().isEmpty) {
      _showMessage('Value is required.');
      return;
    }

    context.read<ManageCredentialsCubit>().createApiKeyCredential(
      SavedCredential(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        type: AuthType.apiKey,
        apiKey: _apiKey,
      ),
    );
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onSave});

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
            AppStrings.createAuthTitle,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}
