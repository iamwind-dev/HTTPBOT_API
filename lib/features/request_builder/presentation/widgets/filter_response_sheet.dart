import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/app_popup_menu.dart';
import '../../../../injection/injection.dart';
import '../../domain/helpers/filter_response_mode.dart';
import '../../domain/repositories/response_filter_repository.dart';
import '../cubit/filter_response_cubit.dart';
import '../cubit/filter_response_state.dart';
import '../cubit/response_filters_cubit.dart';
import 'request_modal_sheet.dart';
import 'response_filter_editor_sheet.dart';
import 'response_filters_sheet.dart';

/// Opens the Filter Response sheet for the current response body.
Future<void> showFilterResponseSheet(
  BuildContext context, {
  required String body,
  String? contentType,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => BlocProvider<FilterResponseCubit>(
    create: (_) => FilterResponseCubit(body: body, contentType: contentType),
    child: const _FilterResponseSheet(),
  ),
);

class _FilterResponseSheet extends StatefulWidget {
  const _FilterResponseSheet();

  @override
  State<_FilterResponseSheet> createState() => _FilterResponseSheetState();
}

class _FilterResponseSheetState extends State<_FilterResponseSheet> {
  final TextEditingController _queryController = TextEditingController();
  bool _wrap = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.filterResponseSheet),
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.small),
        _FilterResponseHeader(
          queryController: _queryController,
          wrap: _wrap,
          onToggleWrap: () => setState(() => _wrap = !_wrap),
        ),
        const SizedBox(height: AppSpacing.small),
        Expanded(child: _FilterResponseResultViewer(wrap: _wrap)),
        _FilterResponseQueryBar(queryController: _queryController),
      ],
    ),
  );
}

class _FilterResponseHeader extends StatelessWidget {
  const _FilterResponseHeader({
    required this.queryController,
    required this.wrap,
    required this.onToggleWrap,
  });

  final TextEditingController queryController;
  final bool wrap;
  final VoidCallback onToggleWrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.filterResponseCloseButton,
            ),
            tooltip: AppStrings.filterResponseCloseTooltip,
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: colors.background,
              foregroundColor: colors.iconPrimary,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              AppStrings.filterResponseTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          _FilterResponseMoreButton(
            queryController: queryController,
            wrap: wrap,
            onToggleWrap: onToggleWrap,
          ),
        ],
      ),
    );
  }
}

class _FilterResponseMoreButton extends StatelessWidget {
  const _FilterResponseMoreButton({
    required this.queryController,
    required this.wrap,
    required this.onToggleWrap,
  });

