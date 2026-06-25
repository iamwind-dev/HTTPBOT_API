import 'dart:convert';

import 'package:xml/xml.dart' as xml;

import '../entities/http_cookie_entity.dart';
import '../entities/request_execution_result.dart';
import '../entities/request_key_value.dart';
import '../entities/request_test.dart';
import '../entities/request_test_result.dart';
import '../helpers/request_test_label_builder.dart';

class EvaluateRequestTestsUseCase {
  const EvaluateRequestTestsUseCase();

  List<RequestTestResult> call(RequestExecutionResult executionResult) {
    return executionResult.request.tests
        .map((test) => _evaluateTest(test, executionResult))
        .toList(growable: false);
  }

  RequestTestResult _evaluateTest(
    RequestTest test,
    RequestExecutionResult executionResult,
  ) {
    final label = buildRequestTestLabel(test);

    try {
      return switch (test.type) {
        RequestTestType.statusCode => _evaluateNumericTest(
          test: test,
          label: label,
          actualValue: executionResult.statusCode?.toDouble(),
          displayActualValue: executionResult.statusCode?.toString(),
        ),
        RequestTestType.responseTime => _evaluateNumericTest(
          test: test,
          label: label,
          actualValue: executionResult.duration.inMilliseconds.toDouble(),
          displayActualValue: '${executionResult.duration.inMilliseconds}ms',
          unitMultiplier: test.timeUnit == ResponseTimeUnit.s ? 1000 : 1,
          expectedSuffix: test.timeUnit?.label ?? 'ms',
        ),
        RequestTestType.responseSize => _evaluateNumericTest(
          test: test,
          label: label,
          actualValue: executionResult.payloadSizeBytes.toDouble(),
          displayActualValue: '${executionResult.payloadSizeBytes}B',
          unitMultiplier: switch (test.sizeUnit) {
            ResponseSizeUnit.kb => 1024,
            ResponseSizeUnit.mb => 1024 * 1024,
            _ => 1,
          },
          expectedSuffix: test.sizeUnit?.label ?? 'B',
        ),
        RequestTestType.responseBody => _evaluateStringTest(
          test: test,
          label: label,
          actualValue: executionResult.bodyText,
        ),
        RequestTestType.header => _evaluateStringTest(
          test: test,
          label: label,
          actualValue: _headerValue(
            executionResult.headers,
            test.headerName,
          ),
        ),
        RequestTestType.headers => _evaluateCollectionTest(
          test: test,
          label: label,
          keys: _headerKeys(executionResult.headers, test.caseSensitive),
        ),
        RequestTestType.cookie => _evaluateStringTest(
          test: test,
          label: label,
          actualValue: _cookieValue(
            executionResult.responseCookies,
            test.cookieName,
            test.caseSensitive,
          ),
        ),
        RequestTestType.cookies => _evaluateCollectionTest(
          test: test,
          label: label,
          keys: _cookieKeys(executionResult.responseCookies, test.caseSensitive),
        ),
        RequestTestType.jsonPath => _evaluateJsonPathTest(
          test: test,
          label: label,
          body: executionResult.bodyText,
        ),
        RequestTestType.xPath => _evaluateXPathTest(
          test: test,
          label: label,
          body: executionResult.bodyText,
        ),
      };
    } on FormatException catch (error) {
      return RequestTestResult(
        testId: test.id,
        label: label,
        status: RequestTestResultStatus.error,
        message: error.message,
      );
    } on Object catch (error) {
      return RequestTestResult(
        testId: test.id,
        label: label,
        status: RequestTestResultStatus.error,
        message: error.toString(),
      );
    }
  }

  RequestTestResult _evaluateCollectionTest({
    required RequestTest test,
    required String label,
    required List<String> keys,
  }) {
    final actualCount = keys.length;

    switch (test.comparator) {
      case RequestTestComparator.isEmpty:
        return _passOrFail(
          test: test,
          label: label,
          passed: keys.isEmpty,
          expected: 'empty',
          actual: actualCount.toString(),
        );
      case RequestTestComparator.isNotEmpty:
        return _passOrFail(
          test: test,
          label: label,
          passed: keys.isNotEmpty,
          expected: 'not empty',
          actual: actualCount.toString(),
        );
      case RequestTestComparator.containsKey:
        final expectedKey = _requiredText(
          test.type == RequestTestType.headers ? test.headerName : test.cookieName,
          'Key name is required.',
        );
        return _passOrFail(
          test: test,
          label: label,
          passed: _containsKey(keys, expectedKey, test.caseSensitive),
          expected: expectedKey,
          actual: keys.join(', '),
        );
      case RequestTestComparator.doesNotContainKey:
        final expectedKey = _requiredText(
          test.type == RequestTestType.headers ? test.headerName : test.cookieName,
          'Key name is required.',
        );
        return _passOrFail(
          test: test,
          label: label,
          passed: !_containsKey(keys, expectedKey, test.caseSensitive),
          expected: expectedKey,
          actual: keys.join(', '),
        );
      case RequestTestComparator.countIs:
        final expectedCount = _parseRequiredNumber(
          test.expectedValue,
          fieldName: 'Expected count',
        );
        return _passOrFail(
          test: test,
          label: label,
          passed: actualCount == expectedCount.toInt(),
          expected: expectedCount.toInt().toString(),
          actual: actualCount.toString(),
        );
      default:
        throw const FormatException('Unsupported collection comparator.');
    }
  }

