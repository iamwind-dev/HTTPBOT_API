import 'package:equatable/equatable.dart';

class ExecutedRequestSnapshot extends Equatable {
  const ExecutedRequestSnapshot({
    required this.method,
    required this.url,
    this.headers = const <String, String>{},
    this.body,
    this.protocol,
    this.headerSizeBytes,
    this.bodySizeBytes,
    this.startAt,
    this.endAt,
  });

  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final String? protocol;
  final int? headerSizeBytes;
  final int? bodySizeBytes;
  final DateTime? startAt;
  final DateTime? endAt;

  @override
  List<Object?> get props => [
    method,
    url,
    headers.entries.toList(growable: false),
    body,
    protocol,
    headerSizeBytes,
    bodySizeBytes,
    startAt,
    endAt,
  ];
}
