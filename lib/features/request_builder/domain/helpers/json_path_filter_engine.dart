/// Raised when a JSONPath query uses syntax outside the supported subset.
class JsonPathUnsupportedQueryException implements Exception {
  const JsonPathUnsupportedQueryException();
}

const Object _missing = Object();

/// Evaluates a small JSONPath subset against decoded JSON.
///
/// Supported: root `$`, dot property `$.a` / `$.a.b`, bracket property
/// `$['a']` / `$["a"]`, array index `$.a[0]`, and wildcard `$.a[*]`.
///
/// Returns the produced value (which may be `null`). Throws
/// [JsonPathUnsupportedQueryException] for anything outside the subset.
Object? evaluateJsonPath({required Object? json, required String query}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty || trimmed[0] != r'$') {
    throw const JsonPathUnsupportedQueryException();
  }

  final tokens = _tokenize(trimmed.substring(1));
  var current = <Object?>[json];

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

class _WildcardToken implements _PathToken {
  const _WildcardToken();

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

List<_PathToken> _tokenize(String source) {
  final tokens = <_PathToken>[];
  var i = 0;
  final length = source.length;

  while (i < length) {
    final char = source[i];
    if (char == '.') {
      i++;
      if (i < length && source[i] == '*') {
        tokens.add(const _WildcardToken());
        i++;
        continue;
      }
      final start = i;
      while (i < length && _isIdentifierChar(source[i])) {
        i++;
      }
      if (i == start) {
        throw const JsonPathUnsupportedQueryException();
      }
      tokens.add(_PropertyToken(source.substring(start, i)));
    } else if (char == '[') {
      i++;
      if (i < length && source[i] == '*') {
        if (i + 1 >= length || source[i + 1] != ']') {
          throw const JsonPathUnsupportedQueryException();
        }
        tokens.add(const _WildcardToken());
        i += 2;
      } else if (i < length && (source[i] == '"' || source[i] == "'")) {
        final quote = source[i];
        final parsed = _readQuoted(source, i, quote);
        if (parsed.nextIndex >= length || source[parsed.nextIndex] != ']') {
          throw const JsonPathUnsupportedQueryException();
        }
        tokens.add(_PropertyToken(parsed.value));
        i = parsed.nextIndex + 1;
      } else {
        final start = i;
        while (i < length && source[i] != ']') {
          i++;
        }
        if (i >= length) {
          throw const JsonPathUnsupportedQueryException();
        }
        final index = int.tryParse(source.substring(start, i).trim());
        if (index == null) {
          throw const JsonPathUnsupportedQueryException();
        }
        tokens.add(_IndexToken(index));
        i++;
      }
    } else {
      throw const JsonPathUnsupportedQueryException();
    }
  }

  return tokens;
}

class _QuotedRead {
  const _QuotedRead(this.value, this.nextIndex);
  final String value;
  final int nextIndex;
}

_QuotedRead _readQuoted(String source, int openIndex, String quote) {
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
  throw const JsonPathUnsupportedQueryException();
}

bool _isIdentifierChar(String char) {
  return RegExp(r'[A-Za-z0-9_\-]').hasMatch(char);
}
