import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/parsed_response.dart';
import '../../domain/entities/request_variable_store.dart';
import '../bloc/request_send_bloc.dart';
import '../bloc/request_send_event.dart';
import '../bloc/request_send_state.dart';
import '../cubit/request_editor_cubit.dart';
import '../models/request_editor_response_badge_data.dart';
import 'request_modal_sheet.dart';

/// Opens the response viewer as a full-screen slide-up sheet layered above the editor.
Future<RequestEditorResponseBadgeData?> showRequestResponseSheet(
  BuildContext context, {
  required RequestEditorCubit requestEditorCubit,
  required RequestSendBloc requestSendBloc,
  required RequestVariableStore variableStore,
}) => showRequestModalSheet<RequestEditorResponseBadgeData>(
  context,
  builder: (context) => MultiBlocProvider(
    providers: [
      BlocProvider<RequestEditorCubit>.value(value: requestEditorCubit),
      BlocProvider<RequestSendBloc>.value(value: requestSendBloc),
    ],
    child: _RequestResponseSheet(variableStore: variableStore),
  ),
);

class _RequestResponseSheet extends StatelessWidget {
  const _RequestResponseSheet({required this.variableStore});

  final RequestVariableStore variableStore;

  /// Builds the live response sheet from the current request send pipeline state.
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RequestSendBloc, RequestSendState>(
        builder: (context, state) => RequestModalSheetCard(
          key: const ValueKey<String>(AppWidgetKeys.requestsResponseSheet),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.small),
              _ResponseHeader(
                summaryLabel: _summaryLabel(state),
                onClose: () => _close(context, state),
                onResend: () => _resend(context),
                isSending: state.status == RequestSendStatus.sending,
              ),
              const SizedBox(height: AppSpacing.small),
              Expanded(child: _ResponseBody(state: state)),
              const _ResponseActionBar(),
            ],
          ),
        ),
      );

  /// Re-runs the current editor draft through the real send pipeline.
  void _resend(BuildContext context) {
    final draft = context.read<RequestEditorCubit>().state.draft;

    context.read<RequestSendBloc>().add(const RequestSendResetRequested());
    context.read<RequestSendBloc>().add(
      RequestSendRequested(draft: draft, variableStore: variableStore),
    );
  }

  /// Closes the response layer and returns the latest execution badge when one exists.
  void _close(BuildContext context, RequestSendState state) {
    final executionResult = state.executionResult;
    final badgeData = executionResult == null
        ? null
        : RequestEditorResponseBadgeData.fromExecutionResult(executionResult);

    Navigator.of(context).pop(badgeData);
  }

  /// Formats the response summary badge label from the active send state.
  String _summaryLabel(RequestSendState state) {
    if (state.status == RequestSendStatus.sending) {
      return 'Sending...';
    }

    final executionResult = state.executionResult;
    if (executionResult != null) {
      return RequestEditorResponseBadgeData.fromExecutionResult(
        executionResult,
      ).displayLabel;
    }

    if (state.status == RequestSendStatus.blocked) {
      return 'Blocked';
    }

    return 'Response';
  }
}

class _ResponseHeader extends StatelessWidget {
  const _ResponseHeader({
    required this.summaryLabel,
    required this.onClose,
    required this.onResend,
    required this.isSending,
  });

  final String summaryLabel;
  final VoidCallback onClose;
  final VoidCallback onResend;
  final bool isSending;

  /// Builds the top row for the response sheet with close, summary, and resend actions.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsResponseCloseButton,
            ),
            tooltip: AppStrings.requestResponseCloseTooltip,
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: colors.background,
              foregroundColor: colors.iconPrimary,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: _ResponseSummaryBadge(label: summaryLabel)),
          const SizedBox(width: AppSpacing.medium),
          _SheetSendButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsResponseSendButton,
            ),
            onPressed: onResend,
            isLoading: isSending,
          ),
        ],
      ),
    );
  }
}

class _ResponseSummaryBadge extends StatelessWidget {
  const _ResponseSummaryBadge({required this.label});

  final String label;

