import '../../domain/entities/postman_account_entity.dart';
import '../../domain/repositories/postman_session_repository.dart';
import '../datasources/postman_local_datasource.dart';

class PostmanSessionRepositoryImpl implements PostmanSessionRepository {
  final PostmanLocalDataSource localDataSource;

  PostmanSessionRepositoryImpl(this.localDataSource);

  @override
  Future<String?> loadApiKey() {
    return localDataSource.loadApiKey();
  }

  @override
  Future<void> saveApiKey(String apiKey) {
    return localDataSource.saveApiKey(apiKey);
  }

  @override
  Future<PostmanAccountEntity?> loadAccount() {
    return localDataSource.loadAccount();
  }

  @override
  Future<void> saveAccount(PostmanAccountEntity account) {
    return localDataSource.saveAccount(account);
  }

  @override
  Future<void> clearApiKey() {
    return localDataSource.clearApiKey();
  }

  @override
  Future<void> clearAccount() {
    return localDataSource.clearAccount();
  }
}
