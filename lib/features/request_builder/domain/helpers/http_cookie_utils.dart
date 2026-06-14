import 'dart:io';

import '../entities/http_cookie_entity.dart';

String? tryParseRequestHost(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.trim().isEmpty) {
    return null;
  }

  return uri.host.toLowerCase();
}

Uri? tryParseRequestUri(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.trim().isEmpty) {
    return null;
  }

  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return null;
  }

  return uri;
}

String? normalizeCookieDomainInput(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return null;
  }

  if (trimmed.contains('://') ||
      trimmed.contains('/') ||
      trimmed.contains('?') ||
      trimmed.contains('#') ||
      trimmed.contains(' ')) {
    return null;
  }

  final normalized = trimmed.startsWith('.') ? trimmed.substring(1) : trimmed;
  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}

String normalizeCookiePath(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '/';
  }

  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}

String? normalizeCookieSameSite(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  return switch (normalized) {
    'strict' => 'Strict',
    'lax' => 'Lax',
    'none' => 'None',
    _ => null,
  };
}

bool cookieDomainMatches({
  required String cookieDomain,
  required String requestHost,
}) {
  final normalizedCookieDomain = normalizeCookieDomainInput(cookieDomain);
  final normalizedRequestHost = requestHost.trim().toLowerCase();
  if (normalizedCookieDomain == null || normalizedRequestHost.isEmpty) {
    return false;
  }

  if (normalizedRequestHost == normalizedCookieDomain) {
    return true;
  }

  return normalizedRequestHost.endsWith('.$normalizedCookieDomain');
}

bool cookiePathMatches({
  required String cookiePath,
  required String requestPath,
}) {
  final normalizedCookiePath = normalizeCookiePath(cookiePath);
  final normalizedRequestPath = requestPath.trim().isEmpty
      ? '/'
      : requestPath.trim();

  return normalizedRequestPath.startsWith(normalizedCookiePath);
}

bool cookieMatchesRequest({
  required HttpCookieEntity cookie,
  required Uri requestUri,
  DateTime? now,
}) {
  final effectiveNow = (now ?? DateTime.now()).toUtc();
  final expiresAt = cookie.expiresAt?.toUtc();
  if (expiresAt != null && !expiresAt.isAfter(effectiveNow)) {
    return false;
  }

  if (cookie.secure && requestUri.scheme.toLowerCase() != 'https') {
    return false;
  }

  if (!cookieDomainMatches(
    cookieDomain: cookie.domain,
    requestHost: requestUri.host,
  )) {
    return false;
  }

  return cookiePathMatches(
    cookiePath: cookie.path,
    requestPath: requestUri.path.isEmpty ? '/' : requestUri.path,
  );
}

Map<String, String> mergeCookieHeader({
  required Map<String, String> headers,
  required List<HttpCookieEntity> cookies,
}) {
  final mergedCookies = <String, String>{};
  for (final cookie in cookies) {
    final name = cookie.name.trim();
    if (name.isEmpty) {
      continue;
    }

    mergedCookies[name] = cookie.value;
  }

  String? manualHeaderKey;
  String? manualCookieHeader;

  for (final entry in headers.entries) {
    if (entry.key.trim().toLowerCase() == 'cookie') {
      manualHeaderKey = entry.key;
      manualCookieHeader = entry.value;
    }
  }

  if (manualCookieHeader != null && manualCookieHeader.trim().isNotEmpty) {
    for (final entry in _parseCookieHeader(manualCookieHeader).entries) {
      mergedCookies[entry.key] = entry.value;
    }
  }

  final sanitizedHeaders = <String, String>{};
  headers.forEach((key, value) {
    if (key.trim().toLowerCase() != 'cookie') {
      sanitizedHeaders[key] = value;
    }
  });

  if (mergedCookies.isEmpty) {
    return sanitizedHeaders;
  }

  final headerValue = mergedCookies.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('; ');
  sanitizedHeaders[manualHeaderKey ?? 'Cookie'] = headerValue;
  return sanitizedHeaders;
}

Map<String, String> _parseCookieHeader(String header) {
  final cookies = <String, String>{};
  for (final part in header.split(';')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    final name = trimmed.substring(0, separatorIndex).trim();
    if (name.isEmpty) {
      continue;
    }

    cookies[name] = trimmed.substring(separatorIndex + 1).trim();
  }

  return cookies;
}

HttpCookieEntity? parseSetCookieHeader({
  required String header,
  required String requestUrl,
  HttpCookieEntity? existingCookie,
  DateTime? now,
}) {
  final requestUri = tryParseRequestUri(requestUrl);
  if (requestUri == null) {
    return null;
  }

  final effectiveNow = (now ?? DateTime.now()).toUtc();
  final segments = header.split(';');
  if (segments.isEmpty) {
    return null;
  }

  final nameValue = segments.first.trim();
  final separatorIndex = nameValue.indexOf('=');
  if (separatorIndex <= 0) {
    return null;
  }

  final name = nameValue.substring(0, separatorIndex).trim();
  final value = nameValue.substring(separatorIndex + 1);
  if (name.isEmpty) {
    return null;
  }

  var domain = requestUri.host.toLowerCase();
  var path = '/';
  var expiresAt = existingCookie?.expiresAt;
  var secure = false;
  var httpOnly = false;
  String? sameSite;
  int? maxAgeSeconds;

  for (final rawAttribute in segments.skip(1)) {
    final attribute = rawAttribute.trim();
    if (attribute.isEmpty) {
      continue;
    }

    final attributeSeparatorIndex = attribute.indexOf('=');
    final attributeName = (attributeSeparatorIndex == -1
            ? attribute
            : attribute.substring(0, attributeSeparatorIndex))
        .trim()
        .toLowerCase();
    final attributeValue = attributeSeparatorIndex == -1
        ? ''
        : attribute.substring(attributeSeparatorIndex + 1).trim();

    switch (attributeName) {
      case 'domain':
        final normalizedDomain = normalizeCookieDomainInput(attributeValue);
        if (normalizedDomain == null ||
            !cookieDomainMatches(
              cookieDomain: normalizedDomain,
              requestHost: requestUri.host,
            )) {
          return null;
        }
        domain = normalizedDomain;
      case 'path':
        path = normalizeCookiePath(attributeValue);
      case 'expires':
        try {
          expiresAt = HttpDate.parse(attributeValue).toUtc();
        } on FormatException {
          // Ignore malformed expires attributes.
        }
      case 'max-age':
        maxAgeSeconds = int.tryParse(attributeValue);
      case 'secure':
        secure = true;
      case 'httponly':
        httpOnly = true;
      case 'samesite':
        sameSite = normalizeCookieSameSite(attributeValue);
    }
  }

  if (maxAgeSeconds != null) {
    expiresAt = effectiveNow.add(Duration(seconds: maxAgeSeconds));
  }

  return HttpCookieEntity(
    id: existingCookie?.id ?? '',
    name: name,
    value: value,
    domain: domain,
    path: path,
    expiresAt: expiresAt,
    secure: secure,
    httpOnly: httpOnly,
    sameSite: sameSite,
    createdAt: existingCookie?.createdAt ?? effectiveNow,
    updatedAt: effectiveNow,
  );
}
