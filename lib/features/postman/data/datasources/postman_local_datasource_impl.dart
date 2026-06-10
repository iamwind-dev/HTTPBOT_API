import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/postman_account_entity.dart';
import '../../domain/entities/postman_auth_entity.dart';
import '../../domain/entities/postman_body_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_folder_entity.dart';
import '../../domain/entities/postman_key_value_entity.dart';
import '../../domain/entities/postman_request_entity.dart';
import '../../domain/entities/postman_url_entity.dart';
import '../../domain/entities/postman_variable_entity.dart';
import '../../domain/entities/postman_workspace_entity.dart';
import 'postman_local_datasource.dart';

class PostmanLocalDataSourceImpl implements PostmanLocalDataSource {
  static const _postmanApiKeyKey = 'postman_api_key';
  static const _postmanAccountKey = 'postman_account';
  static const _postmanWorkspacesKey = 'postman_workspaces';
  static const _postmanCollectionsKey = 'postman_collections';

  @override
  Future<String?> loadApiKey() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_postmanApiKeyKey);
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_postmanApiKeyKey, apiKey);
  }

  @override
  Future<PostmanAccountEntity?> loadAccount() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_postmanAccountKey);

    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final json = jsonDecode(rawValue);
    if (json is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(json);
    return PostmanAccountEntity(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString() ?? '',
    );
  }

  @override
  Future<void> saveAccount(PostmanAccountEntity account) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _postmanAccountKey,
      jsonEncode({
        'id': account.id,
        'username': account.username,
        'email': account.email,
        'fullName': account.fullName,
        'avatarUrl': account.avatarUrl,
      }),
    );
  }

  @override
  Future<List<PostmanWorkspaceEntity>> loadWorkspaces() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_postmanWorkspacesKey),
      _workspaceFromJson,
    );
  }

  @override
  Future<void> saveWorkspaces(List<PostmanWorkspaceEntity> workspaces) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _postmanWorkspacesKey,
      jsonEncode(workspaces.map(_workspaceToJson).toList()),
    );
  }

  @override
  Future<List<PostmanCollectionEntity>> loadCollections() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeList(
      preferences.getString(_postmanCollectionsKey),
      _collectionFromJson,
    );
  }

  @override
  Future<void> saveCollections(List<PostmanCollectionEntity> collections) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _postmanCollectionsKey,
      jsonEncode(collections.map(_collectionToJson).toList()),
    );
  }

  @override
  Future<void> clearApiKey() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_postmanApiKeyKey);
  }

  @override
  Future<void> clearAccount() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_postmanAccountKey);
  }

  @override
  Future<void> clearWorkspaces() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_postmanWorkspacesKey);
  }

  @override
  Future<void> clearCollections() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_postmanCollectionsKey);
  }

  List<T> _decodeList<T>(
    String? rawValue,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _workspaceToJson(PostmanWorkspaceEntity workspace) {
    return {
      'id': workspace.id,
      'name': workspace.name,
      'type': workspace.type,
      'description': workspace.description,
      'variables': workspace.variables.map(_variableToJson).toList(),
      'collections': workspace.collections.map(_collectionToJson).toList(),
    };
  }

  PostmanWorkspaceEntity _workspaceFromJson(Map<String, dynamic> json) {
    return PostmanWorkspaceEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      variables: _decodeVariables(json['variables']),
      collections: _decodeCollections(json['collections']),
    );
  }

  Map<String, dynamic> _collectionToJson(PostmanCollectionEntity collection) {
    return {
      'id': collection.id,
      'name': collection.name,
      'description': collection.description,
      'auth': _authToJson(collection.auth),
      'variables': collection.variables.map(_variableToJson).toList(),
      'folders': collection.folders.map(_folderToJson).toList(),
      'requests': collection.requests.map(_requestToJson).toList(),
    };
  }

  PostmanCollectionEntity _collectionFromJson(Map<String, dynamic> json) {
    return PostmanCollectionEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      auth: _authFromJson(json['auth']),
      variables: _decodeVariables(json['variables']),
      folders: _decodeFolders(json['folders']),
      requests: _decodeRequests(json['requests']),
    );
  }

  Map<String, dynamic> _folderToJson(PostmanFolderEntity folder) {
    return {
      'id': folder.id,
      'name': folder.name,
      'requests': folder.requests.map(_requestToJson).toList(),
      'folders': folder.folders.map(_folderToJson).toList(),
    };
  }

  PostmanFolderEntity _folderFromJson(Map<String, dynamic> json) {
    return PostmanFolderEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      requests: _decodeRequests(json['requests']),
      folders: _decodeFolders(json['folders']),
    );
  }

  Map<String, dynamic> _requestToJson(PostmanRequestEntity request) {
    return {
      'id': request.id,
      'name': request.name,
      'description': request.description,
      'method': request.method,
      'url': _urlToJson(request.url),
      'queryParameters': request.queryParameters.map(_keyValueToJson).toList(),
      'headers': request.headers.map(_keyValueToJson).toList(),
      'body': _bodyToJson(request.body),
      'auth': _authToJson(request.auth),
    };
  }

  PostmanRequestEntity _requestFromJson(Map<String, dynamic> json) {
    return PostmanRequestEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      method: json['method']?.toString() ?? 'GET',
      url: _urlFromJson(json['url']),
      queryParameters: _decodeKeyValues(json['queryParameters']),
      headers: _decodeKeyValues(json['headers']),
      body: _bodyFromJson(json['body']),
      auth: _authFromJson(json['auth']),
    );
  }

  Map<String, dynamic> _urlToJson(PostmanUrlEntity url) {
    return {
      'raw': url.raw,
      'protocol': url.protocol,
      'host': url.host,
      'path': url.path,
      'queryParameters': url.queryParameters.map(_keyValueToJson).toList(),
    };
  }

  PostmanUrlEntity _urlFromJson(Object? input) {
    if (input is! Map) {
      return const PostmanUrlEntity(raw: '');
    }

    final json = Map<String, dynamic>.from(input);
    return PostmanUrlEntity(
      raw: json['raw']?.toString() ?? '',
      protocol: json['protocol']?.toString() ?? '',
      host: (json['host'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      path: (json['path'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      queryParameters: _decodeKeyValues(json['queryParameters']),
    );
  }

  Map<String, dynamic> _bodyToJson(PostmanBodyEntity body) {
    return {
      'type': body.type.name,
      'raw': body.raw,
      'rawSubtype': body.rawSubtype.name,
      'formData': body.formData.map(_keyValueToJson).toList(),
      'urlEncoded': body.urlEncoded.map(_keyValueToJson).toList(),
      'graphQlQuery': body.graphQlQuery,
      'graphQlVariables': body.graphQlVariables,
      'filePath': body.filePath,
    };
  }

  PostmanBodyEntity _bodyFromJson(Object? input) {
    if (input is! Map) {
      return const PostmanBodyEntity();
    }

    final json = Map<String, dynamic>.from(input);
    return PostmanBodyEntity(
      type: PostmanBodyType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PostmanBodyType.none,
      ),
      raw: json['raw']?.toString() ?? '',
      rawSubtype: PostmanRawBodySubtype.values.firstWhere(
        (value) => value.name == json['rawSubtype'],
        orElse: () => PostmanRawBodySubtype.text,
      ),
      formData: _decodeKeyValues(json['formData']),
      urlEncoded: _decodeKeyValues(json['urlEncoded']),
      graphQlQuery: json['graphQlQuery']?.toString() ?? '',
      graphQlVariables: json['graphQlVariables']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _authToJson(PostmanAuthEntity auth) {
    return {
      'type': auth.type.name,
      'basic': {
        'username': auth.basic.username,
        'password': auth.basic.password,
      },
      'apiKey': {
        'key': auth.apiKey.key,
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
        'opaque': auth.digest.opaque,
      },
      'hawk': {
        'identifier': auth.hawk.identifier,
        'key': auth.hawk.key,
        'algorithm': auth.hawk.algorithm,
        'app': auth.hawk.app,
        'delegation': auth.hawk.delegation,
      },
      'jwt': {
        'token': auth.jwt.token,
        'header': auth.jwt.header,
        'payload': auth.jwt.payload,
        'secret': auth.jwt.secret,
        'algorithm': auth.jwt.algorithm,
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
        'nonce': auth.oauth1.nonce,
        'timestamp': auth.oauth1.timestamp,
        'version': auth.oauth1.version,
      },
      'oauth2': {
        'accessToken': auth.oauth2.accessToken,
        'refreshToken': auth.oauth2.refreshToken,
        'clientId': auth.oauth2.clientId,
        'clientSecret': auth.oauth2.clientSecret,
        'tokenUrl': auth.oauth2.tokenUrl,
        'scopes': auth.oauth2.scopes,
      },
    };
  }

  PostmanAuthEntity _authFromJson(Object? input) {
    if (input is! Map) {
      return const PostmanAuthEntity();
    }

    final json = Map<String, dynamic>.from(input);
    final basic = _map(json['basic']);
    final apiKey = _map(json['apiKey']);
    final bearerToken = _map(json['bearerToken']);
    final digest = _map(json['digest']);
    final hawk = _map(json['hawk']);
    final jwt = _map(json['jwt']);
    final ntlm = _map(json['ntlm']);
    final aws = _map(json['aws']);
    final oauth1 = _map(json['oauth1']);
    final oauth2 = _map(json['oauth2']);

    return PostmanAuthEntity(
      type: PostmanAuthType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PostmanAuthType.none,
      ),
      basic: PostmanBasicAuthEntity(
        username: basic['username']?.toString() ?? '',
        password: basic['password']?.toString() ?? '',
      ),
      apiKey: PostmanApiKeyAuthEntity(
        key: apiKey['key']?.toString() ?? '',
        value: apiKey['value']?.toString() ?? '',
        location: PostmanApiKeyLocation.values.firstWhere(
          (value) => value.name == apiKey['location'],
          orElse: () => PostmanApiKeyLocation.header,
        ),
      ),
      bearerToken: PostmanBearerAuthEntity(
        token: bearerToken['token']?.toString() ?? '',
        prefix: bearerToken['prefix']?.toString() ?? 'Bearer',
      ),
      digest: PostmanDigestAuthEntity(
        username: digest['username']?.toString() ?? '',
        password: digest['password']?.toString() ?? '',
        realm: digest['realm']?.toString() ?? '',
        nonce: digest['nonce']?.toString() ?? '',
        algorithm: digest['algorithm']?.toString() ?? '',
        qop: digest['qop']?.toString() ?? '',
        opaque: digest['opaque']?.toString() ?? '',
      ),
      hawk: PostmanHawkAuthEntity(
        identifier: hawk['identifier']?.toString() ?? '',
        key: hawk['key']?.toString() ?? '',
        algorithm: hawk['algorithm']?.toString() ?? '',
        app: hawk['app']?.toString() ?? '',
        delegation: hawk['delegation']?.toString() ?? '',
      ),
      jwt: PostmanJwtAuthEntity(
        token: jwt['token']?.toString() ?? '',
        header: jwt['header']?.toString() ?? '',
        payload: jwt['payload']?.toString() ?? '',
        secret: jwt['secret']?.toString() ?? '',
        algorithm: jwt['algorithm']?.toString() ?? '',
        prefix: jwt['prefix']?.toString() ?? 'Bearer',
      ),
      ntlm: PostmanNtlmAuthEntity(
        username: ntlm['username']?.toString() ?? '',
        password: ntlm['password']?.toString() ?? '',
        domain: ntlm['domain']?.toString() ?? '',
        workstation: ntlm['workstation']?.toString() ?? '',
      ),
      aws: PostmanAwsAuthEntity(
        accessKey: aws['accessKey']?.toString() ?? '',
        secretKey: aws['secretKey']?.toString() ?? '',
        region: aws['region']?.toString() ?? '',
        service: aws['service']?.toString() ?? '',
        sessionToken: aws['sessionToken']?.toString() ?? '',
      ),
      oauth1: PostmanOAuth1AuthEntity(
        consumerKey: oauth1['consumerKey']?.toString() ?? '',
        consumerSecret: oauth1['consumerSecret']?.toString() ?? '',
        token: oauth1['token']?.toString() ?? '',
        tokenSecret: oauth1['tokenSecret']?.toString() ?? '',
        signatureMethod: oauth1['signatureMethod']?.toString() ?? '',
        nonce: oauth1['nonce']?.toString() ?? '',
        timestamp: oauth1['timestamp']?.toString() ?? '',
        version: oauth1['version']?.toString() ?? '',
      ),
      oauth2: PostmanOAuth2AuthEntity(
        accessToken: oauth2['accessToken']?.toString() ?? '',
        refreshToken: oauth2['refreshToken']?.toString() ?? '',
        clientId: oauth2['clientId']?.toString() ?? '',
        clientSecret: oauth2['clientSecret']?.toString() ?? '',
        tokenUrl: oauth2['tokenUrl']?.toString() ?? '',
        scopes: (oauth2['scopes'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
      ),
    );
  }

  Map<String, dynamic> _keyValueToJson(PostmanKeyValueEntity item) {
    return {
      'key': item.key,
      'value': item.value,
      'isEnabled': item.isEnabled,
      'type': item.type.name,
      'contentType': item.contentType,
      'description': item.description,
    };
  }

  PostmanKeyValueEntity _keyValueFromJson(Map<String, dynamic> json) {
    return PostmanKeyValueEntity(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      isEnabled: json['isEnabled'] != false,
      type: PostmanKeyValueType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PostmanKeyValueType.text,
      ),
      contentType: json['contentType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _variableToJson(PostmanVariableEntity variable) {
    return {
      'key': variable.key,
      'value': variable.value,
      'type': variable.type,
      'isEnabled': variable.isEnabled,
    };
  }

  PostmanVariableEntity _variableFromJson(Map<String, dynamic> json) {
    return PostmanVariableEntity(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isEnabled: json['isEnabled'] != false,
    );
  }

  List<PostmanCollectionEntity> _decodeCollections(Object? input) {
    return (input as List? ?? const [])
        .whereType<Map>()
        .map((item) => _collectionFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<PostmanFolderEntity> _decodeFolders(Object? input) {
    return (input as List? ?? const [])
        .whereType<Map>()
        .map((item) => _folderFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<PostmanRequestEntity> _decodeRequests(Object? input) {
    return (input as List? ?? const [])
        .whereType<Map>()
        .map((item) => _requestFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<PostmanVariableEntity> _decodeVariables(Object? input) {
    return (input as List? ?? const [])
        .whereType<Map>()
        .map((item) => _variableFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<PostmanKeyValueEntity> _decodeKeyValues(Object? input) {
    return (input as List? ?? const [])
        .whereType<Map>()
        .map((item) => _keyValueFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _map(Object? input) {
    if (input is Map) {
      return Map<String, dynamic>.from(input);
    }

    return <String, dynamic>{};
  }
}
