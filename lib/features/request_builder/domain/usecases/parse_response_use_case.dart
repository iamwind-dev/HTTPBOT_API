import 'dart:convert';

import '../entities/parsed_response.dart';
import '../entities/request_execution_result.dart';
import '../entities/request_key_value.dart';

class ParseResponseUseCase {
  const ParseResponseUseCase();

  static const JsonEncoder _prettyJsonEncoder = JsonEncoder.withIndent('  ');

  /// Parses the raw execution result into a display-friendly response while preserving the original transport metadata.
  ParsedResponse call(RequestExecutionResult executionResult) {
    final contentType = _extractContentType(executionResult.headers);
    final bodyText = executionResult.bodyText.trim();

    if (bodyText.isEmpty) {
      if (executionResult.errorMessage.trim().isNotEmpty) {
        return ParsedResponse(
          execution: executionResult,
          bodyType: ParsedResponseBodyType.error,
          formattedBody: executionResult.errorMessage,
          contentType: contentType,
        );
      }

      return ParsedResponse(
        execution: executionResult,
        bodyType: ParsedResponseBodyType.empty,
        contentType: contentType,
      );
    }

    if (_isLikelyBinary(contentType)) {
      return ParsedResponse(
        execution: executionResult,
        bodyType: ParsedResponseBodyType.binary,
        formattedBody:
            'Binary response (${executionResult.payloadSizeBytes} bytes)',
        contentType: contentType,
      );
    }

    if (_shouldAttemptJsonParsing(contentType, bodyText)) {
      final prettyJson = _tryPrettyPrintJson(executionResult.bodyText);
      if (prettyJson != null) {
        return ParsedResponse(
          execution: executionResult,
          bodyType: ParsedResponseBodyType.json,
          formattedBody: prettyJson,
          contentType: contentType,
          isPrettyPrinted: true,
        );
      }
    }

    return ParsedResponse(
      execution: executionResult,
      bodyType: ParsedResponseBodyType.text,
      formattedBody: executionResult.bodyText,
      contentType: contentType,
    );
  }

  /// Extracts the normalized MIME type from the response headers when available.
  String _extractContentType(List<KeyValueItem> headers) {
    for (final header in headers.where((item) => item.isEnabled)) {
      if (header.key.toLowerCase() != 'content-type') {
        continue;
      }

      final value = header.value.trim();
      if (value.isEmpty) {
        return '';
      }

      return value.split(';').first.trim().toLowerCase();
    }

    return '';
  }

  /// Returns true when the response should be displayed as a binary payload placeholder.
  bool _isLikelyBinary(String contentType) =>
      contentType.startsWith('image/') ||
      contentType == 'application/octet-stream' ||
      contentType == 'application/pdf';

  /// Returns true when either the declared content type or the body shape suggests JSON.
  bool _shouldAttemptJsonParsing(String contentType, String bodyText) {
    if (contentType.contains('json')) {
      return true;
    }

    final trimmedBody = bodyText.trimLeft();
    return trimmedBody.startsWith('{') || trimmedBody.startsWith('[');
  }

  /// Pretty prints JSON when the payload is valid and returns null otherwise.
  String? _tryPrettyPrintJson(String bodyText) {
    try {
      return _prettyJsonEncoder.convert(jsonDecode(bodyText));
    } on FormatException {
      return null;
    }
  }
}