  /// Displays status, payload size, and response time in the response sheet header.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return DecoratedBox(
      key: const ValueKey<String>(AppWidgetKeys.requestsResponseSummaryBadge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.small,
              height: AppSpacing.small,
              decoration: BoxDecoration(
                color: colors.methodPost,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonViewer extends StatelessWidget {
  const _JsonViewer({required this.body});

  final String body;

  /// Renders pretty JSON with line numbers and lightweight token colors.
  @override
  Widget build(BuildContext context) {
    final lines = body.split('\n');

    return SizedBox(
      width: double.infinity,
      child: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
          child: Scrollbar(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: lines.length,
              itemBuilder: (context, index) =>
                  _JsonLineRow(lineNumber: index + 1, content: lines[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponseBody extends StatelessWidget {
  const _ResponseBody({required this.state});

  final RequestSendState state;

  /// Chooses the most useful body representation for loading, blocked, error, and success states.
  @override
  Widget build(BuildContext context) => _JsonViewer(body: _buildBodyText());

  /// Builds the textual body shown in the response viewer from parsed output or pipeline issues.
  String _buildBodyText() {
    if (state.status == RequestSendStatus.sending) {
      return 'Sending request...';
    }

    final parsedResponse = state.parsedResponse;
    if (parsedResponse != null &&
        parsedResponse.formattedBody.trim().isNotEmpty) {
      return parsedResponse.formattedBody;
    }

    final issueLines = <String>[
      if (state.errorMessage.trim().isNotEmpty) state.errorMessage.trim(),
      ...state.resolutionIssues.map(
        (issue) =>
            'Resolution issue: ${issue.placeholder} (${issue.type.name})',
      ),
      ...state.authIssues.map((issue) => 'Auth issue: ${issue.message}'),
    ];

    if (issueLines.isNotEmpty) {
      return issueLines.join('\n');
    }

    if (parsedResponse != null) {
      return _fallbackBodyForParsedResponse(parsedResponse);
    }

    return 'No response body.';
  }

  /// Provides a fallback description when the parser produced metadata but no formatted body.
  String _fallbackBodyForParsedResponse(ParsedResponse parsedResponse) =>
      switch (parsedResponse.bodyType) {
        ParsedResponseBodyType.empty => 'No response body.',
        ParsedResponseBodyType.binary => 'Binary response received.',
        ParsedResponseBodyType.error => parsedResponse.execution.errorMessage,
        _ => parsedResponse.execution.bodyText,
      };
}

class _JsonLineRow extends StatelessWidget {
  const _JsonLineRow({required this.lineNumber, required this.content});

  final int lineNumber;
  final String content;

  /// Displays one numbered line inside the response body viewer.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: colors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.xxLarge + AppSpacing.small,
            child: Text(
              '$lineNumber',
              style: baseStyle?.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.xxxSmall),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: baseStyle,
                children: _highlightJson(content, baseStyle, colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Colors JSON keys, strings, numbers, and booleans for quick scanning.
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
}

class _ResponseActionBar extends StatelessWidget {
  const _ResponseActionBar();

  /// Builds the iOS-style bottom action row for response-specific controls.
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: Row(
        children: const [
          _BodySelectorChip(),
          Spacer(),
          _CircularActionButton(icon: CupertinoIcons.list_bullet),
          SizedBox(width: AppSpacing.small),
          _CircularActionButton(icon: CupertinoIcons.square_arrow_up),
          SizedBox(width: AppSpacing.small),
          _CircularActionButton(icon: CupertinoIcons.ellipsis),
        ],
      ),
    ),
  );
}

class _BodySelectorChip extends StatelessWidget {
  const _BodySelectorChip();

  /// Shows the active body tab selector in the response action bar.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.requestResponseBodySelector,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: AppSpacing.xxSmall),
            Icon(
              CupertinoIcons.chevron_up_chevron_down,
              size: AppSpacing.medium,
              color: colors.iconPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  const _CircularActionButton({required this.icon});

  final IconData icon;

  /// Renders one placeholder action button in the response action bar.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      child: SizedBox(
        width: AppSpacing.xLarge + AppSpacing.small,
        height: AppSpacing.xLarge + AppSpacing.small,
        child: Icon(icon, color: colors.iconPrimary),
      ),
    );
  }
}

class _SheetSendButton extends StatelessWidget {
  const _SheetSendButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  /// Renders the reusable blue pill send action used in the response sheet.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.methodGet,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: AppSpacing.medium,
                  height: AppSpacing.medium,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
              ],
              Text(
                AppStrings.requestEditorSend,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: colors.textOnPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
