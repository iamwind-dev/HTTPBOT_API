// TEMPORARY: credentials (including API key values) are persisted in plaintext
// via SharedPreferences, mirroring how request drafts are stored. This is NOT
// production-safe — secrets should move to secure storage (Keychain/Keystore)
// in a later iteration.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/saved_credential.dart';
import '../../domain/repositories/saved_credentials_repository.dart';

class SavedCredentialsRepositoryImpl implements SavedCredentialsRepository {
  static const _storageKey = 'request_builder_saved_credentials';

  List<SavedCredential>? _cache;

  @override
  Future<List<SavedCredential>> getSavedCredentials() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <SavedCredential>[];
    }

    try {
      final decoded = jsonDecode(raw);
      final restored = _listFromJson(decoded);
      _cache = restored;
      return restored;
    } catch (_) {
      return const <SavedCredential>[];
    }
  }

  @override
  Future<void> saveSavedCredentials(List<SavedCredential> credentials) async {
    _cache = List<SavedCredential>.unmodifiable(credentials);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(credentials.map(_toJson).toList(growable: false)),
    );
  }

  Map<String, Object?> _toJson(SavedCredential credential) => {
    'id': credential.id,
    'name': credential.name,
    'type': credential.type.name,
    'apiKey': {
      'name': credential.apiKey.name,
      'value': credential.apiKey.value,
      'location': credential.apiKey.location.name,
    },
  };

  SavedCredential _fromJson(Map<String, dynamic> json) {
    final apiKeyJson = json['apiKey'];
    final apiKeyMap = apiKeyJson is Map
        ? Map<String, dynamic>.from(apiKeyJson)
        : const <String, dynamic>{};

    return SavedCredential(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _authTypeFromName(json['type'] as String?),
      apiKey: ApiKeyAuthDraft(
        name: apiKeyMap['name'] as String? ?? '',
        value: apiKeyMap['value'] as String? ?? '',
        location: _apiKeyLocationFromName(apiKeyMap['location'] as String?),
      ),
    );
  }

  List<SavedCredential> _listFromJson(Object? value) {
    if (value is! List) {
      return const <SavedCredential>[];
    }

    return value
        .whereType<Map>()
        .map((item) => _fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  AuthType _authTypeFromName(String? name) => AuthType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => AuthType.apiKey,
  );

  ApiKeyLocation _apiKeyLocationFromName(String? name) =>
      ApiKeyLocation.values.firstWhere(
        (location) => location.name == name,
        orElse: () => ApiKeyLocation.header,
      );
}
