import 'package:equatable/equatable.dart';

class RequestDraft extends Equatable {
  const RequestDraft({
    required this.method,
    required this.url,
    required this.authMode,
    required this.bodyMode,
  });

  final String method;
  final String url;
  final String authMode;
  final String bodyMode;

  @override
  List<Object> get props => [method, url, authMode, bodyMode];
}
