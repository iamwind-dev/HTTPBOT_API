import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/postman_variable_entity.dart';

class PostmanTreeState {
  const PostmanTreeState({
    this.query = '',
    this.expandedFolders = const <String>{},
  });

  final String query;
  final Set<String> expandedFolders;
}

class PostmanTreeCubit extends Cubit<PostmanTreeState> {
  PostmanTreeCubit() : super(const PostmanTreeState());

  void updateQuery(String query) => emit(
    PostmanTreeState(query: query, expandedFolders: state.expandedFolders),
  );

  void toggleFolder(String key) {
    final folders = Set<String>.from(state.expandedFolders);
    folders.contains(key) ? folders.remove(key) : folders.add(key);
    emit(
      PostmanTreeState(
        query: state.query,
        expandedFolders: Set.unmodifiable(folders),
      ),
    );
  }

  void expandFolder(String key) {
    if (state.expandedFolders.contains(key)) return;
    emit(
      PostmanTreeState(
        query: state.query,
        expandedFolders: Set.unmodifiable({...state.expandedFolders, key}),
      ),
    );
  }

  void reset() => emit(const PostmanTreeState());
}

class PostmanVariablesCubit extends Cubit<List<PostmanVariableEntity>> {
  PostmanVariablesCubit(List<PostmanVariableEntity> variables)
    : super(List.unmodifiable(variables));

  void updateAt(int index, PostmanVariableEntity variable) {
    final variables = List<PostmanVariableEntity>.from(state);
    variables[index] = variable;
    emit(List.unmodifiable(variables));
  }

  void addEmpty() => emit(
    List.unmodifiable([
      ...state,
      const PostmanVariableEntity(key: '', value: ''),
    ]),
  );
}

class ExpansionCubit extends Cubit<bool> {
  ExpansionCubit() : super(false);

  void toggle() => emit(!state);
}
