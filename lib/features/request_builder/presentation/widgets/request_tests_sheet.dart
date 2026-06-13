import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_test.dart';
import '../../domain/helpers/request_test_catalog.dart';
import '../../domain/helpers/request_test_label_builder.dart';
import '../cubit/request_editor_cubit.dart';
import 'request_modal_sheet.dart';

Future<void> showRequestTestsSheet(
  BuildContext context, {
  required RequestEditorCubit requestEditorCubit,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => BlocProvider<RequestEditorCubit>.value(
    value: requestEditorCubit,
    child: const _RequestTestsSheet(),
  ),
);

class _RequestTestsSheet extends StatelessWidget {
  const _RequestTestsSheet();

  @override
  Widget build(BuildContext context) {
    return RequestModalSheetCard(
      key: const ValueKey<String>(AppWidgetKeys.requestsTestsSheet),
      child: BlocBuilder<RequestEditorCubit, dynamic>(
        builder: (context, state) {
          final tests = state.draft.tests as List<RequestTest>;

          return Column(
            children: [
              _TestsSheetHeader(
                title: AppStrings.testsTitle,
                onClose: () => Navigator.of(context).pop(),
                onAdd: () => _openTestEditor(context),
              ),
              Expanded(
                child: tests.isEmpty
                    ? const _EmptyTestsState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.large,
                          0,
                          AppSpacing.large,
                          AppSpacing.large,
                        ),
                        itemCount: tests.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.small),
                        itemBuilder: (context, index) {
                          final test = tests[index];
                          return KeyedSubtree(
                            key: ValueKey<String>(
                              AppWidgetKeys.requestsTestListItemAt(index),
                            ),
                            child: _TestListCard(
                              test: test,
                              onTap: () => _openTestEditor(context, test: test),
                              onLongPress: () =>
                                  _openTestActions(context, test: test),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteTest(BuildContext context, RequestTest test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.testsDeleteTitle),
        content: const Text(AppStrings.testsDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.testsDeleteAction,
              style: TextStyle(color: context.appColors.methodDelete),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final cubit = context.read<RequestEditorCubit>();
    cubit.updateTests(
      cubit.state.draft.tests
          .where((existingTest) => existingTest.id != test.id)
          .toList(growable: false),
    );
  }

  Future<void> _openTestActions(
    BuildContext context, {
    required RequestTest test,
  }) async {
    final action = await showModalBottomSheet<_RequestTestAction>(
      context: context,
      backgroundColor: context.appColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(AppStrings.testsEditAction),
              onTap: () => Navigator.of(context).pop(_RequestTestAction.edit),
            ),
            ListTile(
              title: Text(
                AppStrings.testsDeleteAction,
                style: TextStyle(color: context.appColors.methodDelete),
              ),
              onTap: () => Navigator.of(context).pop(_RequestTestAction.delete),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _RequestTestAction.edit:
        await _openTestEditor(context, test: test);
      case _RequestTestAction.delete:
        await _deleteTest(context, test);
    }
  }

  Future<void> _openTestEditor(
    BuildContext context, {
    RequestTest? test,
  }) async {
    final result = await showRequestTestEditorSheet(context, test: test);
    if (result == null || !context.mounted) {
      return;
    }

    final cubit = context.read<RequestEditorCubit>();
    final existingTests = cubit.state.draft.tests;
    final updatedTests = test == null
        ? [...existingTests, result]
        : existingTests
              .map((existingTest) => existingTest.id == result.id ? result : existingTest)
              .toList(growable: false);
    cubit.updateTests(updatedTests);
  }
}

Future<RequestTest?> showRequestTestEditorSheet(
  BuildContext context, {
  RequestTest? test,
}) => showRequestModalSheet<RequestTest>(
  context,
  builder: (context) => _RequestTestEditorSheet(test: test),
);

class _RequestTestEditorSheet extends StatefulWidget {
  const _RequestTestEditorSheet({this.test});

  final RequestTest? test;

  @override
  State<_RequestTestEditorSheet> createState() => _RequestTestEditorSheetState();
}

class _RequestTestEditorSheetState extends State<_RequestTestEditorSheet> {
  late RequestTestType? _selectedType;
  late RequestTestComparator? _selectedComparator;
  late ResponseTimeUnit? _selectedTimeUnit;
  late ResponseSizeUnit? _selectedSizeUnit;
  late bool _caseSensitive;
  late String? _expectedValue;
  late String? _minValue;
  late String? _maxValue;
  late String? _headerName;
  late String? _cookieName;
  late String? _jsonPath;
  late String? _xPath;

  bool get _isEditing => widget.test != null;

  @override
  void initState() {
    super.initState();
    final test = widget.test;
    _selectedType = test?.type;
    _selectedComparator = test?.comparator;
    _selectedTimeUnit = test?.timeUnit;
    _selectedSizeUnit = test?.sizeUnit;
    _caseSensitive = test?.caseSensitive ?? false;
    _expectedValue = test?.expectedValue;
    _minValue = test?.minValue;
    _maxValue = test?.maxValue;
    _headerName = test?.headerName;
    _cookieName = test?.cookieName;
    _jsonPath = test?.jsonPath;
    _xPath = test?.xPath;
  }

  List<RequestTestComparator> get _comparators =>
      _selectedType == null ? const <RequestTestComparator>[] : comparatorsForRequestTestType(_selectedType!);

  bool get _showsCaseSensitive => switch (_selectedType) {
    RequestTestType.responseBody ||
    RequestTestType.header ||
    RequestTestType.headers ||
    RequestTestType.cookie ||
    RequestTestType.cookies ||
    RequestTestType.jsonPath ||
    RequestTestType.xPath => true,
    _ => false,
  };

  bool get _showsExpectedValue {
    final comparator = _selectedComparator;
    if (comparator == null) {
      return false;
    }

    if (comparator.needsRangeValues) {
      return false;
    }

    return comparator.needsExpectedValue;
  }

  Future<void> _editTextValue({
    required String title,
    required String? initialValue,
    required ValueChanged<String> onSaved,
  }) async {
    final result = await showRequestTestTextValueEditorSheet(
      context,
      title: title,
      initialValue: initialValue ?? '',
    );
    if (result != null && mounted) {
      setState(() {
        onSaved(result);
      });
    }
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final now = DateTime.now().toUtc();
    Navigator.of(context).pop(
      RequestTest(
        id: widget.test?.id ?? '${now.microsecondsSinceEpoch}',
        type: _selectedType!,
        comparator: _selectedComparator!,
        expectedValue: _normalizedNullable(_expectedValue),
        minValue: _normalizedNullable(_minValue),
        maxValue: _normalizedNullable(_maxValue),
        headerName: _normalizedNullable(_headerName),
        cookieName: _normalizedNullable(_cookieName),
        jsonPath: _normalizedNullable(_jsonPath),
        xPath: _normalizedNullable(_xPath),
        timeUnit: _selectedTimeUnit,
        sizeUnit: _selectedSizeUnit,
        caseSensitive: _caseSensitive,
        createdAt: widget.test?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  String? _validate() {
    if (_selectedType == null) {
      return 'Test Type is required.';
    }

    if (_selectedComparator == null) {
      return 'Comparator is required.';
    }

    final comparator = _selectedComparator!;
    final type = _selectedType!;

    if (comparatorsForRequestTestType(type).contains(comparator) == false) {
      return 'Comparator is not valid for this Test Type.';
    }

    bool hasValidNumber(String? value) => num.tryParse(value?.trim() ?? '') != null;

    switch (type) {
      case RequestTestType.statusCode:
      case RequestTestType.responseTime:
      case RequestTestType.responseSize:
        if (comparator.needsRangeValues) {
          if (!hasValidNumber(_minValue) || !hasValidNumber(_maxValue)) {
            return 'Min Value and Max Value must be valid numbers.';
          }
        } else if (!hasValidNumber(_expectedValue)) {
          return 'Expected Value must be a valid number.';
        }
        if (type == RequestTestType.responseTime && _selectedTimeUnit == null) {
          return 'Time Unit is required.';
        }
        if (type == RequestTestType.responseSize && _selectedSizeUnit == null) {
          return 'Size Unit is required.';
        }
      case RequestTestType.responseBody:
        if (_showsExpectedValue && _normalizedNullable(_expectedValue) == null) {
          return 'Expected Value is required.';
        }
      case RequestTestType.header:
        if (_normalizedNullable(_headerName) == null) {
          return 'Header Name is required.';
        }
        if (_showsExpectedValue && _normalizedNullable(_expectedValue) == null) {
          return 'Expected Value is required.';
        }
      case RequestTestType.headers:
        if ((comparator == RequestTestComparator.containsKey ||
                comparator == RequestTestComparator.doesNotContainKey) &&
            _normalizedNullable(_headerName) == null) {
          return 'Header Name is required.';
        }
        if (comparator == RequestTestComparator.countIs &&
            !hasValidNumber(_expectedValue)) {
          return 'Expected Value must be a valid number.';
        }
      case RequestTestType.cookie:
        if (_normalizedNullable(_cookieName) == null) {
          return 'Cookie Name is required.';
        }
        if (_showsExpectedValue && _normalizedNullable(_expectedValue) == null) {
          return 'Expected Value is required.';
        }
      case RequestTestType.cookies:
        if ((comparator == RequestTestComparator.containsKey ||
                comparator == RequestTestComparator.doesNotContainKey) &&
            _normalizedNullable(_cookieName) == null) {
          return 'Cookie Name is required.';
        }
        if (comparator == RequestTestComparator.countIs &&
            !hasValidNumber(_expectedValue)) {
          return 'Expected Value must be a valid number.';
        }
      case RequestTestType.jsonPath:
        if (_normalizedNullable(_jsonPath) == null) {
          return 'JSON Path is required.';
        }
        if (_showsExpectedValue && _normalizedNullable(_expectedValue) == null) {
          return 'Expected Value is required.';
        }
      case RequestTestType.xPath:
        if (_normalizedNullable(_xPath) == null) {
          return 'XPath is required.';
        }
        if (_showsExpectedValue && _normalizedNullable(_expectedValue) == null) {
          return 'Expected Value is required.';
        }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RequestModalSheetCard(
      key: const ValueKey<String>(AppWidgetKeys.requestsTestEditorSheet),
      child: Column(
        children: [
          _TestsSheetHeader(
            title: _isEditing ? AppStrings.testsEditTitle : AppStrings.testsAddTitle,
            onClose: () => Navigator.of(context).pop(),
            trailing: IconButton(
              onPressed: _selectedType == null ? null : _save,
              icon: const Icon(CupertinoIcons.check_mark),
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
                _DropdownField<RequestTestType?>(
                  fieldKey: AppWidgetKeys.requestsTestField('type'),
                  label: AppStrings.testsType,
                  value: _selectedType,
                  hintText: AppStrings.testsTypePlaceholder,
                  items: [
                    for (final type in RequestTestType.values)
                      DropdownMenuItem<RequestTestType?>(
                        value: type,
                        child: Text(type.label),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      _selectedComparator = null;
                      _selectedTimeUnit = value == RequestTestType.responseTime
                          ? (_selectedTimeUnit ?? ResponseTimeUnit.ms)
                          : null;
                      _selectedSizeUnit = value == RequestTestType.responseSize
                          ? (_selectedSizeUnit ?? ResponseSizeUnit.b)
                          : null;
                    });
                  },
                ),
                if (_selectedType != null) ...[
                  const SizedBox(height: AppSpacing.small),
                  _DropdownField<RequestTestComparator?>(
                    fieldKey: AppWidgetKeys.requestsTestField('comparator'),
                    label: AppStrings.testsComparator,
                    value: _selectedComparator,
                    items: [
                      for (final comparator in _comparators)
                        DropdownMenuItem<RequestTestComparator?>(
                          value: comparator,
                          child: Text(comparator.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedComparator = value),
                  ),
                ],
                ..._buildDynamicFields(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFields(BuildContext context) {
    final widgets = <Widget>[];
    final type = _selectedType;
    final comparator = _selectedComparator;
    if (type == null || comparator == null) {
      return widgets;
    }

    if (type == RequestTestType.header ||
        (type == RequestTestType.headers &&
            (comparator == RequestTestComparator.containsKey ||
                comparator == RequestTestComparator.doesNotContainKey))) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _TextField(
          fieldKey: AppWidgetKeys.requestsTestField('header_name'),
          label: AppStrings.testsHeaderName,
          initialValue: _headerName ?? '',
          onChanged: (value) => _headerName = value,
        ),
      );
    }

    if (type == RequestTestType.cookie ||
        (type == RequestTestType.cookies &&
            (comparator == RequestTestComparator.containsKey ||
                comparator == RequestTestComparator.doesNotContainKey))) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _TextField(
          fieldKey: AppWidgetKeys.requestsTestField('cookie_name'),
          label: AppStrings.testsCookieName,
          initialValue: _cookieName ?? '',
          onChanged: (value) => _cookieName = value,
        ),
      );
    }

    if (type == RequestTestType.jsonPath) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _ActionField(
          fieldKey: AppWidgetKeys.requestsTestField('json_path'),
          label: AppStrings.testsJsonPath,
          value: _jsonPath?.trim().isNotEmpty == true
              ? _jsonPath!
              : AppStrings.testsUpdateValue,
          onTap: () => _editTextValue(
            title: AppStrings.testsJsonPath,
            initialValue: _jsonPath,
            onSaved: (value) => _jsonPath = value,
          ),
        ),
      );
    }

    if (type == RequestTestType.xPath) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _ActionField(
          fieldKey: AppWidgetKeys.requestsTestField('xpath'),
          label: AppStrings.testsXPath,
          value: _xPath?.trim().isNotEmpty == true
              ? _xPath!
              : AppStrings.testsUpdateValue,
          onTap: () => _editTextValue(
            title: AppStrings.testsXPath,
            initialValue: _xPath,
            onSaved: (value) => _xPath = value,
          ),
        ),
      );
    }

    if (comparator.needsRangeValues) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _TextField(
          fieldKey: AppWidgetKeys.requestsTestField('min_value'),
          label: AppStrings.testsMinValue,
          initialValue: _minValue ?? '',
          keyboardType: TextInputType.number,
          onChanged: (value) => _minValue = value,
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _TextField(
          fieldKey: AppWidgetKeys.requestsTestField('max_value'),
          label: AppStrings.testsMaxValue,
          initialValue: _maxValue ?? '',
          keyboardType: TextInputType.number,
          onChanged: (value) => _maxValue = value,
        ),
      );
    } else if (_showsExpectedValue) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      final useActionEditor = type == RequestTestType.responseBody ||
          type == RequestTestType.header ||
          type == RequestTestType.cookie ||
          type == RequestTestType.jsonPath ||
          type == RequestTestType.xPath;
      widgets.add(
        useActionEditor
            ? _ActionField(
                fieldKey: AppWidgetKeys.requestsTestField('expected_value'),
                label: AppStrings.testsExpectedValue,
                value: _expectedValue?.trim().isNotEmpty == true
                    ? _expectedValue!
                    : AppStrings.testsUpdateValue,
                onTap: () => _editTextValue(
                  title: AppStrings.testsExpectedValue,
                  initialValue: _expectedValue,
                  onSaved: (value) => _expectedValue = value,
                ),
              )
            : _TextField(
                fieldKey: AppWidgetKeys.requestsTestField('expected_value'),
                label: AppStrings.testsExpectedValue,
                initialValue: _expectedValue ?? '',
                keyboardType: _isNumericType(type)
                    ? TextInputType.number
                    : TextInputType.text,
                onChanged: (value) => _expectedValue = value,
              ),
      );
    }

    if (type == RequestTestType.responseTime) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _DropdownField<ResponseTimeUnit?>(
          fieldKey: AppWidgetKeys.requestsTestField('time_unit'),
          label: AppStrings.testsTimeUnit,
          value: _selectedTimeUnit,
          items: [
            for (final unit in ResponseTimeUnit.values)
              DropdownMenuItem<ResponseTimeUnit?>(
                value: unit,
                child: Text(unit.label),
              ),
          ],
          onChanged: (value) => setState(() => _selectedTimeUnit = value),
        ),
      );
    }

    if (type == RequestTestType.responseSize) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        _DropdownField<ResponseSizeUnit?>(
          fieldKey: AppWidgetKeys.requestsTestField('size_unit'),
          label: AppStrings.testsSizeUnit,
          value: _selectedSizeUnit,
          items: [
            for (final unit in ResponseSizeUnit.values)
              DropdownMenuItem<ResponseSizeUnit?>(
                value: unit,
                child: Text(unit.label),
              ),
          ],
          onChanged: (value) => setState(() => _selectedSizeUnit = value),
        ),
      );
    }

    if (_showsCaseSensitive) {
      widgets.add(const SizedBox(height: AppSpacing.small));
      widgets.add(
        SwitchListTile.adaptive(
          key: ValueKey<String>(AppWidgetKeys.requestsTestField('case_sensitive')),
          contentPadding: EdgeInsets.zero,
          value: _caseSensitive,
          title: const Text(AppStrings.testsCaseSensitive),
          onChanged: (value) => setState(() => _caseSensitive = value),
        ),
      );
    }

    return widgets;
  }

  bool _isNumericType(RequestTestType type) =>
      type == RequestTestType.statusCode ||
      type == RequestTestType.responseTime ||
      type == RequestTestType.responseSize ||
      (type == RequestTestType.headers &&
          _selectedComparator == RequestTestComparator.countIs) ||
      (type == RequestTestType.cookies &&
          _selectedComparator == RequestTestComparator.countIs);

  String? _normalizedNullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

Future<String?> showRequestTestTextValueEditorSheet(
  BuildContext context, {
  required String title,
  required String initialValue,
}) => showRequestModalSheet<String>(
  context,
  builder: (context) => _RequestTestTextValueEditorSheet(
    title: title,
    initialValue: initialValue,
  ),
);

class _RequestTestTextValueEditorSheet extends StatefulWidget {
  const _RequestTestTextValueEditorSheet({
    required this.title,
    required this.initialValue,
  });

  final String title;
  final String initialValue;

  @override
  State<_RequestTestTextValueEditorSheet> createState() =>
      _RequestTestTextValueEditorSheetState();
}

class _RequestTestTextValueEditorSheetState
    extends State<_RequestTestTextValueEditorSheet> {
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
  Widget build(BuildContext context) {
    return RequestModalSheetCard(
      key: const ValueKey<String>(AppWidgetKeys.requestsTestValueEditorSheet),
      child: Column(
        children: [
          _TestsSheetHeader(
            title: widget.title,
            onClose: () => Navigator.of(context).pop(),
            trailing: IconButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              icon: const Icon(CupertinoIcons.check_mark),
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
                  AppWidgetKeys.requestsTestField(widget.title.toLowerCase()),
                ),
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: _inputDecoration(context, widget.title),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestsSheetHeader extends StatelessWidget {
  const _TestsSheetHeader({
    required this.title,
    required this.onClose,
    this.onAdd,
    this.trailing,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onAdd;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.medium,
      AppSpacing.small,
      AppSpacing.medium,
      AppSpacing.medium,
    ),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey<String>(AppWidgetKeys.requestsTestsCloseButton),
          onPressed: onClose,
          icon: const Icon(CupertinoIcons.xmark),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        trailing ??
            IconButton(
              key: const ValueKey<String>(AppWidgetKeys.requestsTestsAddButton),
              onPressed: onAdd,
              icon: const Icon(CupertinoIcons.add),
            ),
      ],
    ),
  );
}

class _EmptyTestsState extends StatelessWidget {
  const _EmptyTestsState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.testsNoTestsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            AppStrings.testsNoTestsMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TestListCard extends StatelessWidget {
  const _TestListCard({
    required this.test,
    required this.onTap,
    required this.onLongPress,
  });

  final RequestTest test;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => Material(
    color: context.appColors.surface,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Text(
          buildRequestTestLabel(test),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
  );
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final String fieldKey;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    key: ValueKey<String>(fieldKey),
    initialValue: value,
    items: items,
    hint: hintText == null ? null : Text(hintText!),
    onChanged: onChanged,
    decoration: _inputDecoration(context, label),
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
  );
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.fieldKey,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
  });

  final String fieldKey;
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
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
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey<String>(widget.fieldKey),
    controller: _controller,
    keyboardType: widget.keyboardType,
    onChanged: widget.onChanged,
    decoration: _inputDecoration(context, widget.label),
  );
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String fieldKey;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.appColors.surface,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    child: InkWell(
      key: ValueKey<String>(fieldKey),
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _inputDecoration(BuildContext context, String label) =>
    InputDecoration(
      labelText: label,
      filled: true,
      fillColor: context.appColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        borderSide: BorderSide(color: context.appColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        borderSide: BorderSide(color: context.appColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        borderSide: BorderSide(color: context.appColors.primary),
      ),
    );

enum _RequestTestAction { edit, delete }
