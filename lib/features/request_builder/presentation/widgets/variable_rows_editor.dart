import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_variable.dart';

/// Mutable row model backing one editable variable line.
class VariableRowData {
  VariableRowData({
    RequestVariable? variable,
    this.scope = RequestVariableScope.global,
  }) : keyController = TextEditingController(text: variable?.key ?? ''),
       valueController = TextEditingController(
         text: variable?.effectiveValue ?? '',
       ),
       isEnabled = variable?.isEnabled ?? true,
       isSecret = variable?.isSecret ?? false,
       description = variable?.description ?? '';

  final TextEditingController keyController;
  final TextEditingController valueController;
  final RequestVariableScope scope;
  bool isEnabled;
  final bool isSecret;
  final String description;

  RequestVariable toVariable() => RequestVariable(
    key: keyController.text.trim(),
    currentValue: valueController.text,
    scope: scope,
    isEnabled: isEnabled,
    isSecret: isSecret,
    description: description,
  );

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

/// Renders editable key/value rows shared by the global and environment editors.
class VariableRowsEditor extends StatelessWidget {
  const VariableRowsEditor({
    required this.rows,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onChanged,
    super.key,
  });

  final List<VariableRowData> rows;
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => _showDeleteAction(context, index),
              child: Row(
                children: [
                  Checkbox(
                    value: rows[index].isEnabled,
                    onChanged: (value) {
                      rows[index].isEnabled = value ?? true;
                      onChanged();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      key: ValueKey<String>(
                        AppWidgetKeys.variableRowsEditorKeyField(index),
                      ),
                      controller: rows[index].keyController,
                      decoration: const InputDecoration(
                        hintText: 'Key',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: TextField(
                      key: ValueKey<String>(
                        AppWidgetKeys.variableRowsEditorValueField(index),
                      ),
                      controller: rows[index].valueController,
                      obscureText: rows[index].isSecret,
                      decoration: const InputDecoration(
                        hintText: 'Value',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey<String>(
                      AppWidgetKeys.variableRowsEditorRemoveButton(index),
                    ),
                    tooltip: 'Remove variable',
                    onPressed: () => onRemoveRow(index),
                    onLongPress: () => _showDeleteAction(context, index),
                    icon: Icon(
                      CupertinoIcons.minus_circle,
                      color: colors.methodDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: onAddRow,
          icon: const Icon(CupertinoIcons.add),
          label: const Text('Add Variable'),
        ),
      ],
    );
  }

  /// Opens the row action menu used by long-press delete interactions.
  Future<void> _showDeleteAction(BuildContext context, int index) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.appColors.surface,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: Icon(
            CupertinoIcons.delete,
            color: context.appColors.methodDelete,
          ),
          title: Text(
            'Delete',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.appColors.methodDelete,
            ),
          ),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (shouldDelete == true) {
      onRemoveRow(index);
    }
  }
}
