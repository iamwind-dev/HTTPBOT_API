import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/response_filter_entity.dart';
import '../../domain/helpers/filter_response_mode.dart';
import 'request_modal_sheet.dart';

/// The value returned when the user saves a filter in the editor sheet.
class ResponseFilterDraft {
  const ResponseFilterDraft({
    required this.name,
    required this.query,
    required this.mode,
  });

  final String name;
  final String query;
  final FilterResponseMode mode;
}

/// Opens the add/edit editor; returns the saved draft, or null when cancelled.
Future<ResponseFilterDraft?> showResponseFilterEditorSheet(
  BuildContext context, {
  ResponseFilterEntity? existing,
  String? initialQuery,
  FilterResponseMode? initialMode,
}) => showRequestModalSheet<ResponseFilterDraft>(
  context,
  builder: (context) => _ResponseFilterEditorSheet(
    existing: existing,
    initialQuery: initialQuery,
    initialMode: initialMode,
  ),
);

class _ResponseFilterEditorSheet extends StatefulWidget {
  const _ResponseFilterEditorSheet({
    this.existing,
    this.initialQuery,
    this.initialMode,
  });

  final ResponseFilterEntity? existing;
  final String? initialQuery;
  final FilterResponseMode? initialMode;

  @override
  State<_ResponseFilterEditorSheet> createState() =>
      _ResponseFilterEditorSheetState();
}

class _ResponseFilterEditorSheetState
    extends State<_ResponseFilterEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _queryController;
  late FilterResponseMode _mode;
  String? _nameError;
  String? _queryError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _queryController = TextEditingController(
      text: widget.existing?.query ?? widget.initialQuery ?? '',
    );
    _mode =
        widget.existing?.mode ?? widget.initialMode ?? FilterResponseMode.jq;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.responseFilterEditorSheet),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.small),
        _header(context),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                context,
                key: AppWidgetKeys.responseFilterEditorNameField,
                label: AppStrings.responseFilterNameLabel,
                controller: _nameController,
                error: _nameError,
              ),
              const SizedBox(height: AppSpacing.medium),
              _field(
                context,
                key: AppWidgetKeys.responseFilterEditorQueryField,
                label: AppStrings.responseFilterQueryLabel,
                controller: _queryController,
                error: _queryError,
                monospace: true,
              ),
              const SizedBox(height: AppSpacing.medium),
              _modePicker(context),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
    child: Row(
      children: [
        IconButton(
          tooltip: AppStrings.requestResponseCloseTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
        ),
        Expanded(
          child: Text(
            widget.existing == null
                ? AppStrings.responseFilterEditorAddTitle
                : AppStrings.responseFilterEditorEditTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          key: const ValueKey<String>(
            AppWidgetKeys.responseFilterEditorSaveButton,
          ),
          onPressed: _save,
          child: const Text(AppStrings.responseFilterSave),
        ),
      ],
    ),
  );

  Widget _field(
    BuildContext context, {
    required String key,
    required String label,
    required TextEditingController controller,
    String? error,
    bool monospace = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: AppSpacing.xSmall),
      TextField(
        key: ValueKey<String>(key),
        controller: controller,
        style: monospace
            ? Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')
            : null,
        decoration: InputDecoration(
          errorText: error,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
          ),
        ),
      ),
    ],
  );

  Widget _modePicker(BuildContext context) => Row(
    children: [
      Text(
        AppStrings.responseFilterModeLabel,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const Spacer(),
      DropdownButton<FilterResponseMode>(
        value: _mode,
        onChanged: (mode) {
          if (mode != null) {
            setState(() => _mode = mode);
          }
        },
        items: [
          for (final mode in FilterResponseMode.values)
            DropdownMenuItem<FilterResponseMode>(
              value: mode,
              child: Text(mode.label),
            ),
        ],
      ),
    ],
  );

  void _save() {
    final name = _nameController.text.trim();
    final query = _queryController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? AppStrings.responseFilterNameRequired : null;
      _queryError =
          query.isEmpty ? AppStrings.responseFilterQueryRequired : null;
    });
    if (name.isEmpty || query.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      ResponseFilterDraft(name: name, query: query, mode: _mode),
    );
  }
}
