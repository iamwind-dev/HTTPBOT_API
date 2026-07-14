import 'dart:convert';

import 'filter_response_mode.dart';
import 'filter_response_result.dart';
import 'jq_filter_engine.dart';
import 'json_path_filter_engine.dart';
import 'response_filter_pretty_printer.dart';

/// User-facing messages produced by the filter engine.
abstract final class FilterResponseMessages {
  static const emptyBody = 'No response body to filter.';
  static const invalidJson = 'Response body is not valid JSON.';
  static const unsupportedJq = 'Unsupported jq query.';
  static const unsupportedJsonPath = 'Unsupported JSONPath query.';
  static const xPathOnJson =
      'XPath can only be used with XML or HTML responses.';
  static const xPathNotImplemented = 'XPath filtering is not implemented yet.';
}

/// Applies jq / JSONPath / XPath queries to a response body for the Filter
/// Response sheet. Pure and synchronous so it is trivially unit-testable.
class ResponseFilterEngine {
  const ResponseFilterEngine();

  FilterResponseResult filter({
    required String body,
    required FilterResponseMode mode,
    required String query,
    String? contentType,
  }) {
    if (body.trim().isEmpty) {
      return const FilterResponseResult(
        displayText: FilterResponseMessages.emptyBody,
        errorMessage: FilterResponseMessages.emptyBody,
      );
    }

    return switch (mode) {
      FilterResponseMode.jq => _filterJq(body, query),
      FilterResponseMode.jsonPath => _filterJsonPath(body, query),
      FilterResponseMode.xPath => _filterXPath(body, contentType),
    };
  }

  FilterResponseResult _filterJq(String body, String query) {
    final decoded = _tryDecodeJson(body);
    if (decoded.failed) {
      return _error(FilterResponseMessages.invalidJson);
    }

    if (query.trim().isEmpty) {
      return _success(decoded.value);
    }

    try {
      final result = evaluateJq(json: decoded.value, query: query.trim());
      return _success(result);
    } on JqUnsupportedQueryException {
      return _error(FilterResponseMessages.unsupportedJq);
    }
  }

  FilterResponseResult _filterJsonPath(String body, String query) {
    final decoded = _tryDecodeJson(body);
    if (decoded.failed) {
      return _error(FilterResponseMessages.invalidJson);
    }

    if (query.trim().isEmpty) {
      return _success(decoded.value);
    }

    try {
      final result = evaluateJsonPath(json: decoded.value, query: query.trim());
      return _success(result);
    } on JsonPathUnsupportedQueryException {
      return _error(FilterResponseMessages.unsupportedJsonPath);
    }
  }

  FilterResponseResult _filterXPath(String body, String? contentType) {
    if (_looksLikeJson(body, contentType)) {
      return _error(FilterResponseMessages.xPathOnJson);
    }
    return _error(FilterResponseMessages.xPathNotImplemented);
  }

  FilterResponseResult _success(Object? value) => FilterResponseResult(
    displayText: prettyPrintJsonValue(value),
    rawValue: value,
  );

  FilterResponseResult _error(String message) =>
      FilterResponseResult(displayText: message, errorMessage: message);

  _JsonDecodeOutcome _tryDecodeJson(String body) {
    try {
      return _JsonDecodeOutcome.success(jsonDecode(body));
    } on FormatException {
      return const _JsonDecodeOutcome.failure();
    }
  }

  bool _looksLikeJson(String body, String? contentType) {
    final type = contentType?.toLowerCase() ?? '';
    if (type.contains('json')) {
      return true;
    }
    if (type.contains('xml') || type.contains('html')) {
      return false;
    }
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}

class _JsonDecodeOutcome {
  const _JsonDecodeOutcome.success(this.value) : failed = false;
  const _JsonDecodeOutcome.failure() : value = null, failed = true;

  final Object? value;
  final bool failed;
}

/// Detects the default mode for a response based on its content type / body.
FilterResponseMode defaultFilterMode({
  required String body,
  String? contentType,
}) {
  final type = contentType?.toLowerCase() ?? '';
  if (type.contains('xml') || type.contains('html')) {
    return FilterResponseMode.xPath;
  }
  if (type.contains('json')) {
    return FilterResponseMode.jq;
  }

  final trimmed = body.trimLeft();
  if (trimmed.startsWith('<')) {
    return FilterResponseMode.xPath;
  }
  return FilterResponseMode.jq;
}
