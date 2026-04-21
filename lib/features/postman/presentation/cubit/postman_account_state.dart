import '../../domain/entities/postman_account_entity.dart';

class PostmanAccountState {
  final bool isLoading;
  final bool isUnlinking;
  final String apiKey;
  final String? errorMessage;
  final PostmanAccountEntity? account;

  const PostmanAccountState({
    this.isLoading = false,
    this.isUnlinking = false,
    this.apiKey = '',
    this.errorMessage,
    this.account,
  });

  bool get isLinked => apiKey.isNotEmpty;

  PostmanAccountState copyWith({
    bool? isLoading,
    bool? isUnlinking,
    String? apiKey,
    String? errorMessage,
    PostmanAccountEntity? account,
    bool clearErrorMessage = false,
    bool clearAccount = false,
  }) {
    return PostmanAccountState(
      isLoading: isLoading ?? this.isLoading,
      isUnlinking: isUnlinking ?? this.isUnlinking,
      apiKey: apiKey ?? this.apiKey,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      account: clearAccount ? null : (account ?? this.account),
    );
  }
}
