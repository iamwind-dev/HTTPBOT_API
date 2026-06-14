import 'package:equatable/equatable.dart';

class ExecutedRequestSnapshot extends Equatable {
  const ExecutedRequestSnapshot({
    required this.method,
    required this.url,
    this.headers = const <String, String>{},
    this.body,
  });

  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;

  @override
  List<Object?> get props => [
    method,
    url,
    headers.entries.toList(growable: false),
    body,
  ];
}
