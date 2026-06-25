import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/theme/app_theme_colors.dart';
import 'request_modal_sheet.dart';

/// Opens the generated cURL preview sheet for the current request draft.
Future<void> showViewCurlSheet(
  BuildContext context, {
  required String curlCommand,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => _ViewCurlSheet(curlCommand: curlCommand),
);

class _ViewCurlSheet extends StatelessWidget {
  const _ViewCurlSheet({required this.curlCommand});

  final String curlCommand;

  /// Builds the full cURL preview sheet with header actions and command body.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.viewCurlSheet),
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.small),
        _ViewCurlHeader(curlCommand: curlCommand),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: curlCommand.trim().isEmpty
              ? const _ViewCurlEmptyState()
              : _CurlCommandViewer(command: curlCommand),
        ),
      ],
    ),
  );
}

class _ViewCurlHeader extends StatelessWidget {
  const _ViewCurlHeader({required this.curlCommand});

  final String curlCommand;

  /// Builds close, title, and copy actions for the cURL sheet.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey<String>(AppWidgetKeys.viewCurlCloseButton),
            tooltip: 'Close',
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
              'View curl',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          IconButton(
            key: const ValueKey<String>(AppWidgetKeys.viewCurlShareButton),
            tooltip: 'Copy cURL',
            onPressed: curlCommand.trim().isEmpty
                ? null
                : () => _copyCurlCommand(context),
            style: IconButton.styleFrom(
              backgroundColor: colors.background,
              foregroundColor: colors.iconPrimary,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(CupertinoIcons.square_on_square),
          ),
        ],
      ),
    );
  }

  /// Copies only the generated command text and confirms the action.
  Future<void> _copyCurlCommand(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: curlCommand));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('cURL copied.')));
  }
}

class _ViewCurlEmptyState extends StatelessWidget {
  const _ViewCurlEmptyState();

  /// Shows a friendly message when cURL generation cannot produce a command.
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Text(
        'Could not generate cURL.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: context.appColors.textSecondary),
      ),
    ),
  );
}

class _CurlCommandViewer extends StatelessWidget {
  const _CurlCommandViewer({required this.command});

  final String command;

  /// Renders the cURL command with line numbers and selectable code text.
  @override
  Widget build(BuildContext context) {
    final lines = command.split('\n');

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.small,
          AppSpacing.medium,
          AppSpacing.large,
        ),
        itemCount: lines.length,
        itemBuilder: (context, index) =>
            _CurlCommandLine(lineNumber: index + 1, text: lines[index]),
      ),
    );
  }
}

class _CurlCommandLine extends StatelessWidget {
  const _CurlCommandLine({required this.lineNumber, required this.text});

  final int lineNumber;
  final String text;

  /// Builds one numbered command row without allowing text to resize the gutter.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final codeStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textPrimary,
      fontFamily: 'monospace',
      height: 1.5,
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
              textAlign: TextAlign.right,
              style: codeStyle?.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.medium),
                ),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                child: Text.rich(
                  TextSpan(children: _buildSpans(context, text, codeStyle)),
                  softWrap: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Applies lightweight syntax colors to flags and quoted values.
  List<TextSpan> _buildSpans(
    BuildContext context,
    String line,
    TextStyle? baseStyle,
  ) {
    final colors = context.appColors;
    final spans = <TextSpan>[];
    final tokenPattern = RegExp(r'''("[^"]*"|'[^']*'|--?[A-Za-z0-9-]+|curl)''');
    var cursor = 0;

    for (final match in tokenPattern.allMatches(line)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: line.substring(cursor, match.start), style: baseStyle),
        );
      }

      final token = match.group(0) ?? '';
      spans.add(
        TextSpan(
          text: token,
          style: baseStyle?.copyWith(color: _tokenColor(token, colors)),
        ),
      );
      cursor = match.end;
    }

    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor), style: baseStyle));
    }

    return spans;
  }

  /// Chooses a theme token for a cURL syntax token.
  Color _tokenColor(String token, AppThemeColors colors) {
    if (token == 'curl' || token.startsWith('-')) {
      return colors.codeKey;
    }

    if (token.startsWith('"') || token.startsWith("'")) {
      return colors.codeString;
    }

    return colors.textPrimary;
  }
}