  final TextEditingController queryController;
  final bool wrap;
  final VoidCallback onToggleWrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopupMenuButton<_FilterMoreAction>(
      key: const ValueKey<String>(AppWidgetKeys.filterResponseMoreButton),
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (context) => [
        const PopupMenuItem<_FilterMoreAction>(
          value: _FilterMoreAction.help,
          child: AppPopupMenuRow(
            icon: CupertinoIcons.question_circle,
            label: AppStrings.filterResponseHelp,
          ),
        ),
        PopupMenuItem<_FilterMoreAction>(
          value: _FilterMoreAction.wrap,
          child: AppPopupMenuRow(
            icon: CupertinoIcons.textformat,
            label: AppStrings.filterResponseWrap,
            trailing: wrap
                ? const Icon(CupertinoIcons.check_mark, size: 16)
                : null,
          ),
        ),
        const PopupMenuItem<_FilterMoreAction>(
          value: _FilterMoreAction.saveQuery,
          child: AppPopupMenuRow(
            icon: CupertinoIcons.square_arrow_down,
            label: AppStrings.filterResponseSaveQuery,
          ),
        ),
        const PopupMenuItem<_FilterMoreAction>(
          value: _FilterMoreAction.manageQueries,
          child: AppPopupMenuRow(
            icon: CupertinoIcons.folder,
            label: AppStrings.filterResponseManageQueries,
          ),
        ),
        const PopupMenuItem<_FilterMoreAction>(
          value: _FilterMoreAction.copyResult,
          child: AppPopupMenuRow(
            icon: CupertinoIcons.doc_on_doc,
            label: AppStrings.filterResponseCopyResult,
          ),
        ),
        const PopupMenuItem<_FilterMoreAction>(
          value: _FilterMoreAction.copyQuery,
          child: AppPopupMenuRow(
            icon: CupertinoIcons.doc_on_clipboard,
            label: AppStrings.filterResponseCopyQuery,
          ),
        ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(CupertinoIcons.ellipsis),
        ),
      ),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    _FilterMoreAction action,
  ) async {
    switch (action) {
      case _FilterMoreAction.help:
        await _showHelp(context);
      case _FilterMoreAction.wrap:
        onToggleWrap();
      case _FilterMoreAction.saveQuery:
        await _saveQuery(context);
      case _FilterMoreAction.manageQueries:
        await _manageQueries(context);
      case _FilterMoreAction.copyResult:
        await _copy(
          context,
          context.read<FilterResponseCubit>().state.displayText,
          AppStrings.filterResponseResultCopied,
        );
      case _FilterMoreAction.copyQuery:
        await _copy(
          context,
          queryController.text,
          AppStrings.filterResponseQueryCopied,
        );
    }
  }

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    _toast(context, message);
  }

  Future<void> _showHelp(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.filterResponseHelpTitle),
      content: const Text(
        AppStrings.filterResponseHelpBody,
        style: TextStyle(fontFamily: 'monospace'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<void> _saveQuery(BuildContext context) async {
    final cubit = context.read<FilterResponseCubit>();
    final query = queryController.text.trim();
    if (query.isEmpty) {
      _toast(context, AppStrings.filterResponseSaveEmpty);
      return;
    }

    final draft = await showResponseFilterEditorSheet(
      context,
      initialQuery: query,
      initialMode: cubit.state.mode,
    );
    if (draft == null || !context.mounted) {
      return;
    }

    await ResponseFiltersCubit(
      getIt<ResponseFilterRepository>(),
    ).create(name: draft.name, query: draft.query, mode: draft.mode);
    if (!context.mounted) {
      return;
    }
    _toast(context, AppStrings.filterResponseSaved);
  }

  Future<void> _manageQueries(BuildContext context) async {
    final cubit = context.read<FilterResponseCubit>();
    final selected = await showResponseFiltersSheet(context, pickMode: true);
    if (selected == null) {
      return;
    }
    queryController.text = selected.query;
    cubit.applySavedFilter(mode: selected.mode, query: selected.query);
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _FilterMoreAction {
  help,
  wrap,
  saveQuery,
  manageQueries,
  copyResult,
  copyQuery,
}

class _FilterResponseResultViewer extends StatelessWidget {
  const _FilterResponseResultViewer({required this.wrap});

  final bool wrap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterResponseCubit, FilterResponseState>(
      builder: (context, state) {
        if (state.hasError) {
          return _CenteredMessage(message: state.displayText);
        }

        final lines = state.displayText.split('\n');
        return SelectionArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            child: Scrollbar(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: lines.length,
                itemBuilder: (context, index) => _CodeLineRow(
                  lineNumber: index + 1,
                  content: lines[index],
                  wrap: wrap,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CodeLineRow extends StatelessWidget {
  const _CodeLineRow({
    required this.lineNumber,
    required this.content,
    required this.wrap,
  });

  final int lineNumber;
  final String content;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: colors.textPrimary,
    );

    final richText = Text.rich(
      TextSpan(
        style: baseStyle,
        children: _highlightJson(content, baseStyle, colors),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.xLarge,
            child: Text(
              '$lineNumber',
              style: baseStyle?.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: wrap
                ? richText
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: richText,
                  ),
          ),
        ],
      ),
    );
  }
}

List<InlineSpan> _highlightJson(
  String line,
  TextStyle? baseStyle,
  AppThemeColors colors,
) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(
    r'("(?:\\.|[^"])*")(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d+)?',
  );
  var currentIndex = 0;

  for (final match in pattern.allMatches(line)) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: line.substring(currentIndex, match.start)));
    }

    final token = match.group(0) ?? '';
    final isKey = match.group(2) != null;
    final color = switch (token) {
      'true' || 'false' || 'null' => colors.codeLiteral,
      _ when isKey => colors.codeKey,
      _ when token.startsWith('"') => colors.codeString,
      _ => colors.codeNumber,
    };

    spans.add(
      TextSpan(
        text: token,
        style: baseStyle?.copyWith(color: color),
      ),
    );
    currentIndex = match.end;
  }

  if (currentIndex < line.length) {
    spans.add(TextSpan(text: line.substring(currentIndex)));
  }

  return spans;
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    ),
  );
}

