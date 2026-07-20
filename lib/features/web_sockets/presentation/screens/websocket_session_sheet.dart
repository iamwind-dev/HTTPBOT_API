import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../request_builder/presentation/widgets/request_modal_sheet.dart';
import '../../domain/entities/web_socket_event_entity.dart';
import '../../domain/entities/web_socket_state_entity.dart';
import '../cubits/web_socket_cubit.dart';
import '../utils/web_socket_response_headers_formatter.dart';

/// Opens a session sheet and optionally starts the WebSocket connection.
Future<void> showWebSocketSessionSheet(
  BuildContext context, {
  required WebSocketCubit cubit,
  bool autoConnect = true,
}) => showRequestModalSheet<void>(
  context,
  builder: (_) => BlocProvider<WebSocketCubit>.value(
    value: cubit,
    child: _WebSocketSessionSheet(autoConnect: autoConnect),
  ),
);

class _WebSocketSessionSheet extends StatefulWidget {
  const _WebSocketSessionSheet({required this.autoConnect});

  final bool autoConnect;

  @override
  State<_WebSocketSessionSheet> createState() => _WebSocketSessionSheetState();
}

class _WebSocketSessionSheetState extends State<_WebSocketSessionSheet> {
  late final TextEditingController _messageController = TextEditingController();
  late final ScrollController _scrollController = ScrollController();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectOnce());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocConsumer<WebSocketCubit, WebSocketStateEntity>(
      listenWhen: (previous, current) =>
          previous.events.length != current.events.length,
      listener: (_, __) => _scrollToBottomIfNearEnd(),
      builder: (context, state) => PopScope(
        canPop: !_needsDisconnectPrompt(state.status),
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) {
            return;
          }
          await _confirmClose();
        },
        child: RequestModalSheetCard(
          child: ColoredBox(
            color: colors.background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.large,
                    AppSpacing.medium,
                    AppSpacing.large,
                    AppSpacing.medium,
                  ),
                  child: _SessionHeader(state: state),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                    ),
                    child: _EventLogCard(
                      events: state.events,
                      scrollController: _scrollController,
                    ),
                  ),
                ),
                _MessageInputBar(controller: _messageController, state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connectOnce() async {
    if (_started || !mounted) {
      return;
    }
    _started = true;
    await context.read<WebSocketCubit>().connect();
  }

  bool _needsDisconnectPrompt(WebSocketConnectionStatus status) =>
      status == WebSocketConnectionStatus.connected ||
      status == WebSocketConnectionStatus.connecting;

  Future<void> _confirmClose() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect WebSocket?'),
        content: const Text('The active WebSocket session will be closed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (!mounted || shouldDisconnect != true) {
      return;
    }

    await context.read<WebSocketCubit>().disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _scrollToBottomIfNearEnd() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final shouldScroll = position.maxScrollExtent - position.pixels < 96;
    if (!shouldScroll) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.state});

  final WebSocketStateEntity state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isBusy =
        state.status == WebSocketConnectionStatus.connected ||
        state.status == WebSocketConnectionStatus.connecting;

    return Row(
      children: [
        _StatusPill(status: state.status),
        const Spacer(),
        FilledButton(
          key: const ValueKey<String>(AppWidgetKeys.websocketsConnectButton),
          onPressed: () => isBusy
              ? context.read<WebSocketCubit>().disconnect()
              : context.read<WebSocketCubit>().connect(),
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.textOnPrimary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.medium,
            ),
          ),
          child: Text(isBusy ? 'Disconnect' : 'Connect'),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final WebSocketConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (label, color) = switch (status) {
      WebSocketConnectionStatus.connected => ('Connected', colors.methodPost),
      WebSocketConnectionStatus.connecting => ('Connecting', colors.primary),
      WebSocketConnectionStatus.error => ('Error', colors.methodDelete),
      _ => ('Disconnected', colors.methodDelete),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.circle_fill, size: 14, color: color),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventLogCard extends StatelessWidget {
  const _EventLogCard({required this.events, required this.scrollController});

  final List<WebSocketEventEntity> events;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
      child: events.isEmpty
          ? Center(
              child: Text(
                'Connect to start a WebSocket session.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.medium),
              itemCount: events.length,
              separatorBuilder: (_, __) => Divider(color: colors.divider),
              itemBuilder: (context, index) => _EventRow(event: events[index]),
            ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final WebSocketEventEntity event;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final color = _eventColor(colors);
    final timestamp = DateFormat('HH:mm:ss').format(event.timestamp);
    final isLifecycle = event.type == WebSocketEventType.lifecycle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          child: _EventIcon(event: event, color: color),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(
              color: colors.textPrimary,
              fontFamily: 'monospace',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLifecycle || event.type == WebSocketEventType.error) ...[
                  Text(
                    _title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxSmall),
                ],
                Text(
                  _bodyText,
                  style: TextStyle(
                    color:
                        event.type == WebSocketEventType.ping ||
                            event.type == WebSocketEventType.pong
                        ? colors.primary
                        : colors.textPrimary,
                  ),
                ),
                if (_headersText != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  Text(_headersText!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          timestamp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  String get _title {
    if (event.type == WebSocketEventType.error) {
      return event.title ?? 'Error';
    }
    return event.title ??
        (event.text == 'Disconnected' ? 'Disconnected' : event.text ?? '');
  }

  String get _bodyText {
    if (event.errorMessage != null) {
      return event.errorMessage!;
    }
    if (event.closeCode != null) {
      final reason = event.closeReason?.trim();
      return reason == null || reason.isEmpty
          ? 'Socket disconnected with code: ${event.closeCode}'
          : 'Socket disconnected with code: ${event.closeCode}\nReason: $reason';
    }
    if (event.binarySizeBytes != null) {
      return 'Binary frame: ${event.fileName ?? ''}, ${event.binarySizeBytes} bytes';
    }
    if (event.title != null) {
      return event.text ?? '';
    }
    if (event.responseHeaders != null) {
      return 'Response headers:';
    }
    return event.text ?? '';
  }

  String? get _headersText {
    final headers = event.responseHeaders;
    if (headers == null) {
      return null;
    }
    return formatWebSocketResponseHeaders(headers);
  }

  Color _eventColor(AppThemeColors colors) => switch (event.type) {
    WebSocketEventType.sentText ||
    WebSocketEventType.sentBinary => colors.methodPut,
    WebSocketEventType.receivedText ||
    WebSocketEventType.receivedBinary ||
    WebSocketEventType.ping ||
    WebSocketEventType.pong => colors.primary,
    WebSocketEventType.disconnected => colors.methodDelete,
    WebSocketEventType.error => colors.methodDelete,
    WebSocketEventType.lifecycle =>
      event.text == 'Disconnected' ? colors.methodDelete : colors.methodPost,
  };
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.event, required this.color});

  final WebSocketEventEntity event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (event.type) {
      WebSocketEventType.sentText ||
      WebSocketEventType.sentBinary => CupertinoIcons.arrow_up,
      WebSocketEventType.receivedText ||
      WebSocketEventType.receivedBinary ||
      WebSocketEventType.ping ||
      WebSocketEventType.pong => CupertinoIcons.arrow_down,
      WebSocketEventType.disconnected => CupertinoIcons.xmark,
      WebSocketEventType.error => CupertinoIcons.xmark,
      WebSocketEventType.lifecycle =>
        event.text == 'Disconnected'
            ? CupertinoIcons.xmark
            : CupertinoIcons.check_mark,
    };

    return CircleAvatar(
      radius: 11,
      backgroundColor: color,
      child: Icon(icon, color: context.appColors.textOnPrimary, size: 13),
    );
  }
}

class _MessageInputBar extends StatefulWidget {
  const _MessageInputBar({required this.controller, required this.state});

  final TextEditingController controller;
  final WebSocketStateEntity state;

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canSend =
        widget.state.canSend &&
        !widget.state.isSending &&
        widget.controller.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.card,
            child: IconButton(
              key: const ValueKey<String>(AppWidgetKeys.websocketsBinaryButton),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Binary WebSocket messages are not implemented yet.',
                    ),
                  ),
                );
              },
              icon: Icon(CupertinoIcons.plus, color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
              ),
              child: TextField(
                key: const ValueKey<String>(
                  AppWidgetKeys.websocketsMessageField,
                ),
                controller: widget.controller,
                enabled: widget.state.canSend,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendIfReady(canSend),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          CircleAvatar(
            backgroundColor: canSend ? colors.primary : colors.surfaceMuted,
            child: IconButton(
              key: const ValueKey<String>(AppWidgetKeys.websocketsSendButton),
              onPressed: canSend ? () => _sendIfReady(canSend) : null,
              icon: Icon(CupertinoIcons.arrow_up, color: colors.textOnPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _sendIfReady(bool canSend) {
    if (!canSend) {
      return;
    }
    final text = widget.controller.text;
    context.read<WebSocketCubit>().sendText(text);
    widget.controller.clear();
  }
}
