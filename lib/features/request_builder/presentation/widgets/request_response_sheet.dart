import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/executed_request_snapshot.dart';
import '../../domain/entities/parsed_response.dart';
import '../../domain/entities/request_execution_result.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/request_variable_store.dart';
import '../bloc/request_send_bloc.dart';
import '../bloc/request_send_event.dart';
import '../bloc/request_send_state.dart';
import '../cubit/request_editor_cubit.dart';
import '../models/request_editor_response_badge_data.dart';
import 'request_modal_sheet.dart';

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

enum ResponseViewMode { request, metrics, tests, cookies, headers, body }

class _RequestResponseSheet extends StatefulWidget {
  const _RequestResponseSheet({required this.variableStore});

  final RequestVariableStore variableStore;

  @override
  State<_RequestResponseSheet> createState() => _RequestResponseSheetState();
}

class _RequestResponseSheetState extends State<_RequestResponseSheet> {
  ResponseViewMode _selectedMode = ResponseViewMode.body;

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
              Expanded(
                child: _ResponseContent(
                  state: state,
                  selectedMode: _selectedMode,
                ),
              ),
              _ResponseActionBar(
                selectedMode: _selectedMode,
                onModeSelected: (mode) {
                  setState(() {
                    _selectedMode = mode;
                  });
                },
              ),
            ],
          ),
        ),
      );

  void _resend(BuildContext context) {
    final draft = context.read<RequestEditorCubit>().state.draft;

    context.read<RequestSendBloc>().add(const RequestSendResetRequested());
    context.read<RequestSendBloc>().add(
      RequestSendRequested(draft: draft, variableStore: widget.variableStore),
    );
  }

  void _close(BuildContext context, RequestSendState state) {
    final executionResult = state.executionResult;
    final badgeData = executionResult == null
        ? null
        : RequestEditorResponseBadgeData.fromExecutionResult(executionResult);

    Navigator.of(context).pop(badgeData);
  }

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

class _ResponseContent extends StatelessWidget {
  const _ResponseContent({
    required this.state,
    required this.selectedMode,
  });

  final RequestSendState state;
  final ResponseViewMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final executionResult = state.executionResult;

    return switch (selectedMode) {
      ResponseViewMode.request => _RequestSnapshotView(
        executionResult: executionResult,
      ),
      ResponseViewMode.metrics => _MetricsView(executionResult: executionResult),
      ResponseViewMode.tests => _ResponseTestsView(executionResult: executionResult),
      ResponseViewMode.cookies => _CookiesView(executionResult: executionResult),
      ResponseViewMode.headers => _HeadersView(executionResult: executionResult),
      ResponseViewMode.body => _JsonViewer(body: _buildBodyText()),
    };
  }

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

  String _fallbackBodyForParsedResponse(ParsedResponse parsedResponse) =>
      switch (parsedResponse.bodyType) {
        ParsedResponseBodyType.empty => 'No response body.',
        ParsedResponseBodyType.binary => 'Binary response received.',
        ParsedResponseBodyType.error => parsedResponse.execution.errorMessage,
        _ => parsedResponse.execution.bodyText,
      };
}

class _ResponseActionBar extends StatelessWidget {
  const _ResponseActionBar({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final ResponseViewMode selectedMode;
  final ValueChanged<ResponseViewMode> onModeSelected;

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
        children: [
          _ResponseViewSelectorButton(
            selectedMode: selectedMode,
            onSelected: onModeSelected,
          ),
          const Spacer(),
          const _CircularActionButton(icon: CupertinoIcons.list_bullet),
          const SizedBox(width: AppSpacing.small),
          const _CircularActionButton(icon: CupertinoIcons.square_arrow_up),
          const SizedBox(width: AppSpacing.small),
          const _CircularActionButton(icon: CupertinoIcons.ellipsis),
        ],
      ),
    ),
  );
}

class _ResponseViewSelectorButton extends StatelessWidget {
  const _ResponseViewSelectorButton({
    required this.selectedMode,
    required this.onSelected,
  });

