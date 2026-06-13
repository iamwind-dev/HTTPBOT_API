import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_settings.dart';
import '../cubit/request_editor_cubit.dart';
import 'request_modal_sheet.dart';

Future<void> showRequestSettingsSheet(
  BuildContext context, {
  required RequestEditorCubit requestEditorCubit,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => BlocProvider<RequestEditorCubit>.value(
    value: requestEditorCubit,
    child: const _RequestSettingsSheet(),
  ),
);

class _RequestSettingsSheet extends StatelessWidget {
  const _RequestSettingsSheet();

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsSettingsSheet),
    child: BlocBuilder<RequestEditorCubit, dynamic>(
      builder: (context, state) {
        final settings = state.draft.settings as RequestSettings;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.small,
                AppSpacing.medium,
                AppSpacing.medium,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey<String>(
                      AppWidgetKeys.requestsSettingsCloseButton,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CupertinoIcons.xmark),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.requestSettingsTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  0,
                  AppSpacing.large,
                  AppSpacing.large,
                ),
                children: [
                  _SettingsCard(
                    children: [
                      _SettingsValueRow(
                        fieldName: 'saved_responses',
                        label:
                            AppStrings.requestSettingsSavedResponsesInHistory,
                        value: settings.savedResponsesInHistory.toString(),
                        onTap: () => _editSavedResponses(context, settings),
                      ),
                      _SettingsValueRow(
                        fieldName: 'timeout_seconds',
                        label:
                            AppStrings.requestSettingsTimeoutIntervalInSeconds,
                        value: settings.timeoutSeconds.toString(),
                        onTap: () => _editTimeout(context, settings),
                      ),
                      _SettingsValueRow(
                        fieldName: 'user_agent',
                        label: AppStrings.requestSettingsUserAgent,
                        value: settings.userAgent,
                        onTap: () => _editUserAgent(context, settings),
                      ),
                      _SettingsSwitchRow(
                        fieldName: 'follow_redirects',
                        label: AppStrings.requestSettingsFollowRedirects,
                        value: settings.followRedirects,
                        onChanged: (value) => _updateSettings(
                          context,
                          settings.copyWith(followRedirects: value),
                        ),
                      ),
                      _SettingsSwitchRow(
                        fieldName: 'send_cookies',
                        label: AppStrings.requestSettingsSendCookies,
                        value: settings.sendCookies,
                        onChanged: (value) => _updateSettings(
                          context,
                          settings.copyWith(sendCookies: value),
                        ),
                      ),
                      _SettingsSwitchRow(
                        fieldName: 'store_cookies',
                        label: AppStrings.requestSettingsStoreCookies,
                        value: settings.storeCookies,
                        onChanged: (value) => _updateSettings(
                          context,
                          settings.copyWith(storeCookies: value),
                        ),
                      ),
                      _SettingsSwitchRow(
                        fieldName: 'verify_ssl',
                        label: AppStrings.requestSettingsVerifySsl,
                        value: settings.verifySsl,
                        onChanged: (value) {
                          _updateSettings(
                            context,
                            settings.copyWith(verifySsl: value),
                          );
                          if (!value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  AppStrings.requestSettingsDisableSslWarning,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _editSavedResponses(
    BuildContext context,
    RequestSettings settings,
  ) async {
    final value = await _showSettingsValueEditor(
      context,
      title: AppStrings.requestSettingsSavedResponsesInHistory,
      initialValue: settings.savedResponsesInHistory.toString(),
      keyboardType: TextInputType.number,
    );
    if (value == null || !context.mounted) {
      return;
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 100) {
      _showError(context, AppStrings.requestSettingsSavedResponsesError);
      return;
    }

    _updateSettings(
      context,
      settings.copyWith(savedResponsesInHistory: parsed),
    );
  }

  Future<void> _editTimeout(
    BuildContext context,
    RequestSettings settings,
  ) async {
    final value = await _showSettingsValueEditor(
      context,
      title: AppStrings.requestSettingsTimeoutIntervalInSeconds,
      initialValue: settings.timeoutSeconds.toString(),
      keyboardType: TextInputType.number,
    );
    if (value == null || !context.mounted) {
      return;
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1 || parsed > 600) {
      _showError(context, AppStrings.requestSettingsTimeoutError);
      return;
    }

    _updateSettings(context, settings.copyWith(timeoutSeconds: parsed));
  }

  Future<void> _editUserAgent(
    BuildContext context,
    RequestSettings settings,
  ) async {
    final value = await _showSettingsValueEditor(
      context,
      title: AppStrings.requestSettingsUserAgent,
      initialValue: settings.userAgent,
      keyboardType: TextInputType.text,
    );
    if (value == null || !context.mounted) {
      return;
    }

    _updateSettings(context, settings.copyWith(userAgent: value));
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _updateSettings(BuildContext context, RequestSettings settings) {
    context.read<RequestEditorCubit>().updateSettings(settings);
  }
}

Future<String?> _showSettingsValueEditor(
  BuildContext context, {
  required String title,
  required String initialValue,
  required TextInputType keyboardType,
}) => showRequestModalSheet<String>(
  context,
  builder: (context) => _SettingsValueEditorSheet(
    title: title,
    initialValue: initialValue,
    keyboardType: keyboardType,
  ),
);

class _SettingsValueEditorSheet extends StatefulWidget {
  const _SettingsValueEditorSheet({
    required this.title,
    required this.initialValue,
    required this.keyboardType,
  });

  final String title;
  final String initialValue;
  final TextInputType keyboardType;

  @override
  State<_SettingsValueEditorSheet> createState() =>
      _SettingsValueEditorSheetState();
}

class _SettingsValueEditorSheetState extends State<_SettingsValueEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.small,
            AppSpacing.medium,
            AppSpacing.medium,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.xmark),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                icon: const Icon(CupertinoIcons.check_mark),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              0,
              AppSpacing.large,
              AppSpacing.large,
            ),
            child: TextFormField(
              key: ValueKey<String>(
                AppWidgetKeys.requestsSettingsField(widget.title.toLowerCase()),
              ),
              controller: _controller,
              keyboardType: widget.keyboardType,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.title,
                filled: true,
                fillColor: context.appColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.xxLarge),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    ),
    child: Column(children: children),
  );
}

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({
    required this.fieldName,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String fieldName;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey<String>(AppWidgetKeys.requestsSettingsField(fieldName)),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.fieldName,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String fieldName;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.medium,
      vertical: AppSpacing.small,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Switch.adaptive(
          key: ValueKey<String>(AppWidgetKeys.requestsSettingsField(fieldName)),
          value: value,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