  RequestTestResult _evaluateJsonPathTest({
    required RequestTest test,
    required String label,
    required String body,
  }) {
    final path = _requiredText(test.jsonPath, 'JSON Path is required.');
    final decoded = jsonDecode(body);
    final values = _evaluateJsonPath(path, decoded);
    final actualValue = _serializeEvaluatedValues(values);

    return _evaluateStringTest(
      test: test,
      label: label,
      actualValue: values.isEmpty ? null : actualValue,
    );
  }

  RequestTestResult _evaluateNumericTest({
    required RequestTest test,
    required String label,
    required double? actualValue,
    required String? displayActualValue,
    num unitMultiplier = 1,
    String expectedSuffix = '',
  }) {
    if (actualValue == null) {
      return RequestTestResult(
        testId: test.id,
        label: label,
        status: RequestTestResultStatus.failed,
        actual: null,
        message: 'Actual numeric value is unavailable.',
      );
    }

    if (test.comparator == RequestTestComparator.isBetween) {
      final minValue = _parseRequiredNumber(test.minValue, fieldName: 'Min Value') *
          unitMultiplier;
      final maxValue = _parseRequiredNumber(test.maxValue, fieldName: 'Max Value') *
          unitMultiplier;
      final passed = actualValue >= minValue && actualValue <= maxValue;
      return _passOrFail(
        test: test,
        label: label,
        passed: passed,
        expected:
            '${_formatNum(minValue / unitMultiplier)}$expectedSuffix and ${_formatNum(maxValue / unitMultiplier)}$expectedSuffix',
        actual: displayActualValue,
      );
    }

    final expectedValue =
        _parseRequiredNumber(test.expectedValue, fieldName: 'Expected Value') *
        unitMultiplier;
    final passed = switch (test.comparator) {
      RequestTestComparator.isEqualTo => actualValue == expectedValue,
      RequestTestComparator.isNotEqualTo => actualValue != expectedValue,
      RequestTestComparator.isGreaterThan => actualValue > expectedValue,
      RequestTestComparator.isLessThan => actualValue < expectedValue,
      RequestTestComparator.isGreaterThanOrEqualTo => actualValue >= expectedValue,
      RequestTestComparator.isLessThanOrEqualTo => actualValue <= expectedValue,
      _ => throw const FormatException('Unsupported numeric comparator.'),
    };

    return _passOrFail(
      test: test,
      label: label,
      passed: passed,
      expected: '${_formatNum(expectedValue / unitMultiplier)}$expectedSuffix',
      actual: displayActualValue,
    );
  }

