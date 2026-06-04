import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/postman_account_entity.dart';
import '../../domain/repositories/postman_session_repository.dart';

class PostmanSessionRepositoryImpl implements PostmanSessionRepository {
  static const _postmanApiKeyKey = 'postman_api_key';
  static const _postmanAccountKey = 'postman_account';

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
    final rawValue = jsonEncode({
      'id': account.id,
      'username': account.username,
      'email': account.email,
      'fullName': account.fullName,
      'avatarUrl': account.avatarUrl,
    });
    await preferences.setString(_postmanAccountKey, rawValue);
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
}
