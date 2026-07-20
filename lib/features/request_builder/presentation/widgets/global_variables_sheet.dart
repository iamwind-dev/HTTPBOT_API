import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_variable.dart';

const _footerText =
    'Variables set here are available to use irrespective of the current '
    'selected environment. However, variables with the same names set in '
    'the selected environment take precedence.';

class GlobalVariablesController {
  VoidCallback? save;
}

/// Opens the Global Variables editor and returns the saved list, or null on cancel.
Future<List<RequestVariable>?> showGlobalVariablesSheet(
  BuildContext context, {
  required List<RequestVariable> variables,
}) => showModalBottomSheet<List<RequestVariable>>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: context.appColors.background,
  builder: (context) => GlobalVariablesView(
    variables: variables,
    onClose: () => Navigator.of(context).pop(),
  ),
);

class GlobalVariablesView extends StatefulWidget {
  const GlobalVariablesView({
    super.key,
    required this.variables,
    this.onClose,
    this.onSave,
    this.controller,
  });

  final List<RequestVariable> variables;
  final VoidCallback? onClose;
  final Future<void> Function(List<RequestVariable> variables)? onSave;
  final GlobalVariablesController? controller;

  @override
  State<GlobalVariablesView> createState() => _GlobalVariablesViewState();
}

class _GlobalVariablesViewState extends State<GlobalVariablesView> {
  late final TextEditingController _keyController = TextEditingController();
  late final TextEditingController _valueController = TextEditingController();
  late final FocusNode _keyFocusNode = FocusNode();
  late List<RequestVariable> _variables = List<RequestVariable>.of(
    widget.variables,
  );
  String _errorMessage = '';

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  /// Adds the pending input row to the in-memory list after validation.
  void _addPendingVariable() {
    final result = _buildValidatedVariables(includePending: true);
    if (result.errorMessage != null) {
      setState(() {
        _errorMessage = result.errorMessage!;
      });
      return;
    }

    final pending = _pendingVariableOrNull();
    if (pending == null) {
      _keyFocusNode.requestFocus();
      return;
    }

    setState(() {
      _variables = <RequestVariable>[..._variables, pending];
      _keyController.clear();
      _valueController.clear();
      _errorMessage = '';
    });
    _keyFocusNode.requestFocus();
  }

  /// Validates and returns the final list when the user taps the check button.
  Future<void> _save() async {
    final result = _buildValidatedVariables(includePending: true);
    if (result.errorMessage != null) {
      setState(() {
        _errorMessage = result.errorMessage!;
      });
      return;
    }

    if (widget.onSave != null) {
      await widget.onSave!(result.variables);
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(result.variables);
    }
  }

  /// Removes a row from local state without persisting until save is tapped.
  void _deleteVariableAt(int index) {
    setState(() {
      _variables = _variables
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value)
          .toList(growable: false);
      _errorMessage = '';
    });
  }

  /// Shows the delete action requested by the long-press row interaction.
  Future<void> _showDeleteAction(int index) async {
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

    if (shouldDelete == true && mounted) {
      _deleteVariableAt(index);
    }
  }

  /// Creates a pending variable unless the input row is completely empty.
  RequestVariable? _pendingVariableOrNull() {
    final key = _keyController.text.trim();
    final value = _valueController.text;
    if (key.isEmpty && value.isEmpty) {
      return null;
    }

    return RequestVariable(
      key: key,
      currentValue: value,
      scope: RequestVariableScope.global,
    );
  }

  /// Validates key rules and duplicate names for rows that would be saved.
  _ValidationResult _buildValidatedVariables({required bool includePending}) {
    final candidateVariables = <RequestVariable>[..._variables];
    final pending = includePending ? _pendingVariableOrNull() : null;
    if (pending != null) {
      candidateVariables.add(pending);
    }

    final keys = <String>{};
    final validatedVariables = <RequestVariable>[];

    for (final variable in candidateVariables) {
      final key = variable.key.trim();
      final value = variable.currentValue;
      if (key.isEmpty && value.isEmpty) {
        continue;
      }

      if (key.isEmpty) {
        return const _ValidationResult.error('Variable key is required.');
      }

      if (key.contains('{{') || key.contains('}}')) {
        return const _ValidationResult.error(
          'Variable key must not include braces.',
        );
      }

      if (keys.contains(key)) {
        return _ValidationResult.error('Duplicate variable key: $key');
      }

      keys.add(key);
      validatedVariables.add(
        RequestVariable(
          key: key,
          currentValue: value,
          initialValue: variable.initialValue,
          scope: RequestVariableScope.global,
          isEnabled: variable.isEnabled,
          isSecret: variable.isSecret,
          description: variable.description,
        ),
      );
    }

    return _ValidationResult.success(validatedVariables);
  }

  /// Builds the modal shell matching the request editor bottom-sheet style.
  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    widget.controller?.save = () => unawaited(_save());

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          key: const ValueKey<String>(AppWidgetKeys.globalVariablesSheet),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.large,
            widget.onClose == null ? 0 : AppSpacing.large,
            AppSpacing.large,
            AppSpacing.large,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onClose != null) ...[
                _GlobalVariablesHeader(
                  onClose: widget.onClose ?? _close,
                  onSave: _save,
                ),
                const SizedBox(height: AppSpacing.large),
              ],
              _VariablesCard(
                variables: _variables,
                keyController: _keyController,
                valueController: _valueController,
                keyFocusNode: _keyFocusNode,
                onAdd: _addPendingVariable,
                onDeleteRequested: _showDeleteAction,
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  _errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appColors.methodDelete,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              Text(
                _footerText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Closes the sheet and discards unsaved local changes.
  void _close() {
    Navigator.of(context).pop();
  }
}

class _GlobalVariablesHeader extends StatelessWidget {
  const _GlobalVariablesHeader({required this.onClose, required this.onSave});

  final VoidCallback onClose;
  final Future<void> Function() onSave;

  /// Builds the X, centered title, and blue check toolbar.
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: const ValueKey<String>(AppWidgetKeys.globalVariablesCloseButton),
        onPressed: onClose,
        icon: const Icon(CupertinoIcons.xmark),
      ),
      Expanded(
        child: Text(
          'Global Variables',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        key: const ValueKey<String>(AppWidgetKeys.globalVariablesSaveButton),
        onPressed: () => unawaited(onSave()),
        color: context.appColors.primary,
        icon: const Icon(CupertinoIcons.check_mark),
      ),
    ],
  );
}

