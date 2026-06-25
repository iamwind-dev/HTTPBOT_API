import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/executed_request_snapshot.dart';
import '../../domain/entities/http_exchange.dart';
import '../../domain/entities/parsed_response.dart';
import '../../domain/entities/request_execution_result.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/request_test_result.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/helpers/request_snapshot_formatter.dart';
import '../../domain/helpers/response_metrics_formatter.dart';
import '../bloc/request_send_bloc.dart';
import '../bloc/request_send_event.dart';
import '../bloc/request_send_state.dart';
import '../cubit/request_editor_cubit.dart';
import '../models/request_editor_response_badge_data.dart';
import 'filter_response_sheet.dart';
import 'request_history_sheet.dart';
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
  bool _wrapResponse = true;

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
                onTapStatus: () => showRequestHistorySheet(context),
                isSending: state.status == RequestSendStatus.sending,
              ),
              const SizedBox(height: AppSpacing.small),
              Expanded(
                child: _ResponseContent(
                  state: state,
                  selectedMode: _selectedMode,
                  wrapResponse: _wrapResponse,
                ),
              ),
              _ResponseActionBar(
                selectedMode: _selectedMode,
                executionResult: state.executionResult,
                parsedResponse: state.parsedResponse,
                wrapResponse: _wrapResponse,
                onModeSelected: (mode) {
                  setState(() {
                    _selectedMode = mode;
                  });
                },
                onToggleWrap: () {
                  setState(() {
                    _wrapResponse = !_wrapResponse;
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
    required this.onTapStatus,
    required this.isSending,
  });

  final String summaryLabel;
  final VoidCallback onClose;
  final VoidCallback onResend;
  final VoidCallback onTapStatus;
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
          Expanded(
            child: InkWell(
              onTap: onTapStatus,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.xxLarge),
              ),
              child: _ResponseSummaryBadge(label: summaryLabel),
            ),
          ),
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
    required this.wrapResponse,
  });

  final RequestSendState state;
  final ResponseViewMode selectedMode;
  final bool wrapResponse;

  @override
  Widget build(BuildContext context) {
    final executionResult = state.executionResult;

    return switch (selectedMode) {
      ResponseViewMode.request => _RequestSnapshotView(
        executionResult: executionResult,
      ),
      ResponseViewMode.metrics => _MetricsView(
        executionResult: executionResult,
      ),
      ResponseViewMode.tests => _ResponseTestsView(
        executionResult: executionResult,
      ),
      ResponseViewMode.cookies => _CookiesView(
        executionResult: executionResult,
      ),
      ResponseViewMode.headers => _HeadersView(
        executionResult: executionResult,
      ),
      ResponseViewMode.body => _JsonViewer(
        body: buildResponseBodyText(state),
        wrap: wrapResponse,
      ),
    };
  }
}

class _ResponseActionBar extends StatelessWidget {
  const _ResponseActionBar({
    required this.selectedMode,
    required this.executionResult,
    required this.parsedResponse,
    required this.wrapResponse,
    required this.onModeSelected,
    required this.onToggleWrap,
  });

  final ResponseViewMode selectedMode;
  final RequestExecutionResult? executionResult;
  final ParsedResponse? parsedResponse;
  final bool wrapResponse;
  final ValueChanged<ResponseViewMode> onModeSelected;
  final VoidCallback onToggleWrap;

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
          _CircularActionButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsResponseFilterButton,
            ),
            icon: CupertinoIcons.list_bullet,
            onTap: () => _openFilter(context),
          ),
          const SizedBox(width: AppSpacing.small),
          _CircularActionButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsResponseShareButton,
            ),
            icon: CupertinoIcons.square_arrow_up,
            onTap: _shareText == null ? null : () => _share(context),
          ),
          const SizedBox(width: AppSpacing.small),
          _ResponseMoreButton(
            wrapResponse: wrapResponse,
            onToggleWrap: onToggleWrap,
          ),
        ],
      ),
    ),
  );

  String? get _shareText => buildResponseShareText(
    selectedMode: selectedMode,
    executionResult: executionResult,
    parsedResponse: parsedResponse,
  );

  /// Opens the platform share sheet with the text represented by the active response tab.
  Future<void> _share(BuildContext context) async {
    final text = _shareText;
    if (text == null) {
      return;
    }

    final renderObject = context.findRenderObject();
    final origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'HTTPBot ${selectedMode.label}',
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Opens the Filter Response sheet against the raw response body, regardless
  /// of which response tab is currently selected.
  void _openFilter(BuildContext context) {
    showFilterResponseSheet(
      context,
      body: executionResult?.bodyText ?? '',
      contentType: parsedResponse?.contentType,
    );
  }
}

