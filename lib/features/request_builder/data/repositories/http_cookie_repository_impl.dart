import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/http_cookie_entity.dart';
import '../../domain/helpers/http_cookie_utils.dart';
import '../../domain/repositories/http_cookie_repository.dart';
import '../models/http_cookie_model.dart';

class HttpCookieRepositoryImpl implements HttpCookieRepository {
  static const _storageKey = 'request_builder_http_cookies';

  List<HttpCookieEntity>? _cache;
  int _idSeed = 0;

  @override
  Future<void> deleteCookie(String id) async {
    final cookies = await _readCookies();
    final updatedCookies = cookies
        .where((cookie) => cookie.id != id)
        .toList(growable: false);
    await _persistCookies(updatedCookies);
  }

  @override
  Future<void> deleteExpiredCookies() async {
    final cookies = await _readCookies();
    final now = DateTime.now().toUtc();
    final updatedCookies = cookies
        .where((cookie) => cookie.expiresAt == null || cookie.expiresAt!.isAfter(now))
        .toList(growable: false);
    await _persistCookies(updatedCookies);
  }

  @override
  Future<List<HttpCookieEntity>> getAllCookies() async => _readCookies();

  @override
  Future<List<HttpCookieEntity>> getCookiesForDomain(String domain) async {
    final normalizedDomain = normalizeCookieDomainInput(domain);
    if (normalizedDomain == null) {
      return const <HttpCookieEntity>[];
    }

    final cookies = await _readCookies();
    return cookies
        .where(
          (cookie) => cookieDomainMatches(
            cookieDomain: cookie.domain,
            requestHost: normalizedDomain,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<HttpCookieEntity>> getCookiesForRequestUrl(String url) async {
    final requestUri = tryParseRequestUri(url);
    if (requestUri == null) {
      return const <HttpCookieEntity>[];
    }

    final cookies = await _readCookies();
    return cookies
        .where((cookie) => cookieMatchesRequest(cookie: cookie, requestUri: requestUri))
        .toList(growable: false);
  }

  @override
  Future<void> saveCookie(HttpCookieEntity cookie) async {
    await _upsertCookie(cookie, preserveIdWhenPossible: true);
  }

  @override
  Future<void> updateCookie(HttpCookieEntity cookie) async {
    await _upsertCookie(cookie, preserveIdWhenPossible: false);
  }

  @override
  Future<void> upsertCookiesFromSetCookieHeaders(
    String requestUrl,
    List<String> setCookieHeaders,
  ) async {
    if (setCookieHeaders.isEmpty) {
      return;
    }

    var cookies = await _readCookies();
    var hasChanges = false;

    for (final header in setCookieHeaders) {
      final requestHost = tryParseRequestHost(requestUrl);
      if (requestHost == null) {
        continue;
      }

      final provisionalCookie = parseSetCookieHeader(
        header: header,
        requestUrl: requestUrl,
      );
      if (provisionalCookie == null) {
        continue;
      }

      final existingCookie = _findCookieByScope(
        cookies,
        name: provisionalCookie.name,
        domain: provisionalCookie.domain,
        path: provisionalCookie.path,
      );
      final parsedCookie = parseSetCookieHeader(
        header: header,
        requestUrl: requestUrl,
        existingCookie: existingCookie,
      );
      if (parsedCookie == null) {
        continue;
      }

      final normalizedCookie = _normalizeCookie(
        parsedCookie.copyWith(id: existingCookie?.id ?? parsedCookie.id),
      );
      if (normalizedCookie == null) {
        continue;
      }

      cookies = _removeCookieByScope(
        cookies,
        name: normalizedCookie.name,
        domain: normalizedCookie.domain,
        path: normalizedCookie.path,
      );

      if (normalizedCookie.expiresAt != null &&
          !normalizedCookie.expiresAt!.isAfter(DateTime.now().toUtc())) {
        hasChanges = true;
        continue;
      }

      cookies = List<HttpCookieEntity>.unmodifiable([...cookies, normalizedCookie]);
      hasChanges = true;
    }

    if (hasChanges) {
      await _persistCookies(cookies);
    }
  }

  HttpCookieEntity? _findCookieByScope(
    List<HttpCookieEntity> cookies, {
    required String name,
    required String domain,
    required String path,
  }) {
    for (final cookie in cookies) {
      if (cookie.name == name &&
          cookie.domain == domain &&
          cookie.path == path) {
        return cookie;
      }
    }

    return null;
  }

  String _generateId() =>
      '${DateTime.now().toUtc().microsecondsSinceEpoch}-${_idSeed++}';

  HttpCookieEntity? _normalizeCookie(HttpCookieEntity cookie) {
    final normalizedName = cookie.name.trim();
    final normalizedDomain = normalizeCookieDomainInput(cookie.domain);
    if (normalizedName.isEmpty || normalizedDomain == null) {
      return null;
    }

    final now = DateTime.now().toUtc();
    return cookie.copyWith(
      id: cookie.id.trim().isEmpty ? _generateId() : cookie.id.trim(),
      name: normalizedName,
      domain: normalizedDomain,
      path: normalizeCookiePath(cookie.path),
      sameSite: normalizeCookieSameSite(cookie.sameSite),
      createdAt: cookie.createdAt.toUtc(),
      updatedAt: cookie.updatedAt.toUtc().isBefore(now)
          ? cookie.updatedAt.toUtc()
          : cookie.updatedAt.toUtc(),
    );
  }

  Future<void> _persistCookies(List<HttpCookieEntity> cookies) async {
    final normalizedCookies = cookies
        .map(_normalizeCookie)
        .whereType<HttpCookieEntity>()
        .toList(growable: false)
      ..sort((left, right) {
        final domainCompare = left.domain.compareTo(right.domain);
        if (domainCompare != 0) {
          return domainCompare;
        }

        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }

        return left.path.compareTo(right.path);
      });

    _cache = List<HttpCookieEntity>.unmodifiable(normalizedCookies);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(
        normalizedCookies
            .map((cookie) => HttpCookieModel.fromEntity(cookie).toJson())
            .toList(growable: false),
      ),
    );
  }

  Future<List<HttpCookieEntity>> _readCookies() async {
    final cachedCookies = _cache;
    if (cachedCookies != null) {
      return cachedCookies;
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <HttpCookieEntity>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <HttpCookieEntity>[];
      }

      final now = DateTime.now().toUtc();
      final restoredCookies = decoded
          .whereType<Map>()
          .map((item) => HttpCookieModel.fromJson(Map<String, dynamic>.from(item)).toEntity())
          .map(_normalizeCookie)
          .whereType<HttpCookieEntity>()
          .where(
            (cookie) => cookie.expiresAt == null || cookie.expiresAt!.isAfter(now),
          )
          .toList(growable: false);

      _cache = List<HttpCookieEntity>.unmodifiable(restoredCookies);
      if (restoredCookies.length != decoded.length) {
        await _persistCookies(restoredCookies);
      }

      return _cache!;
    } catch (_) {
      return const <HttpCookieEntity>[];
    }
  }

