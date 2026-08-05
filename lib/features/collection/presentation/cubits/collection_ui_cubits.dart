import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/presentation/widgets/variable_rows_editor.dart';
import '../../domain/entities/imported_collection_entity.dart';
import '../../domain/entities/openapi_directory_entry.dart';

class CollectionTreeState {
  const CollectionTreeState({
    this.query = '',
    this.expandedFolders = const <String>{},
  });

  final String query;
  final Set<String> expandedFolders;
}

class CollectionTreeCubit extends Cubit<CollectionTreeState> {
  CollectionTreeCubit({Iterable<String> initiallyExpanded = const []})
    : super(
        CollectionTreeState(
          expandedFolders: Set.unmodifiable(initiallyExpanded),
        ),
      );

  void updateQuery(String query) => emit(
    CollectionTreeState(query: query, expandedFolders: state.expandedFolders),
  );

  void toggleFolder(String key) {
    final folders = Set<String>.from(state.expandedFolders);
    folders.contains(key) ? folders.remove(key) : folders.add(key);
    emit(
      CollectionTreeState(
        query: state.query,
        expandedFolders: Set.unmodifiable(folders),
      ),
    );
  }

  void expandFolder(String key) {
    if (state.expandedFolders.contains(key)) return;
    emit(
      CollectionTreeState(
        query: state.query,
        expandedFolders: Set.unmodifiable({...state.expandedFolders, key}),
      ),
    );
  }

  void reset({Iterable<String> expandedFolders = const []}) => emit(
    CollectionTreeState(expandedFolders: Set.unmodifiable(expandedFolders)),
  );
}

class CollectionVariablesCubit
    extends Cubit<List<ImportedCollectionVariableEntity>> {
  CollectionVariablesCubit(List<ImportedCollectionVariableEntity> variables)
    : super(List.unmodifiable(variables));

  void updateAt(int index, ImportedCollectionVariableEntity variable) {
    final variables = List<ImportedCollectionVariableEntity>.from(state);
    variables[index] = variable;
    emit(List.unmodifiable(variables));
  }

  void addEmpty() => emit(
    List.unmodifiable([
      ...state,
      const ImportedCollectionVariableEntity(name: '', value: ''),
    ]),
  );
}

class CollectionEditorFormState {
  const CollectionEditorFormState({
    required this.auth,
    required this.variableRows,
    this.isCompleting = false,
  });

  final RequestAuthDraft auth;
  final List<VariableRowData> variableRows;
  final bool isCompleting;
}

class CollectionEditorFormCubit extends Cubit<CollectionEditorFormState> {
  CollectionEditorFormCubit({
    required RequestAuthDraft auth,
    required List<VariableRowData> variableRows,
  }) : super(
         CollectionEditorFormState(
           auth: auth,
           variableRows: List.unmodifiable(variableRows),
         ),
       );

  void updateAuth(RequestAuthDraft auth) => emit(
    CollectionEditorFormState(
      auth: auth,
      variableRows: state.variableRows,
      isCompleting: state.isCompleting,
    ),
  );

  void addVariableRow() => emit(
    CollectionEditorFormState(
      auth: state.auth,
      variableRows: List.unmodifiable([
        ...state.variableRows,
        VariableRowData(),
      ]),
      isCompleting: state.isCompleting,
    ),
  );

  void removeVariableRow(int index) {
    final rows = List<VariableRowData>.from(state.variableRows);
    rows.removeAt(index).dispose();
    emit(
      CollectionEditorFormState(
        auth: state.auth,
        variableRows: List.unmodifiable(rows),
        isCompleting: state.isCompleting,
      ),
    );
  }

  void variableChanged() => emit(
    CollectionEditorFormState(
      auth: state.auth,
      variableRows: List.unmodifiable(state.variableRows),
      isCompleting: state.isCompleting,
    ),
  );

  void markCompleting() => emit(
    CollectionEditorFormState(
      auth: state.auth,
      variableRows: state.variableRows,
      isCompleting: true,
    ),
  );

  @override
  Future<void> close() {
    for (final row in state.variableRows) {
      row.dispose();
    }
    return super.close();
  }
}

class OpenApiDirectoryState {
  const OpenApiDirectoryState({
    this.query = '',
    this.selectedEntry,
    this.selectedVersionName,
  });

  final String query;
  final OpenApiDirectoryEntry? selectedEntry;
  final String? selectedVersionName;
}

class OpenApiDirectoryCubit extends Cubit<OpenApiDirectoryState> {
  OpenApiDirectoryCubit() : super(const OpenApiDirectoryState());

  void updateQuery(String query) => emit(
    OpenApiDirectoryState(
      query: query,
      selectedEntry: state.selectedEntry,
      selectedVersionName: state.selectedVersionName,
    ),
  );

  void selectEntry(OpenApiDirectoryEntry entry) => emit(
    OpenApiDirectoryState(
      query: state.query,
      selectedEntry: entry,
      selectedVersionName: entry.preferredVersionName,
    ),
  );

  void selectVersion(String versionName) => emit(
    OpenApiDirectoryState(
      query: state.query,
      selectedEntry: state.selectedEntry,
      selectedVersionName: versionName,
    ),
  );

  void clearEntry() => emit(OpenApiDirectoryState(query: state.query));
}

class ExpansionCubit extends Cubit<bool> {
  ExpansionCubit() : super(false);

  void toggle() => emit(!state);
}