enum _ResponseMoreAction { help, wrap }

class _ResponseMoreButton extends StatelessWidget {
  const _ResponseMoreButton({
    required this.wrapResponse,
    required this.onToggleWrap,
  });

  final bool wrapResponse;
  final VoidCallback onToggleWrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopupMenuButton<_ResponseMoreAction>(
      color: colors.surface,
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (context) => [
        const PopupMenuItem<_ResponseMoreAction>(
          value: _ResponseMoreAction.help,
          child: Text(AppStrings.filterResponseHelp),
        ),
        CheckedPopupMenuItem<_ResponseMoreAction>(
          value: _ResponseMoreAction.wrap,
          checked: wrapResponse,
          child: const Text(AppStrings.filterResponseWrap),
        ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: AppSpacing.xLarge + AppSpacing.small,
          height: AppSpacing.xLarge + AppSpacing.small,
          child: Icon(CupertinoIcons.ellipsis, color: colors.iconPrimary),
        ),
      ),
    );
  }

  void _onSelected(BuildContext context, _ResponseMoreAction action) {
    switch (action) {
      case _ResponseMoreAction.help:
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.filterResponseHelpTitle),
            content: const Text(AppStrings.filterResponseHelpBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      case _ResponseMoreAction.wrap:
        onToggleWrap();
    }
  }
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: colors.textOnPrimary),
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
        title: AppStrings.requestResponseNoRequestData,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      children: [
        _InfoCard(
          key: const ValueKey<String>(
            AppWidgetKeys.requestsResponseRawRequestCard,
          ),
          child: _RawRequestRichText(rawRequest: buildRawRequest(snapshot)),
        ),
      ],
    );
  }
}

/// Renders the raw HTTP request with primary header keys and secondary values.
class _RawRequestRichText extends StatelessWidget {
  const _RawRequestRichText({required this.rawRequest});

  final String rawRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: colors.textPrimary,
    );
    final secondaryStyle = baseStyle?.copyWith(color: colors.textSecondary);
    final lines = rawRequest.split('\n');

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Text.rich(
              _buildLineSpan(
                line: lines[i],
                isFirstLine: i == 0,
                baseStyle: baseStyle,
                secondaryStyle: secondaryStyle,
              ),
            ),
        ],
      ),
    );
  }

  TextSpan _buildLineSpan({
    required String line,
    required bool isFirstLine,
    required TextStyle? baseStyle,
    required TextStyle? secondaryStyle,
  }) {
    if (isFirstLine) {
      // METHOD path PROTOCOL — protocol (last token) is secondary.
      final lastSpace = line.lastIndexOf(' ');
      if (lastSpace <= 0) {
        return TextSpan(text: line, style: baseStyle);
      }
      return TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: line.substring(0, lastSpace + 1)),
          TextSpan(text: line.substring(lastSpace + 1), style: secondaryStyle),
        ],
      );
    }

    final separator = line.indexOf(':');
    if (separator <= 0) {
      // Body or blank lines render as secondary text.
      return TextSpan(text: line, style: secondaryStyle);
    }

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: line.substring(0, separator + 1)),
        TextSpan(text: line.substring(separator + 1), style: secondaryStyle),
      ],
    );
  }
}

class _MetricsView extends StatelessWidget {
  const _MetricsView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    final result = executionResult;
    final exchanges = result == null
        ? const <HttpExchange>[]
        : resolveExchanges(result);
    if (exchanges.isEmpty) {
      return const _CenteredEmptyState(
        title: AppStrings.requestResponseNoMetrics,
      );
    }

    // Newest request first, mirroring the screenshots (Request #2 above #1).
    final ordered = exchanges.reversed.toList(growable: false);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      itemCount: ordered.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.medium),
      itemBuilder: (context, index) {
        final exchange = ordered[index];
        return Column(
          key: ValueKey<String>(
            AppWidgetKeys.requestsResponseMetricsExchangeAt(exchange.index),
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Text(
                AppStrings.requestResponseExchangeTitle(exchange.index),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _MetricsRequestCard(exchange: exchange),
          ],
        );
      },
    );
  }
}