class _FilterResponseQueryBar extends StatelessWidget {
  const _FilterResponseQueryBar({required this.queryController});

  final TextEditingController queryController;

  static const _tokensByMode = <FilterResponseMode, List<String>>{
    FilterResponseMode.jq: ['.', '|', '[', ']'],
    FilterResponseMode.jsonPath: [r'$', '.', '[', ']', '*'],
    FilterResponseMode.xPath: ['/', '//', '@', '=', 'text()'],
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.small,
          AppSpacing.medium,
          AppSpacing.medium,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.large),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<FilterResponseCubit, FilterResponseState>(
                  buildWhen: (previous, current) =>
                      previous.mode != current.mode,
                  builder: (context, state) => Row(
                    children: [
                      for (final token in _tokensByMode[state.mode]!) ...[
                        _QuickTokenButton(
                          token: token,
                          onTap: () => _insertToken(token),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                      ],
                      const Spacer(),
                      const _FilterResponseModePicker(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                _QueryTextField(queryController: queryController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _insertToken(String token) {
    final insertText = token == '|' ? ' | ' : token;
    final selection = queryController.selection;
    final text = queryController.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final updated = text.replaceRange(start, end, insertText);
    queryController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + insertText.length),
    );
  }
}

class _QueryTextField extends StatelessWidget {
  const _QueryTextField({required this.queryController});

  final TextEditingController queryController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterResponseCubit, FilterResponseState>(
      buildWhen: (previous, current) => previous.mode != current.mode,
      builder: (context, state) => TextField(
        key: const ValueKey<String>(AppWidgetKeys.filterResponseQueryField),
        controller: queryController,
        onChanged: context.read<FilterResponseCubit>().queryChanged,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: _placeholder(state.mode),
        ),
      ),
    );
  }

  String _placeholder(FilterResponseMode mode) => switch (mode) {
    FilterResponseMode.jq => AppStrings.filterResponseJqPlaceholder,
    FilterResponseMode.jsonPath => AppStrings.filterResponseJsonPathPlaceholder,
    FilterResponseMode.xPath => AppStrings.filterResponseXPathPlaceholder,
  };
}

class _QuickTokenButton extends StatelessWidget {
  const _QuickTokenButton({required this.token, required this.onTap});

  final String token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey<String>(AppWidgetKeys.filterResponseToken(token)),
    onTap: onTap,
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.small)),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xSmall,
        vertical: AppSpacing.xxSmall,
      ),
      child: Text(
        token,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: context.appColors.primary,
          fontFamily: 'monospace',
        ),
      ),
    ),
  );
}

class _FilterResponseModePicker extends StatelessWidget {
  const _FilterResponseModePicker();

  // Order must match the screenshot: XPath, JSONPath, jq.
  static const _orderedModes = [
    FilterResponseMode.xPath,
    FilterResponseMode.jsonPath,
    FilterResponseMode.jq,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<FilterResponseCubit, FilterResponseState>(
      buildWhen: (previous, current) => previous.mode != current.mode,
      builder: (context, state) => PopupMenuButton<FilterResponseMode>(
        key: const ValueKey<String>(AppWidgetKeys.filterResponseModePicker),
        onSelected: context.read<FilterResponseCubit>().modeChanged,
        itemBuilder: (context) => [
          for (final mode in _orderedModes)
            PopupMenuItem<FilterResponseMode>(
              key: ValueKey<String>(
                AppWidgetKeys.filterResponseModeOption(mode.name),
              ),
              value: mode,
              child: Text(mode.label),
            ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.mode.label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.primary),
            ),
            Icon(
              CupertinoIcons.chevron_up_chevron_down,
              size: AppSpacing.medium,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
