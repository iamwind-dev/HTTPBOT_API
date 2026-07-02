import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/clear_postman_account_usecase.dart';
import '../../domain/usecases/clear_postman_api_key_usecase.dart';
import '../../domain/usecases/clear_cached_postman_collections_usecase.dart';
import '../../domain/usecases/clear_cached_postman_workspaces_usecase.dart';
import '../../domain/usecases/load_postman_account_usecase.dart';
import '../../domain/usecases/load_postman_api_key_usecase.dart';
import 'postman_account_state.dart';

class PostmanAccountCubit extends Cubit<PostmanAccountState> {
  final LoadPostmanApiKeyUseCase loadPostmanApiKeyUseCase;
  final LoadPostmanAccountUseCase loadPostmanAccountUseCase;
  final ClearPostmanApiKeyUseCase clearPostmanApiKeyUseCase;
  final ClearPostmanAccountUseCase clearPostmanAccountUseCase;
  final ClearCachedPostmanWorkspacesUseCase
      clearCachedPostmanWorkspacesUseCase;
  final ClearCachedPostmanCollectionsUseCase
      clearCachedPostmanCollectionsUseCase;

  PostmanAccountCubit({
    required this.loadPostmanApiKeyUseCase,
    required this.loadPostmanAccountUseCase,
    required this.clearPostmanApiKeyUseCase,
    required this.clearPostmanAccountUseCase,
    required this.clearCachedPostmanWorkspacesUseCase,
    required this.clearCachedPostmanCollectionsUseCase,
  }) : super(const PostmanAccountState());

  Future<void> load() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    final apiKey = await loadPostmanApiKeyUseCase();
    if (apiKey == null || apiKey.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          apiKey: '',
          clearAccount: true,
        ),
      );
      return;
    }

    final account = await loadPostmanAccountUseCase();
    emit(
      state.copyWith(
        isLoading: false,
        apiKey: apiKey,
        account: account,
      ),
    );
  }

  Future<void> unlink() async {
    emit(
      state.copyWith(
        isUnlinking: true,
        clearErrorMessage: true,
      ),
    );

    await clearPostmanAccountUseCase();
    await clearPostmanApiKeyUseCase();
    await clearCachedPostmanWorkspacesUseCase();

    emit(
      const PostmanAccountState(),
    );
  }
}
