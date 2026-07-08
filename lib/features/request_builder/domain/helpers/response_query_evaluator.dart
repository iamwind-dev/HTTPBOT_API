import 'dart:convert';

import 'package:xml/xml.dart' as xml;

List<Object?> evaluateJsonPathExpression(String path, Object? root) {
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

List<Object?> evaluateJqExpression(String query, Object? root) {
  final stages = query
      .split('|')
      .map((stage) => stage.trim())
      .where((stage) => stage.isNotEmpty)
      .toList(growable: false);
  if (stages.isEmpty) {
    throw const FormatException('jq query is required.');
  }

  var currentValues = <Object?>[root];
  for (final stage in stages) {
    currentValues = _applyJqStage(stage, currentValues);
  }

  return currentValues;
}

List<String> evaluateXPathExpression(String path, xml.XmlDocument document) {
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
      (element) =>
          element.childElements.where((child) => child.name.local == segment),
    );
  }

  return current.map((element) => element.innerText).toList(growable: false);
}

String serializeEvaluatedJsonValues(List<Object?> values) {
  if (values.isEmpty) {
    return '';
  }

  if (values.length == 1) {
    return _serializeSingleJsonValue(values.first);
  }

  return values.map(_serializeSingleJsonValue).join(', ');
}

String prettyPrintJsonValue(Object? value) {
  const encoder = JsonEncoder.withIndent('  ');
  if (value is String) {
    return value;
  }

  return encoder.convert(value);
}

List<Object?> _applyJqStage(String stage, List<Object?> values) {
  final trimmed = stage.trim();
  if (trimmed == '.') {
    return values;
  }
  if (!trimmed.startsWith('.')) {
    throw const FormatException('jq query must start with .');
  }

  var cursor = 1;
  var currentValues = values;

  while (cursor < trimmed.length) {
    if (trimmed[cursor] == '.') {
      cursor++;
      continue;
    }

    if (trimmed[cursor] == '[') {
      final closingIndex = trimmed.indexOf(']', cursor);
      if (closingIndex == -1) {
        throw const FormatException('jq bracket is not closed.');
      }

      final token = trimmed.substring(cursor + 1, closingIndex).trim();
      if (token.isEmpty || token == '*') {
        currentValues = _readJsonWildcard(currentValues);
      } else {
        final index = int.tryParse(token);
        if (index == null) {
          throw const FormatException('jq array index is invalid.');
        }
        currentValues = _readJsonIndex(currentValues, index);
      }
      cursor = closingIndex + 1;
      continue;
    }

    final nextSpecial = _findNextSpecialCharacter(trimmed, cursor);
    final key = trimmed.substring(cursor, nextSpecial).trim();
    if (key.isEmpty) {
      throw const FormatException('jq key is invalid.');
    }
    currentValues = _readJsonProperty(currentValues, key);
    cursor = nextSpecial;
  }

  return currentValues;
}

int _findNextSpecialCharacter(String path, int startIndex) {
  var cursor = startIndex;
  while (cursor < path.length && path[cursor] != '.' && path[cursor] != '[') {
    cursor++;
  }

  return cursor;
}

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

String _serializeSingleJsonValue(Object? value) {
  if (value == null) {
    return 'null';
  }

  if (value is String) {
    return value;
  }

  return jsonEncode(value);
}