class _VariablesCard extends StatelessWidget {
  const _VariablesCard({
    required this.variables,
    required this.keyController,
    required this.valueController,
    required this.keyFocusNode,
    required this.onAdd,
    required this.onDeleteRequested,
  });

  final FocusNode keyFocusNode;
  final TextEditingController keyController;
  final VoidCallback onAdd;
  final ValueChanged<int> onDeleteRequested;
  final TextEditingController valueController;
  final List<RequestVariable> variables;

  /// Builds the card containing saved variables, pending inputs, and Add row.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
      border: Border.all(color: context.appColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < variables.length; index++)
            _VariableDisplayRow(
              variable: variables[index],
              onLongPress: () => onDeleteRequested(index),
            ),
          _VariableInputRow(
            keyController: keyController,
            valueController: valueController,
            keyFocusNode: keyFocusNode,
          ),
          _AddVariableRow(onTap: onAdd),
        ],
      ),
    ),
  );
}

class _VariableDisplayRow extends StatelessWidget {
  const _VariableDisplayRow({
    required this.variable,
    required this.onLongPress,
  });

  final VoidCallback onLongPress;
  final RequestVariable variable;

  /// Shows one persisted key/value pair with ellipsis for long values.
  @override
  Widget build(BuildContext context) => InkWell(
    onLongPress: onLongPress,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              variable.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              variable.effectiveValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VariableInputRow extends StatelessWidget {
  const _VariableInputRow({
    required this.keyController,
    required this.valueController,
    required this.keyFocusNode,
  });

  final FocusNode keyFocusNode;
  final TextEditingController keyController;
  final TextEditingController valueController;

  /// Renders the always-visible key/value input row.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.large,
      vertical: AppSpacing.xSmall,
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey<String>(AppWidgetKeys.globalVariablesKeyField),
            controller: keyController,
            focusNode: keyFocusNode,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Key', isDense: true),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: TextField(
            key: const ValueKey<String>(
              AppWidgetKeys.globalVariablesValueField,
            ),
            controller: valueController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Value', isDense: true),
          ),
        ),
      ],
    ),
  );
}

class _AddVariableRow extends StatelessWidget {
  const _AddVariableRow({required this.onTap});

  final VoidCallback onTap;

  /// Builds the green-blue Add action row used for appending the pending input.
  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey<String>(AppWidgetKeys.globalVariablesAddRow),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.add, color: context.appColors.primary),
          const SizedBox(width: AppSpacing.small),
          Text(
            'Add',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ValidationResult {
  const _ValidationResult.success(this.variables) : errorMessage = null;

  const _ValidationResult.error(this.errorMessage)
    : variables = const <RequestVariable>[];

  final String? errorMessage;
  final List<RequestVariable> variables;
}
