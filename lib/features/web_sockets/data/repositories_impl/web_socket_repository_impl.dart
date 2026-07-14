import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../domain/entities/web_socket_request_entity.dart';
import '../../domain/entities/web_socket_settings_entity.dart';
import '../../domain/repositories/web_socket_repository.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  static const _storageKey = 'websockets_requests_list';

  List<WebSocketRequestEntity>? _cachedRequests;

  @override
  Future<List<WebSocketRequestEntity>> getRequests() async {
    final cached = _cachedRequests;
    if (cached != null) {
      return cached;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawList = preferences.getString(_storageKey);
    if (rawList == null || rawList.trim().isEmpty) {
      _cachedRequests = const <WebSocketRequestEntity>[];
      return const <WebSocketRequestEntity>[];
    }

    try {
      final decoded = jsonDecode(rawList);
      if (decoded is! List) {
        _cachedRequests = const <WebSocketRequestEntity>[];
        return const <WebSocketRequestEntity>[];
      }

      final requests = decoded
          .whereType<Map>()
          .map((item) => _requestFromJson(Map<String, dynamic>.from(item)))
          .toList();
      _cachedRequests = requests;
      return requests;
    } catch (_) {
      _cachedRequests = const <WebSocketRequestEntity>[];
      return const <WebSocketRequestEntity>[];
    }
  }

  @override
  Future<WebSocketRequestEntity> createRequest(WebSocketRequestEntity request) async {
    final requests = List<WebSocketRequestEntity>.from(await getRequests());
    requests.add(request);
    _cachedRequests = requests;
    await _persist(requests);
    return request;
  }

  @override
  Future<WebSocketRequestEntity> updateRequest(WebSocketRequestEntity request) async {
    final requests = List<WebSocketRequestEntity>.from(await getRequests());
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      requests[index] = request;
    } else {
      requests.add(request);
    }
    _cachedRequests = requests;
    await _persist(requests);
    return request;
  }

  @override
  Future<void> deleteRequest(String id) async {
    final requests = List<WebSocketRequestEntity>.from(await getRequests());
    requests.removeWhere((r) => r.id == id);
    _cachedRequests = requests;
    await _persist(requests);
  }

  Future<void> _persist(List<WebSocketRequestEntity> requests) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      requests.map(_requestToJson).toList(growable: false),
    );
    await preferences.setString(_storageKey, raw);
  }

  Map<String, Object?> _requestToJson(WebSocketRequestEntity request) => {
        'id': request.id,
        'name': request.name,
        'url': request.url,
        'queryParameters': request.queryParameters.map(_keyValueItemToJson).toList(growable: false),
        'headers': request.headers.map(_keyValueItemToJson).toList(growable: false),
        'auth': _requestAuthDraftToJson(request.auth),
        'settings': {
          'handshakeTimeoutSeconds': request.settings.handshakeTimeoutSeconds,
          'verifySsl': request.settings.verifySsl,
        },
        'createdAt': request.createdAt?.toIso8601String(),
        'updatedAt': request.updatedAt?.toIso8601String(),
      };

  WebSocketRequestEntity _requestFromJson(Map<String, dynamic> json) =>
      WebSocketRequestEntity(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled Request',
        url: json['url'] as String? ?? '',
        queryParameters: _listFromJson(json['queryParameters'], _keyValueItemFromJson),
        headers: _listFromJson(json['headers'], _keyValueItemFromJson),
        auth: _requestAuthDraftFromJson(_mapFromJson(json['auth'])),
        settings: _settingsFromJson(_mapFromJson(json['settings'])),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  WebSocketSettingsEntity _settingsFromJson(Map<String, dynamic> json) =>
      WebSocketSettingsEntity(
        handshakeTimeoutSeconds: json['handshakeTimeoutSeconds'] as int? ?? 30,
        verifySsl: json['verifySsl'] as bool? ?? true,
      );

  Map<String, Object?> _keyValueItemToJson(KeyValueItem item) => {
        'key': item.key,
        'value': item.value,
        'isEnabled': item.isEnabled,
        'type': item.type.name,
        'contentType': item.contentType,
        'description': item.description,
      };

  KeyValueItem _keyValueItemFromJson(Map<String, dynamic> json) => KeyValueItem(
        key: json['key'] as String? ?? '',
        value: json['value'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? true,
        type: _keyValueItemTypeFromName(json['type'] as String?),
        contentType: json['contentType'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  KeyValueItemType _keyValueItemTypeFromName(String? value) =>
      value == 'file' ? KeyValueItemType.file : KeyValueItemType.text;

  Map<String, Object?> _requestAuthDraftToJson(RequestAuthDraft auth) => {
        'type': auth.type.name,
        'basic': {'username': auth.basic.username, 'password': auth.basic.password},
        'apiKey': {
          'name': auth.apiKey.name,
          'value': auth.apiKey.value,
          'location': auth.apiKey.location.name,
        },
        'bearerToken': {
          'token': auth.bearerToken.token,
          'prefix': auth.bearerToken.prefix,
        },
        'digest': {
          'username': auth.digest.username,
          'password': auth.digest.password,
          'realm': auth.digest.realm,
          'nonce': auth.digest.nonce,
          'algorithm': auth.digest.algorithm,
          'qop': auth.digest.qop,
          'nonceCount': auth.digest.nonceCount,
          'clientNonce': auth.digest.clientNonce,
          'opaque': auth.digest.opaque,
        },
        'hawk': {
          'identifier': auth.hawk.identifier,
          'key': auth.hawk.key,
          'algorithm': auth.hawk.algorithm,
          'user': auth.hawk.user,
          'nonce': auth.hawk.nonce,
          'ext': auth.hawk.ext,
          'app': auth.hawk.app,
          'delegation': auth.hawk.delegation,
          'timestamp': auth.hawk.timestamp,
          'includePayloadHash': auth.hawk.includePayloadHash,
        },
        'jwt': {
          'token': auth.jwt.token,
          'header': auth.jwt.header,
          'payload': auth.jwt.payload,
          'secret': auth.jwt.secret,
          'algorithm': auth.jwt.algorithm,
          'base64EncodedSecret': auth.jwt.base64EncodedSecret,
          'privateKey': auth.jwt.privateKey,
          'sendAsHeader': auth.jwt.sendAsHeader,
          'prefix': auth.jwt.prefix,
        },
        'ntlm': {
          'username': auth.ntlm.username,
          'password': auth.ntlm.password,
          'domain': auth.ntlm.domain,
          'workstation': auth.ntlm.workstation,
        },
        'aws': {
          'accessKey': auth.aws.accessKey,
          'secretKey': auth.aws.secretKey,
          'region': auth.aws.region,
          'service': auth.aws.service,
          'sessionToken': auth.aws.sessionToken,
        },
        'oauth1': {
          'consumerKey': auth.oauth1.consumerKey,
          'consumerSecret': auth.oauth1.consumerSecret,
          'token': auth.oauth1.token,
          'tokenSecret': auth.oauth1.tokenSecret,
          'signatureMethod': auth.oauth1.signatureMethod,
          'realm': auth.oauth1.realm,
          'version': auth.oauth1.version,
          'nonce': auth.oauth1.nonce,
          'timestamp': auth.oauth1.timestamp,
          'verifier': auth.oauth1.verifier,
          'callback': auth.oauth1.callback,
          'includeEmptyParameters': auth.oauth1.includeEmptyParameters,
          'includeBodyHash': auth.oauth1.includeBodyHash,
        },
        'oauth2': {
          'accessToken': auth.oauth2.accessToken,
          'refreshToken': auth.oauth2.refreshToken,
          'grantType': auth.oauth2.grantType.name,
          'authorizationUrl': auth.oauth2.authorizationUrl,
          'accessTokenUrl': auth.oauth2.accessTokenUrl,
          'clientId': auth.oauth2.clientId,
          'clientSecret': auth.oauth2.clientSecret,
          'tokenUrl': auth.oauth2.tokenUrl,
          'scopes': auth.oauth2.scopes,
        },
      };

  RequestAuthDraft _requestAuthDraftFromJson(Map<String, dynamic> json) =>
      RequestAuthDraft(
        type: _authTypeFromName(json['type'] as String?),
        basic: _basicAuthDraftFromJson(_mapFromJson(json['basic'])),
        apiKey: _apiKeyAuthDraftFromJson(_mapFromJson(json['apiKey'])),
        bearerToken: _bearerTokenAuthDraftFromJson(
          _mapFromJson(json['bearerToken']),
        ),
      );

  BasicAuthDraft _basicAuthDraftFromJson(Map<String, dynamic> json) =>
      BasicAuthDraft(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  ApiKeyAuthDraft _apiKeyAuthDraftFromJson(Map<String, dynamic> json) =>
      ApiKeyAuthDraft(
        name: json['name'] as String? ?? '',
        value: json['value'] as String? ?? '',
        location: _apiKeyLocationFromName(json['location'] as String?),
      );

  BearerTokenAuthDraft _bearerTokenAuthDraftFromJson(
    Map<String, dynamic> json,
  ) =>
      BearerTokenAuthDraft(
        token: json['token'] as String? ?? '',
        prefix: json['prefix'] as String? ?? 'Bearer',
      );

  AuthType _authTypeFromName(String? value) =>
      _enumValueOrFallback(AuthType.values, value, AuthType.none);

  ApiKeyLocation _apiKeyLocationFromName(String? value) =>
      _enumValueOrFallback(ApiKeyLocation.values, value, ApiKeyLocation.header);

  List<T> _listFromJson<T>(
    Object? value,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _mapFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  T _enumValueOrFallback<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null || name.trim().isEmpty) {
      return fallback;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return fallback;
  }
}
