import '../entities/http_cookie_entity.dart';

abstract class HttpCookieRepository {
  Future<List<HttpCookieEntity>> getAllCookies();

  Future<List<HttpCookieEntity>> getCookiesForDomain(String domain);

  Future<List<HttpCookieEntity>> getCookiesForRequestUrl(String url);

  Future<void> saveCookie(HttpCookieEntity cookie);

  Future<void> updateCookie(HttpCookieEntity cookie);

  Future<void> deleteCookie(String id);

  Future<void> deleteExpiredCookies();

  Future<void> upsertCookiesFromSetCookieHeaders(
    String requestUrl,
    List<String> setCookieHeaders,
  );
}
