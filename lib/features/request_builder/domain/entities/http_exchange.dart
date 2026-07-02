import 'package:equatable/equatable.dart';

import 'executed_request_snapshot.dart';

/// One sent request attempt paired with its response-side network metadata.
///
/// A single execution produces one exchange; redirects or retries append more,
/// surfaced in the Metrics tab as `Request #1`, `Request #2`, and so on.
class HttpExchange extends Equatable {
  const HttpExchange({
    required this.index,
    required this.request,
    this.statusCode,
    this.reasonPhrase,
    this.protocol,
    this.remoteAddress,
    this.tlsProtocol,
    this.tlsCipher,
    this.keptAlive,
    this.responseHeaderSizeBytes,
    this.responseBodySizeBytes,
    this.responseStartAt,
    this.responseEndAt,
    this.dnsLookupDuration,
    this.connectDuration,
    this.tlsHandshakeDuration,
    this.requestDuration,
    this.responseDuration,
  });

  /// 1-based attempt number for display (`Request #index`).
  final int index;
  final ExecutedRequestSnapshot request;
  final int? statusCode;
  final String? reasonPhrase;
  final String? protocol;
  final String? remoteAddress;
  final String? tlsProtocol;
  final String? tlsCipher;
  final bool? keptAlive;
  final int? responseHeaderSizeBytes;
  final int? responseBodySizeBytes;
  final DateTime? responseStartAt;
  final DateTime? responseEndAt;

  /// Durations Dio cannot supply stay null and render as `—` in the UI.
  final Duration? dnsLookupDuration;
  final Duration? connectDuration;
  final Duration? tlsHandshakeDuration;
  final Duration? requestDuration;
  final Duration? responseDuration;

  @override
  List<Object?> get props => [
    index,
    request,
    statusCode,
    reasonPhrase,
    protocol,
    remoteAddress,
    tlsProtocol,
    tlsCipher,
    keptAlive,
    responseHeaderSizeBytes,
    responseBodySizeBytes,
    responseStartAt,
    responseEndAt,
    dnsLookupDuration,
    connectDuration,
    tlsHandshakeDuration,
    requestDuration,
    responseDuration,
  ];
}