  final ResponseViewMode selectedMode;
  final ValueChanged<ResponseViewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopupMenuButton<ResponseViewMode>(
      key: const ValueKey<String>(
        AppWidgetKeys.requestsResponseViewSelectorButton,
      ),
      tooltip: selectedMode.label,
      color: colors.surface,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final mode in ResponseViewMode.values)
          PopupMenuItem<ResponseViewMode>(
            key: ValueKey<String>(
              AppWidgetKeys.requestsResponseViewSelectorItem(mode.name),
            ),
            value: mode,
            child: Text(mode.label),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary,
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
                selectedMode.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textOnPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xxxSmall),
              Icon(
                CupertinoIcons.chevron_down,
                size: AppSpacing.medium,
                color: colors.textOnPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestSnapshotView extends StatelessWidget {
  const _RequestSnapshotView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    final snapshot = executionResult?.executedRequestSnapshot;
    if (snapshot == null) {
      return const _CenteredEmptyState(
        title: AppStrings.requestResponseViewRequest,
        message: 'No request snapshot available.',
      );
    }

    final requestHeaders = snapshot.headers.entries.toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      children: [
        _InfoCard(
          child: Text(
            '${snapshot.method} ${snapshot.url}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _SectionCard(
          title: AppStrings.requestResponseRequestHeaders,
          child: requestHeaders.isEmpty
              ? const Text(AppStrings.requestResponseNoHeaders)
              : Column(
                  children: [
                    for (final header in requestHeaders) ...[
                      _NameValueRow(name: header.key, value: header.value),
                      if (header != requestHeaders.last)
                        const SizedBox(height: AppSpacing.small),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.small),
        _SectionCard(
          title: AppStrings.requestResponseRequestBody,
          child: _BodyPreviewText(
            text: snapshot.body?.trim().isNotEmpty == true
                ? snapshot.body!
                : AppStrings.requestResponseRequestBodyEmpty,
          ),
        ),
      ],
    );
  }
}

class _MetricsView extends StatelessWidget {
  const _MetricsView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    if (executionResult == null) {
      return const _CenteredEmptyState(
        title: AppStrings.requestResponseNoMetrics,
      );
    }

    final snapshot = executionResult!.executedRequestSnapshot;
    final metrics = <MapEntry<String, String>>[
      MapEntry(
        AppStrings.requestResponseStatus,
        executionResult!.statusCode?.toString() ?? 'Unknown',
      ),
      MapEntry(
        AppStrings.requestResponseSize,
        '${executionResult!.payloadSizeBytes} B',
      ),
      MapEntry(
        AppStrings.requestResponseDuration,
        '${executionResult!.duration.inMilliseconds} ms',
      ),
      if (snapshot != null)
        MapEntry(AppStrings.requestResponseMethod, snapshot.method),
      if (snapshot != null)
        MapEntry(AppStrings.requestResponseUrl, snapshot.url),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      itemCount: metrics.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.small),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _InfoCard(child: _NameValueRow(name: metric.key, value: metric.value));
      },
    );
  }
}

class _HeadersView extends StatelessWidget {
  const _HeadersView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    final headers = executionResult?.headers ?? const <KeyValueItem>[];
    if (headers.isEmpty) {
      return const _CenteredEmptyState(title: AppStrings.requestResponseNoHeaders);
    }

    final groupedHeaders = _groupHeaders(headers);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      itemCount: groupedHeaders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.small),
      itemBuilder: (context, index) {
        final header = groupedHeaders[index];
        return _InfoCard(
          child: _NameValueRow(
            name: header.key,
            value: header.value.join('\n'),
          ),
        );
      },
    );
  }
}

class _CookiesView extends StatelessWidget {
  const _CookiesView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    final snapshot = executionResult?.executedRequestSnapshot;
    final sentCookies = _parseSentCookies(snapshot);
    final receivedCookies = _parseReceivedCookies(executionResult);

