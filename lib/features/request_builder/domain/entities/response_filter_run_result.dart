import 'package:equatable/equatable.dart';

class ResponseFilterRunResult extends Equatable {
  const ResponseFilterRunResult({
    required this.outputText,
    required this.isJson,
    this.errorMessage,
    this.usedOriginalBody = false,
  });

  final String outputText;
  final bool isJson;
  final String? errorMessage;
  final bool usedOriginalBody;

  bool get hasError => errorMessage?.trim().isNotEmpty ?? false;

  @override
  List<Object?> get props => [outputText, isJson, errorMessage, usedOriginalBody];
}