/// One card of labeled metric rows for a single exchange, separated by dividers.
class _MetricsRequestCard extends StatelessWidget {
  const _MetricsRequestCard({required this.exchange});

  final HttpExchange exchange;

  @override
  Widget build(BuildContext context) {
    final rows = buildMetricRows(exchange);

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _MetricRow(label: rows[i].key, value: rows[i].value),
            if (i != rows.length - 1) const Divider(height: AppSpacing.large),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.xxxSmall),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    ],
  );
}

class _HeadersView extends StatelessWidget {
  const _HeadersView({required this.executionResult});

  final RequestExecutionResult? executionResult;

  @override
  Widget build(BuildContext context) {
    final headers = executionResult?.headers ?? const <KeyValueItem>[];
    if (headers.isEmpty) {
      return const _CenteredEmptyState(
        title: AppStrings.requestResponseNoHeaders,
      );
    }

    final groupedHeaders = _groupHeaders(headers);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.large,
      ),
      children: [
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < groupedHeaders.length; i++) ...[
                _MetricRow(
                  label: groupedHeaders[i].key,
                  value: groupedHeaders[i].value.join('\n'),
                ),
                if (i != groupedHeaders.length - 1)
                  const Divider(height: AppSpacing.large),
              ],
            ],
          ),
        ),
      ],
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
      return const _CenteredEmptyState(
        title: AppStrings.requestResponseNoCookies,
      );
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
  const _JsonViewer({required this.body, this.wrap = true});

  final String body;
  final bool wrap;

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
              itemBuilder: (context, index) => _JsonLineRow(
                lineNumber: index + 1,
                content: lines[index],
                wrap: wrap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JsonLineRow extends StatelessWidget {
  const _JsonLineRow({
    required this.lineNumber,
    required this.content,
    this.wrap = true,
  });

  final int lineNumber;
  final String content;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
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
            width: AppSpacing.xxLarge + AppSpacing.small,
            child: Text(
              '$lineNumber',
              style: baseStyle?.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.xxxSmall),
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
  const _InfoCard({super.key, required this.child});

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

class _CookieDisplayTile extends StatelessWidget {
  const _CookieDisplayTile({required this.cookie});

  final _CookieDisplay cookie;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${cookie.name} = ${cookie.value}',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
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
  const _CircularActionButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = AppSpacing.xLarge + AppSpacing.small;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: colors.iconPrimary),
        ),
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

/// Returns the recorded exchanges, synthesizing one from the legacy single
/// snapshot when an older result carries no exchange list.
List<HttpExchange> resolveExchanges(RequestExecutionResult result) {
  if (result.exchanges.isNotEmpty) {
    return result.exchanges;
  }

  final snapshot = result.executedRequestSnapshot;
  if (snapshot == null) {
    return const <HttpExchange>[];
  }

  return [
    HttpExchange(
      index: 1,
      request: snapshot,
      statusCode: result.statusCode,
      reasonPhrase: result.statusMessage,
      protocol: snapshot.protocol,
      responseBodySizeBytes: result.payloadSizeBytes,
      responseStartAt: snapshot.startAt,
      responseEndAt: snapshot.endAt,
    ),
  ];
}

/// Builds the ordered label/value rows shown in a Metrics card.
List<MapEntry<String, String>> buildMetricRows(HttpExchange exchange) {
  final request = exchange.request;
  return <MapEntry<String, String>>[
    MapEntry(AppStrings.requestMetricUrl, formatText(request.url)),
    MapEntry(AppStrings.requestMetricMethod, formatText(request.method)),
    MapEntry(
      AppStrings.requestMetricResponseCode,
      formatStatus(exchange.statusCode, exchange.reasonPhrase),
    ),
    MapEntry(
      AppStrings.requestMetricProtocol,
      formatProtocol(exchange.protocol ?? request.protocol),
    ),
    MapEntry(
      AppStrings.requestMetricRemoteAddress,
      formatText(exchange.remoteAddress),
    ),
    MapEntry(AppStrings.requestMetricTls, _formatTls(exchange)),
    MapEntry(AppStrings.requestMetricKeptAlive, formatBool(exchange.keptAlive)),
    MapEntry(
      AppStrings.requestMetricRequestHeaderSize,
      formatBytes(request.headerSizeBytes),
    ),
    MapEntry(
      AppStrings.requestMetricRequestSize,
      formatBytes(request.bodySizeBytes),
    ),
    MapEntry(
      AppStrings.requestMetricResponseHeaderSize,
      formatBytes(exchange.responseHeaderSizeBytes),
    ),
    MapEntry(
      AppStrings.requestMetricResponseSize,
      formatBytes(exchange.responseBodySizeBytes),
    ),
    MapEntry(
      AppStrings.requestMetricRequestStart,
      formatDateUtc(request.startAt),
    ),
    MapEntry(AppStrings.requestMetricRequestEnd, formatDateUtc(request.endAt)),
    MapEntry(
      AppStrings.requestMetricResponseStart,
      formatDateUtc(exchange.responseStartAt),
    ),
    MapEntry(
      AppStrings.requestMetricResponseEnd,
      formatDateUtc(exchange.responseEndAt),
    ),
    MapEntry(
      AppStrings.requestMetricDnsLookupDuration,
      formatDuration(exchange.dnsLookupDuration),
    ),
    MapEntry(
      AppStrings.requestMetricConnectDuration,
      formatDuration(exchange.connectDuration),
    ),
    MapEntry(
      AppStrings.requestMetricTlsHandshake,
      formatDuration(exchange.tlsHandshakeDuration),
    ),
    MapEntry(
      AppStrings.requestMetricRequestDuration,
      formatDuration(exchange.requestDuration),
    ),
    MapEntry(
      AppStrings.requestMetricResponseDuration,
      formatDuration(exchange.responseDuration),
    ),
  ];
}

String _formatTls(HttpExchange exchange) {
  final protocol = exchange.tlsProtocol?.trim();
  final cipher = exchange.tlsCipher?.trim();
  if ((protocol == null || protocol.isEmpty) &&
      (cipher == null || cipher.isEmpty)) {
    return metricsEmptyValue;
  }
  return [
    if (protocol != null && protocol.isNotEmpty) protocol,
    if (cipher != null && cipher.isNotEmpty) cipher,
  ].join('\n');
}

/// Builds a plain-text metrics summary used by the share action.
String buildMetricsSummary(List<HttpExchange> exchanges) {
  final buffer = StringBuffer();
  for (final exchange in exchanges.reversed) {
    buffer.writeln(AppStrings.requestResponseExchangeTitle(exchange.index));
    for (final row in buildMetricRows(exchange)) {
      buffer.writeln('${row.key}: ${row.value}');
    }
    buffer.writeln();
  }
  return buffer.toString().trimRight();
}

/// Builds the response body text shared by the visible body tab and share action.
String buildResponseBodyText(RequestSendState state) {
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
      (issue) => 'Resolution issue: ${issue.placeholder} (${issue.type.name})',
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

/// Builds the plain text payload for sharing the currently selected response tab.
String? buildResponseShareText({
  required ResponseViewMode selectedMode,
  required RequestExecutionResult? executionResult,
  required ParsedResponse? parsedResponse,
}) {
  final result = executionResult;
  if (result == null) {
    return null;
  }

  return switch (selectedMode) {
    ResponseViewMode.request => _buildRequestShareText(result),
    ResponseViewMode.metrics => _buildMetricsShareText(result),
    ResponseViewMode.tests => _buildTestsShareText(result),
    ResponseViewMode.cookies => _buildCookiesShareText(result),
    ResponseViewMode.headers => _buildHeadersShareText(result),
    ResponseViewMode.body => _buildBodyShareText(result, parsedResponse),
  };
}

/// Builds raw request share text when the transport captured an executed snapshot.
String? _buildRequestShareText(RequestExecutionResult result) {
  final snapshot = result.executedRequestSnapshot;
  return snapshot == null ? null : buildRawRequest(snapshot);
}

/// Builds metric share text from all recorded HTTP exchanges.
String? _buildMetricsShareText(RequestExecutionResult result) {
  final exchanges = resolveExchanges(result);
  return exchanges.isEmpty ? null : buildMetricsSummary(exchanges);
}

/// Builds a readable test result list with status, expected, actual, and failure details.
String? _buildTestsShareText(RequestExecutionResult result) {
  if (result.testResults.isEmpty) {
    return null;
  }

  final buffer = StringBuffer();
  for (final testResult in result.testResults) {
    buffer.writeln(
      '${_formatTestStatus(testResult.status)} ${testResult.label}',
    );
    if (testResult.expected?.trim().isNotEmpty ?? false) {
      buffer.writeln('Expected: ${testResult.expected}');
    }
    if (testResult.actual?.trim().isNotEmpty ?? false) {
      buffer.writeln('Actual: ${testResult.actual}');
    }
    if (testResult.message?.trim().isNotEmpty ?? false) {
      buffer.writeln(testResult.message);
    }
    buffer.writeln();
  }

  return buffer.toString().trimRight();
}

/// Builds sent and received cookie share text while preserving section labels.
String? _buildCookiesShareText(RequestExecutionResult result) {
  final sentCookies = _parseSentCookies(result.executedRequestSnapshot);
  final receivedCookies = _parseReceivedCookies(result);
  if (sentCookies.isEmpty && receivedCookies.isEmpty) {
    return null;
  }

  final buffer = StringBuffer();
  if (sentCookies.isNotEmpty) {
    buffer.writeln(AppStrings.requestResponseSentCookies);
    for (final cookie in sentCookies) {
      buffer.writeln(_formatCookie(cookie));
    }
  }

  if (sentCookies.isNotEmpty && receivedCookies.isNotEmpty) {
    buffer.writeln();
  }

  if (receivedCookies.isNotEmpty) {
    buffer.writeln(AppStrings.requestResponseReceivedCookies);
    for (final cookie in receivedCookies) {
      buffer.writeln(_formatCookie(cookie));
    }
  }

  return buffer.toString().trimRight();
}

/// Builds grouped response header share text.
String? _buildHeadersShareText(RequestExecutionResult result) {
  final groupedHeaders = _groupHeaders(result.headers);
  if (groupedHeaders.isEmpty) {
    return null;
  }

  return groupedHeaders
      .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
      .join('\n');
}

/// Builds body share text using the same fallback rules as the visible body tab.
String? _buildBodyShareText(
  RequestExecutionResult result,
  ParsedResponse? parsedResponse,
) {
  final state = RequestSendState(
    status: RequestSendStatus.completed,
    draft: result.request,
    executionResult: result,
    parsedResponse: parsedResponse,
    errorMessage: result.errorMessage,
  );
  final body = buildResponseBodyText(state).trim();
  return body.isEmpty ? null : body;
}

/// Returns the visible fallback text for parsed response types without formatted bodies.
String _fallbackBodyForParsedResponse(ParsedResponse parsedResponse) =>
    switch (parsedResponse.bodyType) {
      ParsedResponseBodyType.empty => 'No response body.',
      ParsedResponseBodyType.binary => 'Binary response received.',
      ParsedResponseBodyType.error => parsedResponse.execution.errorMessage,
      _ => parsedResponse.execution.bodyText,
    };

/// Formats one cookie row for plain-text sharing.
String _formatCookie(_CookieDisplay cookie) {
  final buffer = StringBuffer('${cookie.name}=${cookie.value}');
  if (cookie.attributes.isNotEmpty) {
    for (final attribute in cookie.attributes.entries) {
      buffer.write('; ${attribute.key}=${attribute.value}');
    }
  } else if (cookie.rawValue?.trim().isNotEmpty ?? false) {
    return cookie.rawValue!;
  }

  return buffer.toString();
}

/// Converts test statuses into compact labels for shared plain text.
String _formatTestStatus(RequestTestResultStatus status) => switch (status) {
  RequestTestResultStatus.passed => 'PASS',
  RequestTestResultStatus.failed => 'FAIL',
  RequestTestResultStatus.error => 'ERROR',
};

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
      cookies.add(_CookieDisplay(name: trimmed, value: '', rawValue: trimmed));
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
            attributes: {'Domain': cookie.domain, 'Path': cookie.path},
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
    return _CookieDisplay(name: firstSegment, value: '', rawValue: rawHeader);
  }

  final attributes = <String, String>{};
  for (final segment in segments.skip(1)) {
    final attributeSeparatorIndex = segment.indexOf('=');
    if (attributeSeparatorIndex <= 0) {
      attributes[segment] = 'true';
      continue;
    }
    attributes[segment.substring(0, attributeSeparatorIndex).trim()] = segment
        .substring(attributeSeparatorIndex + 1)
        .trim();
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
