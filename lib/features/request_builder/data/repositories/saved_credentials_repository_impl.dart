// TEMPORARY: credentials (including API key values) are persisted in plaintext
// via SharedPreferences, mirroring how request drafts are stored. This is NOT
// production-safe — secrets should move to secure storage (Keychain/Keystore)
// in a later iteration.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/saved_credential.dart';
import '../../domain/repositories/saved_credentials_repository.dart';
import '../mappers/request_auth_draft_codec.dart';

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
    'auth': requestAuthDraftToJson(credential.auth),
    'createdAt': credential.createdAt.toIso8601String(),
    'updatedAt': credential.updatedAt.toIso8601String(),
  };

  SavedCredential _fromJson(Map<String, dynamic> json) {
    return SavedCredential(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      auth: requestAuthDraftFromJson(mapFromJson(json['auth'])),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
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
}