  RequestTestResult _evaluateStringTest({
    required RequestTest test,
    required String label,
    required String? actualValue,
  }) {
    final valueExists = actualValue != null;
    final actualText = actualValue ?? '';

    switch (test.comparator) {
      case RequestTestComparator.exists:
        return _passOrFail(
          test: test,
          label: label,
          passed: valueExists,
          expected: 'exists',
          actual: valueExists ? actualText : null,
        );
      case RequestTestComparator.doesNotExist:
        return _passOrFail(
          test: test,
          label: label,
          passed: !valueExists,
          expected: 'does not exist',
          actual: valueExists ? actualText : null,
        );
      case RequestTestComparator.hasAnyValue:
        return _passOrFail(
          test: test,
          label: label,
          passed: valueExists && actualText.trim().isNotEmpty,
          expected: 'has any value',
          actual: valueExists ? actualText : null,
        );
      case RequestTestComparator.doesNotHaveAnyValue:
        return _passOrFail(
          test: test,
          label: label,
          passed: !valueExists || actualText.trim().isEmpty,
          expected: 'does not have any value',
          actual: valueExists ? actualText : null,
        );
      case RequestTestComparator.matchesRegex:
      case RequestTestComparator.doesNotMatchRegex:
        final pattern = _requiredText(
          test.expectedValue,
          'Expected Value is required.',
        );
        final regex = RegExp(
          pattern,
          caseSensitive: test.caseSensitive,
        );
        final isMatch = valueExists && regex.hasMatch(actualText);
        return _passOrFail(
          test: test,
          label: label,
          passed: test.comparator == RequestTestComparator.matchesRegex
              ? isMatch
              : !isMatch,
          expected: pattern,
          actual: valueExists ? actualText : null,
        );
      default:
        final expectedText = _requiredText(
          test.expectedValue,
          'Expected Value is required.',
        );
        final normalizedActual = _normalizeForCase(actualText, test.caseSensitive);
        final normalizedExpected = _normalizeForCase(
          expectedText,
          test.caseSensitive,
        );
        final passed = switch (test.comparator) {
          RequestTestComparator.isEqualTo =>
            valueExists && normalizedActual == normalizedExpected,
          RequestTestComparator.isNotEqualTo =>
            !valueExists || normalizedActual != normalizedExpected,
          RequestTestComparator.contains =>
            valueExists && normalizedActual.contains(normalizedExpected),
          RequestTestComparator.doesNotContain =>
            !valueExists || !normalizedActual.contains(normalizedExpected),
          RequestTestComparator.beginsWith =>
            valueExists && normalizedActual.startsWith(normalizedExpected),
          RequestTestComparator.endsWith =>
            valueExists && normalizedActual.endsWith(normalizedExpected),
          _ => throw const FormatException('Unsupported string comparator.'),
        };
        return _passOrFail(
          test: test,
          label: label,
          passed: passed,
          expected: expectedText,
          actual: valueExists ? actualText : null,
        );
    }
  }

  RequestTestResult _evaluateXPathTest({
    required RequestTest test,
    required String label,
    required String body,
  }) {
    final path = _requiredText(test.xPath, 'XPath is required.');
    final document = xml.XmlDocument.parse(body);
    final values = _evaluateXPath(path, document);
    final actualValue = values.join(', ');

    return _evaluateStringTest(
      test: test,
      label: label,
      actualValue: values.isEmpty ? null : actualValue,
    );
  }

  String? _cookieValue(
    List<HttpCookieEntity> cookies,
    String? cookieName,
    bool caseSensitive,
  ) {
    final expectedName = cookieName?.trim() ?? '';
    if (expectedName.isEmpty) {
      return null;
    }

    for (final cookie in cookies) {
      if (_equals(cookie.name, expectedName, caseSensitive)) {
        return cookie.value;
      }
    }

    return null;
  }

  List<String> _cookieKeys(List<HttpCookieEntity> cookies, bool caseSensitive) {
    final uniqueKeys = <String>{};
    final normalizedKeys = <String>{};

    for (final cookie in cookies) {
      final name = cookie.name.trim();
      if (name.isEmpty) {
        continue;
      }

      final normalizedName = _normalizeForCase(name, caseSensitive);
      if (normalizedKeys.add(normalizedName)) {
        uniqueKeys.add(name);
      }
    }

    return uniqueKeys.toList(growable: false);
  }

  List<Object?> _evaluateJsonPath(String path, Object? root) {
    if (!path.startsWith(r'$')) {
      throw const FormatException(r'JSON Path must start with $.');
    }

    var cursor = 1;
    var currentValues = <Object?>[root];

    while (cursor < path.length) {
      if (path[cursor] == '.') {
        cursor++;
        final nextDot = _findNextSpecialCharacter(path, cursor);
        final key = path.substring(cursor, nextDot);
        if (key.trim().isEmpty) {
          throw const FormatException('JSON Path key is invalid.');
        }

        currentValues = _readJsonProperty(currentValues, key);
        cursor = nextDot;
        continue;
      }

      if (path[cursor] == '[') {
        final closingIndex = path.indexOf(']', cursor);
        if (closingIndex == -1) {
          throw const FormatException('JSON Path bracket is not closed.');
        }

        final token = path.substring(cursor + 1, closingIndex).trim();
        if (token == '*') {
          currentValues = _readJsonWildcard(currentValues);
        } else {
          final index = int.tryParse(token);
          if (index == null) {
            throw const FormatException('JSON Path array index is invalid.');
          }
          currentValues = _readJsonIndex(currentValues, index);
        }
        cursor = closingIndex + 1;
        continue;
      }

      throw const FormatException('JSON Path contains unsupported syntax.');
    }

    return currentValues;
  }

  List<String> _evaluateXPath(String path, xml.XmlDocument document) {
    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      throw const FormatException('XPath is required.');
    }

