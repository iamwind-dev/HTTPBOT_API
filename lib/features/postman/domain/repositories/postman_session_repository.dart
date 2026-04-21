import '../entities/postman_account_entity.dart';

abstract class PostmanSessionRepository {
  Future<String?> loadApiKey();

  Future<void> saveApiKey(String apiKey);

  Future<PostmanAccountEntity?> loadAccount();

  Future<void> saveAccount(PostmanAccountEntity account);

  Future<void> clearApiKey();

  Future<void> clearAccount();
}