    if (sentCookies.isEmpty && receivedCookies.isEmpty) {
      return const _CenteredEmptyState(title: AppStrings.requestResponseNoCookies);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      children: [
        if (sentCookies.isNotEmpty)
          _SectionCard(
            title: AppStrings.requestResponseSentCookies,
            child: Column(
              children: [
                for (final cookie in sentCookies) ...[
                  _CookieDisplayTile(cookie: cookie),
                  if (cookie != sentCookies.last)
                    const SizedBox(height: AppSpacing.small),
                ],
              ],
            ),
          ),
        if (sentCookies.isNotEmpty && receivedCookies.isNotEmpty)
          const SizedBox(height: AppSpacing.small),
        if (receivedCookies.isNotEmpty)
          _SectionCard(
            title: AppStrings.requestResponseReceivedCookies,
            child: Column(
              children: [
                for (final cookie in receivedCookies) ...[
                  _CookieDisplayTile(cookie: cookie),
                  if (cookie != receivedCookies.last)
                    const SizedBox(height: AppSpacing.small),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ResponseTestsView extends StatelessWidget {
  const _ResponseTestsView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    final testResults = executionResult?.testResults ?? const [];
    if (testResults.isEmpty) {
      return const _CenteredEmptyState(
        title: AppStrings.testsNoTestsTitle,
        message: AppStrings.testsNoResponseRunMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      itemCount: testResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.small),
      itemBuilder: (context, index) {
        final result = testResults[index];
        final isPassed = result.isPassed;
        final accentColor = isPassed
            ? context.appColors.methodGet
            : context.appColors.methodDelete;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xxLarge),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isPassed
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.xmark_circle_fill,
                      color: accentColor,
                      size: AppSpacing.large,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        result.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if ((result.expected?.trim().isNotEmpty ?? false) ||
                    (result.actual?.trim().isNotEmpty ?? false) ||
                    (result.message?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: AppSpacing.small),
                  if (result.expected?.trim().isNotEmpty ?? false)
                    Text(
                      'Expected: ${result.expected}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (result.actual?.trim().isNotEmpty ?? false)
                    Text(
                      'Actual: ${result.actual}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (result.message?.trim().isNotEmpty ?? false)
                    Text(
                      result.message!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JsonViewer extends StatelessWidget {
  const _JsonViewer({required this.body});

  final String body;

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

class _JsonLineRow extends StatelessWidget {
  const _JsonLineRow({required this.lineNumber, required this.content});

  final int lineNumber;
  final String content;

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
        TextSpan(text: token, style: baseStyle?.copyWith(color: color)),
      );
      currentIndex = match.end;
    }

    if (currentIndex < line.length) {
      spans.add(TextSpan(text: line.substring(currentIndex)));
    }

    return spans;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => _InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.small),
        child,
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: child,
    ),
  );
}

class _CenteredEmptyState extends StatelessWidget {
  const _CenteredEmptyState({required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (message?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _NameValueRow extends StatelessWidget {
  const _NameValueRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: AppSpacing.xxxSmall),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
        ),
      ),
    ],
  );
}

class _BodyPreviewText extends StatelessWidget {
  const _BodyPreviewText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => SelectableText(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
    ),
  );
}

class _CookieDisplayTile extends StatelessWidget {
  const _CookieDisplayTile({required this.cookie});

  final _CookieDisplay cookie;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${cookie.name} = ${cookie.value}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
        ),
      ),
      if (cookie.attributes.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxxSmall),
        for (final attribute in cookie.attributes.entries)
          Text(
            '${attribute.key} = ${attribute.value}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
      ],
      if (cookie.rawValue != null && cookie.attributes.isEmpty)
        Text(
          cookie.rawValue!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
            fontFamily: 'monospace',
          ),
        ),
    ],
  );
}

class _CircularActionButton extends StatelessWidget {
  const _CircularActionButton({required this.icon});

  final IconData icon;

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

extension on ResponseViewMode {
  String get label => switch (this) {
    ResponseViewMode.request => AppStrings.requestResponseViewRequest,
    ResponseViewMode.metrics => AppStrings.requestResponseViewMetrics,
    ResponseViewMode.tests => AppStrings.requestResponseViewTests,
    ResponseViewMode.cookies => AppStrings.requestResponseViewCookies,
    ResponseViewMode.headers => AppStrings.requestResponseViewHeaders,
    ResponseViewMode.body => AppStrings.requestResponseViewBody,
  };
}

List<MapEntry<String, List<String>>> _groupHeaders(List<KeyValueItem> headers) {
  final grouped = <String, List<String>>{};
  final orderedKeys = <String>[];

  for (final header in headers) {
    final key = header.key.trim();
    if (key.isEmpty) {
      continue;
    }

    final existingKey = grouped.keys.firstWhere(
      (entry) => entry.toLowerCase() == key.toLowerCase(),
      orElse: () => '',
    );
    final canonicalKey = existingKey.isEmpty ? key : existingKey;
    if (existingKey.isEmpty) {
      orderedKeys.add(canonicalKey);
      grouped[canonicalKey] = <String>[];
    }
    grouped[canonicalKey]!.add(header.value);
  }

  return orderedKeys
      .map((key) => MapEntry(key, List<String>.unmodifiable(grouped[key]!)))
      .toList(growable: false);
}

List<_CookieDisplay> _parseSentCookies(ExecutedRequestSnapshot? snapshot) {
  if (snapshot == null) {
    return const [];
  }

  final cookieHeader = snapshot.headers.entries
      .where((entry) => entry.key.trim().toLowerCase() == 'cookie')
      .map((entry) => entry.value)
      .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
  if (cookieHeader.isEmpty) {
    return const [];
  }

  final parts = cookieHeader.split(';');
  final cookies = <_CookieDisplay>[];
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) {
      cookies.add(
        _CookieDisplay(name: trimmed, value: '', rawValue: trimmed),
      );
      continue;
    }

    cookies.add(
      _CookieDisplay(
        name: trimmed.substring(0, separatorIndex).trim(),
        value: trimmed.substring(separatorIndex + 1).trim(),
      ),
    );
  }

  return cookies;
}

List<_CookieDisplay> _parseReceivedCookies(RequestExecutionResult? result) {
  if (result == null) {
    return const [];
  }

  final setCookieHeaders = result.headers
      .where((header) => header.key.trim().toLowerCase() == 'set-cookie')
      .map((header) => header.value)
      .toList(growable: false);
  if (setCookieHeaders.isEmpty) {
    return result.responseCookies
        .map(
          (cookie) => _CookieDisplay(
            name: cookie.name,
            value: cookie.value,
            attributes: {
              'Domain': cookie.domain,
              'Path': cookie.path,
            },
          ),
        )
        .toList(growable: false);
  }

  return setCookieHeaders.map(_parseSetCookieHeader).toList(growable: false);
}

_CookieDisplay _parseSetCookieHeader(String rawHeader) {
  final segments = rawHeader
      .split(';')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty) {
    return _CookieDisplay(name: rawHeader, value: '', rawValue: rawHeader);
  }

  final firstSegment = segments.first;
  final separatorIndex = firstSegment.indexOf('=');
  if (separatorIndex <= 0) {
    return _CookieDisplay(
      name: firstSegment,
      value: '',
      rawValue: rawHeader,
    );
  }

  final attributes = <String, String>{};
  for (final segment in segments.skip(1)) {
    final attributeSeparatorIndex = segment.indexOf('=');
    if (attributeSeparatorIndex <= 0) {
      attributes[segment] = 'true';
      continue;
    }
    attributes[segment.substring(0, attributeSeparatorIndex).trim()] =
        segment.substring(attributeSeparatorIndex + 1).trim();
  }

  return _CookieDisplay(
    name: firstSegment.substring(0, separatorIndex).trim(),
    value: firstSegment.substring(separatorIndex + 1).trim(),
    attributes: attributes,
    rawValue: rawHeader,
  );
}

class _CookieDisplay {
  const _CookieDisplay({
    required this.name,
    required this.value,
    this.attributes = const <String, String>{},
    this.rawValue,
  });

  final String name;
  final String value;
  final Map<String, String> attributes;
  final String? rawValue;
}
