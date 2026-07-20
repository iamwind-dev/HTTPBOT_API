/// Raised when a jq query uses syntax outside the supported subset.
class JqUnsupportedQueryException implements Exception {
  const JqUnsupportedQueryException();
}

/// Sentinel marking a value the document does not contain, so callers can
/// distinguish "absent" from an explicit JSON null.
const Object _missing = Object();

/// Evaluates a small jq subset against decoded JSON.
///
/// Supported: identity `.`, property access `.a` / `.a.b`, quoted keys
/// `.a["k"]` / `."k"`, array index `.a[0]`, array projection `.a[]`, the
/// builtins `keys` and `length`, and pipes joining any of the above.
///
/// Returns the produced value (which may be `null`). Throws
/// [JqUnsupportedQueryException] for anything outside the subset.
Object? evaluateJq({required Object? json, required String query}) {
  final stages = query
      .split('|')
      .map((stage) => stage.trim())
      .toList(growable: false);
  if (stages.any((stage) => stage.isEmpty)) {
    throw const JqUnsupportedQueryException();
  }

  var current = json;
  for (final stage in stages) {
    final result = _applyStage(current, stage);
    current = identical(result, _missing) ? null : result;
  }
  return current;
}

Object? _applyStage(Object? value, String stage) {
  if (stage == 'keys') {
    return _builtinKeys(value);
  }
  if (stage == 'length') {
    return _builtinLength(value);
  }
  if (stage == '.') {
    return value;
  }
  if (!stage.startsWith('.')) {
    throw const JqUnsupportedQueryException();
  }

  return _applyPath(value, stage);
}

Object? _applyPath(Object? value, String stage) {
  final tokens = _tokenizePath(stage);
  var current = <Object?>[value];

  for (final token in tokens) {
    final next = <Object?>[];
    for (final item in current) {
      if (identical(item, _missing)) {
        next.add(_missing);
        continue;
      }
      next.addAll(token.apply(item));
    }
    current = next;
  }

  final resolved = current
      .map((item) => identical(item, _missing) ? null : item)
      .toList(growable: false);
  if (resolved.length == 1) {
    return resolved.first;
  }
  return resolved;
}

abstract class _PathToken {
  Iterable<Object?> apply(Object? value);
}

class _PropertyToken implements _PathToken {
  const _PropertyToken(this.key);
  final String key;

  @override
  Iterable<Object?> apply(Object? value) {
    if (value is Map) {
      return [value.containsKey(key) ? value[key] : _missing];
    }
    return const [_missing];
  }
}

class _IndexToken implements _PathToken {
  const _IndexToken(this.index);
  final int index;

  @override
  Iterable<Object?> apply(Object? value) {
    if (value is List && index >= 0 && index < value.length) {
      return [value[index]];
    }
    return const [_missing];
  }
}

class _IterateToken implements _PathToken {
  const _IterateToken();

  @override
  Iterable<Object?> apply(Object? value) {
    if (value is List) {
      return value;
    }
    if (value is Map) {
      return value.values;
    }
    return const [_missing];
  }
}

List<_PathToken> _tokenizePath(String stage) {
  final tokens = <_PathToken>[];
  var i = 0;
  final source = stage;
  final length = source.length;

  while (i < length) {
    final char = source[i];
    if (char == '.') {
      i++;
      if (i < length && source[i] == '"') {
        final parsed = _readQuoted(source, i);
        tokens.add(_PropertyToken(parsed.value));
        i = parsed.nextIndex;
      } else {
        final start = i;
        while (i < length && _isIdentifierChar(source[i])) {
          i++;
        }
        if (i == start) {
          throw const JqUnsupportedQueryException();
        }
        tokens.add(_PropertyToken(source.substring(start, i)));
      }
    } else if (char == '[') {
      i++;
      if (i < length && source[i] == ']') {
        tokens.add(const _IterateToken());
        i++;
      } else if (i < length && (source[i] == '"' || source[i] == "'")) {
        final quote = source[i];
        final parsed = _readQuoted(source, i, quote: quote);
        if (parsed.nextIndex >= length || source[parsed.nextIndex] != ']') {
          throw const JqUnsupportedQueryException();
        }
        tokens.add(_PropertyToken(parsed.value));
        i = parsed.nextIndex + 1;
      } else {
        final start = i;
        while (i < length && source[i] != ']') {
          i++;
        }
        if (i >= length) {
          throw const JqUnsupportedQueryException();
        }
        final raw = source.substring(start, i);
        final index = int.tryParse(raw.trim());
        if (index == null) {
          throw const JqUnsupportedQueryException();
        }
        tokens.add(_IndexToken(index));
        i++;
      }
    } else {
      throw const JqUnsupportedQueryException();
    }
  }

  return tokens;
}

class _QuotedRead {
  const _QuotedRead(this.value, this.nextIndex);
  final String value;
  final int nextIndex;
}

_QuotedRead _readQuoted(String source, int openIndex, {String quote = '"'}) {
  final buffer = StringBuffer();
  var i = openIndex + 1;
  while (i < source.length) {
    final char = source[i];
    if (char == '\\' && i + 1 < source.length) {
      buffer.write(source[i + 1]);
      i += 2;
      continue;
    }
    if (char == quote) {
      return _QuotedRead(buffer.toString(), i + 1);
    }
    buffer.write(char);
    i++;
  }
  throw const JqUnsupportedQueryException();
}

bool _isIdentifierChar(String char) {
  return RegExp(r'[A-Za-z0-9_\-]').hasMatch(char);
}

List<Object?> _builtinKeys(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return keys;
  }
  if (value is List) {
    return List<int>.generate(value.length, (index) => index);
  }
  throw const JqUnsupportedQueryException();
}

int _builtinLength(Object? value) {
  if (value is Map) {
    return value.length;
  }
  if (value is List) {
    return value.length;
  }
  if (value is String) {
    return value.length;
  }
  throw const JqUnsupportedQueryException();
}