    if (trimmedPath.startsWith('//')) {
      final tagName = trimmedPath.substring(2).trim();
      if (tagName.isEmpty || tagName.contains('/')) {
        throw const FormatException('Unsupported XPath expression.');
      }

      return document
          .findAllElements(tagName)
          .map((element) => element.innerText)
          .toList(growable: false);
    }

    if (!trimmedPath.startsWith('/')) {
      throw const FormatException('XPath must start with / or //.');
    }

    final segments = trimmedPath
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      throw const FormatException('XPath is invalid.');
    }

    Iterable<xml.XmlElement> current = [document.rootElement];
    var segmentIndex = 0;

    if (document.rootElement.name.local == segments.first) {
      segmentIndex = 1;
    }

    for (var index = segmentIndex; index < segments.length; index++) {
      final segment = segments[index];
      current = current.expand(
        (element) => element.childElements.where(
          (child) => child.name.local == segment,
        ),
      );
    }

    return current.map((element) => element.innerText).toList(growable: false);
  }

  String? _headerValue(List<KeyValueItem> headers, String? headerName) {
    final normalizedHeaderName = headerName?.trim().toLowerCase() ?? '';
    if (normalizedHeaderName.isEmpty) {
      return null;
    }

    final values = headers
        .where((header) => header.key.trim().toLowerCase() == normalizedHeaderName)
        .map((header) => header.value)
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }

    return values.join(', ');
  }

  List<String> _headerKeys(List<KeyValueItem> headers, bool caseSensitive) {
    final uniqueKeys = <String>{};
    final normalizedKeys = <String>{};

    for (final header in headers) {
      final key = header.key.trim();
      if (key.isEmpty) {
        continue;
      }

      final normalizedKey = _normalizeForCase(key, caseSensitive);
      if (normalizedKeys.add(normalizedKey)) {
        uniqueKeys.add(key);
      }
    }

    return uniqueKeys.toList(growable: false);
  }

  bool _containsKey(List<String> keys, String expectedKey, bool caseSensitive) {
    final normalizedExpected = _normalizeForCase(expectedKey, caseSensitive);
    return keys.any(
      (key) => _normalizeForCase(key, caseSensitive) == normalizedExpected,
    );
  }

  bool _equals(String left, String right, bool caseSensitive) =>
      _normalizeForCase(left, caseSensitive) ==
      _normalizeForCase(right, caseSensitive);

  int _findNextSpecialCharacter(String path, int startIndex) {
    var cursor = startIndex;
    while (cursor < path.length &&
        path[cursor] != '.' &&
        path[cursor] != '[') {
      cursor++;
    }

    return cursor;
  }

  String _formatNum(num value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _normalizeForCase(String value, bool caseSensitive) =>
      caseSensitive ? value : value.toLowerCase();

  num _parseRequiredNumber(String? value, {required String fieldName}) {
    final trimmed = value?.trim() ?? '';
    final parsed = num.tryParse(trimmed);
    if (parsed == null) {
      throw FormatException('$fieldName must be a valid number.');
    }

    return parsed;
  }

  RequestTestResult _passOrFail({
    required RequestTest test,
    required String label,
    required bool passed,
    String? expected,
    String? actual,
  }) => RequestTestResult(
    testId: test.id,
    label: label,
    status: passed
        ? RequestTestResultStatus.passed
        : RequestTestResultStatus.failed,
    expected: expected,
    actual: actual,
    message: passed ? null : 'Assertion failed.',
  );

  List<Object?> _readJsonIndex(List<Object?> values, int index) {
    final nextValues = <Object?>[];
    for (final value in values) {
      if (value is List && index >= 0 && index < value.length) {
        nextValues.add(value[index]);
      }
    }

    return nextValues;
  }

  List<Object?> _readJsonProperty(List<Object?> values, String key) {
    final nextValues = <Object?>[];
    for (final value in values) {
      if (value is Map && value.containsKey(key)) {
        nextValues.add(value[key]);
      }
    }

    return nextValues;
  }

  List<Object?> _readJsonWildcard(List<Object?> values) {
    final nextValues = <Object?>[];
    for (final value in values) {
      if (value is List) {
        nextValues.addAll(value);
      } else if (value is Map) {
        nextValues.addAll(value.values);
      }
    }

    return nextValues;
  }

  String _requiredText(String? value, String message) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw FormatException(message);
    }

    return trimmed;
  }

  String _serializeEvaluatedValues(List<Object?> values) {
    if (values.isEmpty) {
      return '';
    }

    if (values.length == 1) {
      return _serializeSingleJsonValue(values.first);
    }

    return values.map(_serializeSingleJsonValue).join(', ');
  }

  String _serializeSingleJsonValue(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }
}
