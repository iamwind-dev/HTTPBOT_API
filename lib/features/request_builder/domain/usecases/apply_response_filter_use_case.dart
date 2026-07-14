import 'dart:convert';

import 'package:xml/xml.dart' as xml;

import '../entities/response_filter.dart';
import '../entities/response_filter_run_result.dart';
import '../helpers/response_query_evaluator.dart';

class ApplyResponseFilterUseCase {
  const ApplyResponseFilterUseCase();

  ResponseFilterRunResult call({
    required String bodyText,
    required String contentType,
    required ResponseFilterType filterType,
    required String query,
  }) {
    if (_isLikelyBinary(contentType)) {
      return const ResponseFilterRunResult(
        outputText: '',
        isJson: false,
        errorMessage: 'Filtering only works on text responses.',
      );
    }

    if (query.trim().isEmpty) {
      return ResponseFilterRunResult(
        outputText: bodyText,
        isJson: _looksLikeJson(bodyText),
        usedOriginalBody: true,
      );
    }

    try {
      return switch (filterType) {
        ResponseFilterType.jq => _evaluateJq(bodyText, query),
        ResponseFilterType.jsonPath => _evaluateJsonPath(bodyText, query),
        ResponseFilterType.xPath => _evaluateXPath(bodyText, query),
      };
    } on FormatException catch (error) {
      return ResponseFilterRunResult(
        outputText: '',
        isJson: false,
        errorMessage: error.message,
      );
    } on Object {
      return const ResponseFilterRunResult(
        outputText: '',
        isJson: false,
        errorMessage: 'Invalid filter query.',
      );
    }
  }

  ResponseFilterRunResult _evaluateJq(String bodyText, String query) {
    final decoded = jsonDecode(bodyText);
    final values = evaluateJqExpression(query, decoded);
    return _formatJsonResult(values);
  }

  ResponseFilterRunResult _evaluateJsonPath(String bodyText, String query) {
    final decoded = jsonDecode(bodyText);
    final values = evaluateJsonPathExpression(query, decoded);
    return _formatJsonResult(values);
  }

  ResponseFilterRunResult _evaluateXPath(String bodyText, String query) {
    final document = xml.XmlDocument.parse(bodyText);
    final values = evaluateXPathExpression(query, document);
    return ResponseFilterRunResult(
      outputText: values.join('\n'),
      isJson: false,
    );
  }

  ResponseFilterRunResult _formatJsonResult(List<Object?> values) {
    if (values.isEmpty) {
      return const ResponseFilterRunResult(outputText: '[]', isJson: true);
    }

    if (values.length == 1) {
      final value = values.first;
      if (value is Map || value is List) {
        return ResponseFilterRunResult(
          outputText: prettyPrintJsonValue(value),
          isJson: true,
        );
      }

      return ResponseFilterRunResult(
        outputText: value == null ? 'null' : value.toString(),
        isJson: false,
      );
    }

    return ResponseFilterRunResult(
      outputText: prettyPrintJsonValue(values),
      isJson: true,
    );
  }

  bool _isLikelyBinary(String contentType) {
    final normalized = contentType.trim().toLowerCase();
    return normalized.startsWith('image/') ||
        normalized == 'application/octet-stream' ||
        normalized == 'application/pdf';
  }

  bool _looksLikeJson(String bodyText) {
    final trimmed = bodyText.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}