  List<HttpCookieEntity> _removeCookieByScope(
    List<HttpCookieEntity> cookies, {
    required String name,
    required String domain,
    required String path,
  }) => cookies
      .where(
        (cookie) =>
            cookie.name != name || cookie.domain != domain || cookie.path != path,
      )
      .toList(growable: false);

  Future<void> _upsertCookie(
    HttpCookieEntity cookie, {
    required bool preserveIdWhenPossible,
  }) async {
    final normalizedCookie = _normalizeCookie(cookie);
    if (normalizedCookie == null) {
      return;
    }

    final cookies = await _readCookies();
    final existingCookie = _findCookieByScope(
      cookies,
      name: normalizedCookie.name,
      domain: normalizedCookie.domain,
      path: normalizedCookie.path,
    );
    final nextCookie = normalizedCookie.copyWith(
      id: preserveIdWhenPossible
          ? (cookie.id.trim().isNotEmpty
                ? cookie.id.trim()
                : existingCookie?.id ?? normalizedCookie.id)
          : (cookie.id.trim().isNotEmpty
                ? cookie.id.trim()
                : existingCookie?.id ?? normalizedCookie.id),
      createdAt: existingCookie?.createdAt ?? normalizedCookie.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    final updatedCookies = [
      ...cookies.where(
        (existing) =>
            existing.id != nextCookie.id &&
            (existing.name != nextCookie.name ||
                existing.domain != nextCookie.domain ||
                existing.path != nextCookie.path),
      ),
      nextCookie,
    ];

    await _persistCookies(updatedCookies);
  }
}
