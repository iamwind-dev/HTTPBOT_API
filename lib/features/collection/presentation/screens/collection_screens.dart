import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:httpbot_api/core/widgets/body_empty.dart';
import 'package:httpbot_api/features/collection/presentation/model/list_collections.dart';
import 'package:httpbot_api/features/collection/presentation/widget/collections_list_item.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_body_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_key_value.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_variable.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_variable_store.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/requests_method.dart';
import 'package:httpbot_api/features/request_builder/domain/helpers/curl_command_builder.dart';
import 'package:httpbot_api/features/request_builder/domain/helpers/simple_curl_request_parser.dart';
import 'package:httpbot_api/features/request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import 'package:httpbot_api/features/request_builder/presentation/models/request_editor_result.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/view_curl_sheet.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/request_editor_sheet.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/imported_collection_entity.dart';
import '../cubits/collection_cubit.dart';
import '../cubits/collection_state.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionCubit, CollectionState>(
      builder: (context, state) {
        final collections = state.items
            .map(
              (item) => CollectionItemModel(
                id: item.id,
                folderName: item.name,
                itemCount: item.itemCount,
              ),
            )
            .toList(growable: false);

        final selectedCollection = state.selectedCollection;

        return Scaffold(
          body: selectedCollection != null
              ? _CollectionDetailView(collection: selectedCollection)
              : collections.isEmpty
              ? const BodyEmpty(
                  title: 'No Collections',
                  subtitle: "Tap '+' to create or import a new collection",
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: collections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = collections[index];
                    final collection = state.items[index];
                    return CollectionsListItem(
                      item: item,
                      onTap: () => context
                          .read<CollectionCubit>()
                          .selectCollection(item.id),
                      onMoreTap: () =>
                          _showCollectionActions(context, collection),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _showCollectionActions(
    BuildContext context,
    ImportedCollectionEntity collection,
  ) async {
    final action = await showModalBottomSheet<_CollectionListAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectionActionsSheet(collection: collection),
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _CollectionListAction.edit:
        await _editCollection(context, collection);
        break;
      case _CollectionListAction.export:
        await _exportCollection(collection);
        break;
      case _CollectionListAction.delete:
        await _deleteCollection(context, collection);
        break;
    }
  }

  Future<void> _editCollection(
    BuildContext context,
    ImportedCollectionEntity collection,
  ) async {
    final updated = await Navigator.of(context).push<ImportedCollectionEntity>(
      MaterialPageRoute<ImportedCollectionEntity>(
        fullscreenDialog: true,
        builder: (_) => _CollectionEditorPage(collection: collection),
      ),
    );

    if (!context.mounted || updated == null) {
      return;
    }

    context.read<CollectionCubit>().updateCollection(updated);
  }

  Future<void> _deleteCollection(
    BuildContext context,
    ImportedCollectionEntity collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DeleteCollectionDialog(collectionName: collection.name),
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    context.read<CollectionCubit>().deleteCollection(collection.id);
  }

  Future<void> _exportCollection(ImportedCollectionEntity collection) {
    final payload = _collectionToExportPayload(collection);
    return SharePlus.instance.share(
      ShareParams(
        subject: collection.name,
        text: const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );
  }

  Map<String, Object?> _collectionToExportPayload(
    ImportedCollectionEntity collection,
  ) {
    return <String, Object?>{
      'name': collection.name,
      'description': collection.description,
      'auth': collection.authLabel,
      'variables': collection.variables
          .map(
            (variable) => <String, Object?>{
              'name': variable.name,
              'value': variable.value,
              'enabled': variable.isEnabled,
            },
          )
          .toList(growable: false),
      'folders': collection.folders.map(_folderToJson).toList(growable: false),
      'requests': collection.rootRequests
          .map(_requestToJson)
          .toList(growable: false),
    };
  }

  Map<String, Object?> _folderToJson(ImportedCollectionFolderEntity folder) {
    return <String, Object?>{
      'name': folder.name,
      'folders': folder.folders.map(_folderToJson).toList(growable: false),
      'requests': folder.requests.map(_requestToJson).toList(growable: false),
    };
  }

  Map<String, Object?> _requestToJson(ImportedCollectionRequestEntity request) {
    return <String, Object?>{
      'method': request.method,
      'title': request.title,
      'url': request.url,
      'baseUrlValue': request.baseUrlValue,
      'queryParameters': request.queryParameters
          .map(
            (item) => <String, Object?>{
              'name': item.name,
              'value': item.value,
              'description': item.description,
            },
          )
          .toList(growable: false),
      'headers': request.headers
          .map(
            (item) => <String, Object?>{
              'name': item.name,
              'value': item.value,
              'description': item.description,
            },
          )
          .toList(growable: false),
      'bodyContentType': request.bodyContentType,
      'bodyContent': request.bodyContent,
    };
  }
}

class _CollectionDetailView extends StatefulWidget {
  const _CollectionDetailView({required this.collection});

  final ImportedCollectionEntity collection;

  @override
  State<_CollectionDetailView> createState() => _CollectionDetailViewState();
}

class _CollectionDetailViewState extends State<_CollectionDetailView> {
  final Set<String> _expandedFolders = <String>{};
  late final TextEditingController _searchController;
  static const _curlParser = SimpleCurlRequestParser();

  String get _searchQuery => _searchController.text;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _seedExpandedFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CollectionDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection.id != widget.collection.id) {
      _expandedFolders
        ..clear()
        ..addAll(_allFolderKeys(widget.collection.folders));
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visibleFolders = _filterFolders(
      widget.collection.folders,
      _searchQuery.trim(),
    );
    final visibleRootRequests = widget.collection.rootRequests
        .where((request) => _requestMatchesQuery(request, _searchQuery))
        .toList(growable: false);

    final hasVisibleItems =
        visibleFolders.isNotEmpty || visibleRootRequests.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _CollectionSearchBar(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Divider(color: colors.divider, thickness: 1),
        const SizedBox(height: 10),
        if (!hasVisibleItems)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Text(
              'No matching items',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        for (final request in visibleRootRequests)
          _RequestRow(
            request: request,
            depth: 0,
            onTap: () => _openRequestEditor(request),
            onLongPress: () => _showRequestActions(request: request),
          ),
        for (final folder in visibleFolders)
          _CollectionFolderNode(
            folder: folder,
            depth: 0,
            expandedKeys: _expandedFolders,
            onToggle: (folderKey) => setState(() {
              if (_expandedFolders.contains(folderKey)) {
                _expandedFolders.remove(folderKey);
              } else {
                _expandedFolders.add(folderKey);
              }
            }),
            onLongPress: _showFolderActions,
            onRequestTap: _openRequestEditor,
            onRequestLongPress: ({
              required request,
              required folderKey,
            }) => _showRequestActions(
              request: request,
              folderKey: folderKey,
            ),
          ),
      ],
    );
  }

  Future<void> _showFolderActions(_VisibleFolderNode folder) async {
    final action = await showModalBottomSheet<_FolderTreeAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FolderActionsSheet(),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _FolderTreeAction.rename:
        await _renameFolder(folder);
        break;
      case _FolderTreeAction.newRequest:
        await _createFolderRequest(folder);
        break;
      case _FolderTreeAction.newFolder:
        await _createChildFolder(folder);
        break;
      case _FolderTreeAction.importCurl:
        await _importCurlIntoFolder(folder);
        break;
      case _FolderTreeAction.delete:
        await _deleteFolder(folder);
        break;
    }
  }

  Future<void> _showRequestActions({
    required ImportedCollectionRequestEntity request,
    String? folderKey,
  }) async {
    final action = await showModalBottomSheet<_RequestTreeAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RequestActionsSheet(),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _RequestTreeAction.edit:
        await _editRequest(request: request, folderKey: folderKey);
        break;
      case _RequestTreeAction.duplicate:
        _duplicateRequest(request: request, folderKey: folderKey);
        break;
      case _RequestTreeAction.viewCurl:
        await _viewCurlRequest(request);
        break;
      case _RequestTreeAction.delete:
        await _deleteRequest(request: request, folderKey: folderKey);
        break;
    }
  }

  Future<void> _openRequestEditor(
    ImportedCollectionRequestEntity request,
  ) async {
    final variableStore = await getIt<GetRequestVariableStoreUseCase>()();
    if (!mounted) {
      return;
    }

    await showRequestEditorSheet(
      context,
      title: request.title,
      initialDraft: _draftFromImportedRequest(request),
      variableStore: _mergeImportedVariables(
        existingStore: variableStore,
        collection: widget.collection,
      ),
    );
  }

  RequestDraft _draftFromImportedRequest(
    ImportedCollectionRequestEntity request,
  ) {
    final headers = request.headers
        .map(
          (field) => KeyValueItem(
            key: field.name,
            value: field.value,
            description: field.description,
          ),
        )
        .toList(growable: false);

    final queryParameters = request.queryParameters
        .map(
          (field) => KeyValueItem(
            key: field.name,
            value: field.value,
            description: field.description,
          ),
        )
        .toList(growable: false);

    final body = _bodyFromImportedRequest(request);

    return RequestDraft(
      method: _mapMethod(request.method),
      url: request.url,
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      variables: widget.collection.variables
          .where(
            (variable) => variable.isEnabled && variable.name.trim().isNotEmpty,
          )
          .map(
            (variable) => RequestVariable(
              key: variable.name,
              initialValue: variable.value,
              description: 'Imported from the selected collection',
            ),
          )
          .toList(growable: false),
    );
  }

  RequestBodyDraft _bodyFromImportedRequest(
    ImportedCollectionRequestEntity request,
  ) {
    if (request.bodyContent.trim().isEmpty) {
      return const RequestBodyDraft.none();
    }

    final contentType = request.bodyContentType.toLowerCase();
    if (contentType.contains('application/json') ||
        contentType.contains('+json')) {
      return RequestBodyDraft(
        type: RequestBodyType.raw,
        raw: RawBodyDraft(
          subtype: RawBodySubtype.json,
          content: request.bodyContent,
        ),
      );
    }

    if (contentType.contains('xml')) {
      return RequestBodyDraft(
        type: RequestBodyType.raw,
        raw: RawBodyDraft(
          subtype: RawBodySubtype.xml,
          content: request.bodyContent,
        ),
      );
    }

    if (contentType.contains('html')) {
      return RequestBodyDraft(
        type: RequestBodyType.raw,
        raw: RawBodyDraft(
          subtype: RawBodySubtype.html,
          content: request.bodyContent,
        ),
      );
    }

    return RequestBodyDraft(
      type: RequestBodyType.raw,
      raw: RawBodyDraft(
        subtype: RawBodySubtype.text,
        content: request.bodyContent,
      ),
    );
  }

  RequestVariableStore _mergeImportedVariables({
    required RequestVariableStore existingStore,
    required ImportedCollectionEntity collection,
  }) {
    if (collection.variables.isEmpty) {
      return existingStore;
    }

    final variables =
        existingStore.globalVariables
            .where(
              (variable) => !collection.variables.any(
                (collectionVariable) => collectionVariable.name == variable.key,
              ),
            )
            .toList(growable: true)
          ..insertAll(
            0,
            collection.variables
                .where(
                  (variable) =>
                      variable.isEnabled && variable.name.trim().isNotEmpty,
                )
                .map(
                  (variable) => RequestVariable(
                    key: variable.name,
                    initialValue: variable.value,
                    scope: RequestVariableScope.global,
                    description: 'Imported from the selected collection',
                  ),
                ),
          );

    return RequestVariableStore(
      globalVariables: List<RequestVariable>.unmodifiable(variables),
      environments: existingStore.environments,
      selectedEnvironmentId: existingStore.selectedEnvironmentId,
    );
  }

  HttpMethod _mapMethod(String method) {
    final normalized = method.trim().toUpperCase();
    for (final value in HttpMethod.values) {
      if (value.wireName == normalized || value.label == normalized) {
        return value;
      }
    }

    return HttpMethod.get;
  }

  void _seedExpandedFolders() {
    _expandedFolders
      ..clear()
      ..addAll(_allFolderKeys(widget.collection.folders));
  }

  Set<String> _allFolderKeys(
    List<ImportedCollectionFolderEntity> folders, [
    String parentKey = '',
  ]) {
    final keys = <String>{};
    for (final folder in folders) {
      final folderKey = _folderKey(parentKey, folder.name);
      keys.add(folderKey);
      keys.addAll(_allFolderKeys(folder.folders, folderKey));
    }
    return keys;
  }

  List<_VisibleFolderNode> _filterFolders(
    List<ImportedCollectionFolderEntity> folders,
    String query, [
    String parentKey = '',
  ]) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return folders
          .map(
            (folder) => _VisibleFolderNode(
              folder: folder,
              key: _folderKey(parentKey, folder.name),
              visibleChildren: _filterFolders(
                folder.folders,
                normalizedQuery,
                _folderKey(parentKey, folder.name),
              ),
              visibleRequests: folder.requests,
            ),
          )
          .toList(growable: false);
    }

    final visible = <_VisibleFolderNode>[];
    for (final folder in folders) {
      final folderKey = _folderKey(parentKey, folder.name);
      final childFolders = _filterFolders(
        folder.folders,
        normalizedQuery,
        folderKey,
      );
      final matchingRequests = folder.requests
          .where((request) => _requestMatchesQuery(request, normalizedQuery))
          .toList(growable: false);
      final folderMatches = folder.name.toLowerCase().contains(normalizedQuery);

      if (!folderMatches && childFolders.isEmpty && matchingRequests.isEmpty) {
        continue;
      }

      visible.add(
        _VisibleFolderNode(
          folder: folder,
          key: folderKey,
          visibleChildren: childFolders,
          visibleRequests: folderMatches ? folder.requests : matchingRequests,
        ),
      );
    }

    return visible;
  }

  bool _requestMatchesQuery(
    ImportedCollectionRequestEntity request,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return request.title.toLowerCase().contains(normalizedQuery) ||
        request.url.toLowerCase().contains(normalizedQuery) ||
        request.method.toLowerCase().contains(normalizedQuery);
  }

  String _folderKey(String parentKey, String folderName) {
    if (parentKey.isEmpty) {
      return folderName;
    }
    return '$parentKey/$folderName';
  }

  Future<void> _renameFolder(_VisibleFolderNode folder) async {
    final nextName = await _showNameEditorDialog(
      title: 'Rename Folder',
      actionLabel: 'Rename',
      initialValue: folder.folder.name,
    );
    if (!mounted || nextName == null || nextName == folder.folder.name) {
      return;
    }

    final updatedCollection = widget.collection.copyWith(
      folders: _updateFolderTree(
        widget.collection.folders,
        folder.key,
        (target) => target.copyWith(name: nextName),
      ),
    );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
  }

  Future<void> _createChildFolder(_VisibleFolderNode folder) async {
    final folderName = await _showNameEditorDialog(
      title: 'New Folder',
      actionLabel: 'Create',
      initialValue: '',
    );
    if (!mounted || folderName == null) {
      return;
    }

    final updatedCollection = widget.collection.copyWith(
      folders: _updateFolderTree(
        widget.collection.folders,
        folder.key,
        (target) => target.copyWith(
          folders: [
            ...target.folders,
            ImportedCollectionFolderEntity(name: folderName),
          ],
        ),
      ),
    );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
    setState(() => _expandedFolders.add(folder.key));
  }

  Future<void> _deleteFolder(_VisibleFolderNode folder) async {
    final confirmed = await _showDeleteFolderDialog(folder.folder.name);
    if (!mounted || confirmed != true) {
      return;
    }

    final updatedCollection = widget.collection.copyWith(
      folders: _deleteFolderFromTree(widget.collection.folders, folder.key),
    );
    context.read<CollectionCubit>().updateCollection(updatedCollection);
  }

  Future<void> _createFolderRequest(_VisibleFolderNode folder) async {
    final variableStore = await getIt<GetRequestVariableStoreUseCase>()();
    if (!mounted) {
      return;
    }

    final result = await showRequestEditorSheet(
      context,
      title: 'Untitled Request',
      initialDraft: const RequestDraft(),
      variableStore: _mergeImportedVariables(
        existingStore: variableStore,
        collection: widget.collection,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final request = _requestFromEditorResult(result);
    final updatedCollection = widget.collection.copyWith(
      folders: _updateFolderTree(
        widget.collection.folders,
        folder.key,
        (target) => target.copyWith(requests: [...target.requests, request]),
      ),
    );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
    setState(() => _expandedFolders.add(folder.key));
  }

  Future<void> _importCurlIntoFolder(_VisibleFolderNode folder) async {
    final curlCommand = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const _CurlImportPage(),
      ),
    );

    if (!mounted || curlCommand == null || curlCommand.trim().isEmpty) {
      return;
    }

    final parsedDraft = _curlParser.parse(curlCommand);
    final variableStore = await getIt<GetRequestVariableStoreUseCase>()();
    if (!mounted) {
      return;
    }

    final result = await showRequestEditorSheet(
      context,
      title: 'Imported cURL Request',
      initialDraft: parsedDraft,
      variableStore: _mergeImportedVariables(
        existingStore: variableStore,
        collection: widget.collection,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final request = _requestFromEditorResult(result);
    final updatedCollection = widget.collection.copyWith(
      folders: _updateFolderTree(
        widget.collection.folders,
        folder.key,
        (target) => target.copyWith(requests: [...target.requests, request]),
      ),
    );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
    setState(() => _expandedFolders.add(folder.key));
  }

  Future<void> _viewCurlRequest(ImportedCollectionRequestEntity request) async {
    final curlCommand = const CurlCommandBuilder().build(
      draft: _draftFromImportedRequest(request),
    );
    await showViewCurlSheet(context, curlCommand: curlCommand);
  }

  void _duplicateRequest({
    required ImportedCollectionRequestEntity request,
    String? folderKey,
  }) {
    final duplicatedRequest = request.copyWith(title: '${request.title} Copy');

    final updatedCollection = folderKey == null
        ? widget.collection.copyWith(
            rootRequests: _duplicateRootRequest(
              widget.collection.rootRequests,
              request,
              duplicatedRequest,
            ),
          )
        : widget.collection.copyWith(
            folders: _updateFolderTree(
              widget.collection.folders,
              folderKey,
              (target) => target.copyWith(
                requests: _duplicateFolderRequest(
                  target.requests,
                  request,
                  duplicatedRequest,
                ),
              ),
            ),
          );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
  }

  Future<void> _deleteRequest({
    required ImportedCollectionRequestEntity request,
    String? folderKey,
  }) async {
    final confirmed = await _showDeleteRequestDialog(
      request.title.trim().isEmpty ? 'Untitled Request' : request.title,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final updatedCollection = folderKey == null
        ? widget.collection.copyWith(
            rootRequests: _deleteRootRequest(
              widget.collection.rootRequests,
              request,
            ),
          )
        : widget.collection.copyWith(
            folders: _updateFolderTree(
              widget.collection.folders,
              folderKey,
              (target) => target.copyWith(
                requests: _deleteFolderRequest(target.requests, request),
              ),
            ),
          );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
  }

  List<ImportedCollectionFolderEntity> _updateFolderTree(
    List<ImportedCollectionFolderEntity> folders,
    String targetKey,
    ImportedCollectionFolderEntity Function(ImportedCollectionFolderEntity)
    transform, [
    String parentKey = '',
  ]) {
    return folders.map((folder) {
      final currentKey = _folderKey(parentKey, folder.name);
      if (currentKey == targetKey) {
        return transform(folder);
      }

      return folder.copyWith(
        folders: _updateFolderTree(
          folder.folders,
          targetKey,
          transform,
          currentKey,
        ),
      );
    }).toList(growable: false);
  }

  List<ImportedCollectionFolderEntity> _deleteFolderFromTree(
    List<ImportedCollectionFolderEntity> folders,
    String targetKey, [
    String parentKey = '',
  ]) {
    final nextFolders = <ImportedCollectionFolderEntity>[];
    for (final folder in folders) {
      final currentKey = _folderKey(parentKey, folder.name);
      if (currentKey == targetKey) {
        continue;
      }
      nextFolders.add(
        folder.copyWith(
          folders: _deleteFolderFromTree(
            folder.folders,
            targetKey,
            currentKey,
          ),
        ),
      );
    }
    return nextFolders;
  }

  List<ImportedCollectionRequestEntity> _replaceRootRequest(
    List<ImportedCollectionRequestEntity> requests,
    ImportedCollectionRequestEntity source,
    ImportedCollectionRequestEntity replacement,
  ) {
    final index = requests.indexOf(source);
    if (index < 0) {
      return requests;
    }
    final updated = [...requests];
    updated[index] = replacement;
    return List<ImportedCollectionRequestEntity>.unmodifiable(updated);
  }

  List<ImportedCollectionRequestEntity> _replaceFolderRequest(
    List<ImportedCollectionRequestEntity> requests,
    ImportedCollectionRequestEntity source,
    ImportedCollectionRequestEntity replacement,
  ) {
    return _replaceRootRequest(requests, source, replacement);
  }

  List<ImportedCollectionRequestEntity> _duplicateRootRequest(
    List<ImportedCollectionRequestEntity> requests,
    ImportedCollectionRequestEntity source,
    ImportedCollectionRequestEntity duplicate,
  ) {
    final index = requests.indexOf(source);
    if (index < 0) {
      return [...requests, duplicate];
    }
    return [
      ...requests.sublist(0, index + 1),
      duplicate,
      ...requests.sublist(index + 1),
    ];
  }

  List<ImportedCollectionRequestEntity> _duplicateFolderRequest(
    List<ImportedCollectionRequestEntity> requests,
    ImportedCollectionRequestEntity source,
    ImportedCollectionRequestEntity duplicate,
  ) {
    return _duplicateRootRequest(requests, source, duplicate);
  }

  List<ImportedCollectionRequestEntity> _deleteRootRequest(
    List<ImportedCollectionRequestEntity> requests,
    ImportedCollectionRequestEntity source,
  ) {
    final index = requests.indexOf(source);
    if (index < 0) {
      return requests;
    }
    return [
      ...requests.sublist(0, index),
      ...requests.sublist(index + 1),
    ];
  }

  List<ImportedCollectionRequestEntity> _deleteFolderRequest(
    List<ImportedCollectionRequestEntity> requests,
    ImportedCollectionRequestEntity source,
  ) {
    return _deleteRootRequest(requests, source);
  }

  ImportedCollectionRequestEntity _requestFromEditorResult(
    RequestEditorResult result,
  ) {
    final draft = result.draft;
    return ImportedCollectionRequestEntity(
      method: draft.method.wireName,
      title: result.title.trim().isEmpty ? 'Untitled Request' : result.title,
      url: draft.url,
      baseUrlValue: '',
      queryParameters: draft.queryParameters
          .where((item) => item.key.trim().isNotEmpty || item.value.trim().isNotEmpty)
          .map(
            (item) => ImportedRequestFieldEntity(
              name: item.key,
              value: item.value,
              description: item.description,
            ),
          )
          .toList(growable: false),
      headers: draft.headers
          .where((item) => item.key.trim().isNotEmpty || item.value.trim().isNotEmpty)
          .map(
            (item) => ImportedRequestFieldEntity(
              name: item.key,
              value: item.value,
              description: item.description,
            ),
          )
          .toList(growable: false),
      bodyContentType: _contentTypeFromDraft(draft),
      bodyContent: _bodyContentFromDraft(draft),
    );
  }

  Future<void> _editRequest({
    required ImportedCollectionRequestEntity request,
    String? folderKey,
  }) async {
    final variableStore = await getIt<GetRequestVariableStoreUseCase>()();
    if (!mounted) {
      return;
    }

    final result = await showRequestEditorSheet(
      context,
      title: request.title,
      initialDraft: _draftFromImportedRequest(request),
      variableStore: _mergeImportedVariables(
        existingStore: variableStore,
        collection: widget.collection,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final updatedRequest = _requestFromEditorResult(result);
    final updatedCollection = folderKey == null
        ? widget.collection.copyWith(
            rootRequests: _replaceRootRequest(
              widget.collection.rootRequests,
              request,
              updatedRequest,
            ),
          )
        : widget.collection.copyWith(
            folders: _updateFolderTree(
              widget.collection.folders,
              folderKey,
              (target) => target.copyWith(
                requests: _replaceFolderRequest(
                  target.requests,
                  request,
                  updatedRequest,
                ),
              ),
            ),
          );

    context.read<CollectionCubit>().updateCollection(updatedCollection);
  }

  String _contentTypeFromDraft(RequestDraft draft) {
    return switch (draft.body.type) {
      RequestBodyType.raw => draft.body.raw.subtype.contentType,
      RequestBodyType.xWwwFormUrlEncoded => 'application/x-www-form-urlencoded',
      RequestBodyType.formData => 'multipart/form-data',
      RequestBodyType.graphql => 'application/json',
      RequestBodyType.none => '',
    };
  }

  String _bodyContentFromDraft(RequestDraft draft) {
    return switch (draft.body.type) {
      RequestBodyType.raw => draft.body.raw.content,
      RequestBodyType.graphql => draft.body.graphQl.query,
      _ => '',
    };
  }

  Future<String?> _showNameEditorDialog({
    required String title,
    required String actionLabel,
    required String initialValue,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _FolderNameDialog(
        title: title,
        actionLabel: actionLabel,
        initialValue: initialValue,
      ),
    );
  }

  Future<bool?> _showDeleteFolderDialog(String folderName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _DeleteFolderDialog(folderName: folderName),
    );
  }

  Future<bool?> _showDeleteRequestDialog(String requestTitle) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _DeleteRequestDialog(requestTitle: requestTitle),
    );
  }
}

class _CollectionSearchBar extends StatelessWidget {
  const _CollectionSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: colors.textPrimary, fontSize: 18),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search',
          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 18),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.iconPrimary,
            size: 34,
          ),
          contentPadding: const EdgeInsets.only(top: 16, right: 20),
        ),
      ),
    );
  }
}

class _CollectionFolderNode extends StatelessWidget {
  const _CollectionFolderNode({
    required this.folder,
    required this.depth,
    required this.expandedKeys,
    required this.onToggle,
    required this.onLongPress,
    required this.onRequestTap,
    required this.onRequestLongPress,
  });

  final _VisibleFolderNode folder;
  final int depth;
  final Set<String> expandedKeys;
  final ValueChanged<String> onToggle;
  final ValueChanged<_VisibleFolderNode> onLongPress;
  final ValueChanged<ImportedCollectionRequestEntity> onRequestTap;
  final Future<void> Function({
    required ImportedCollectionRequestEntity request,
    required String folderKey,
  })
  onRequestLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expanded = expandedKeys.contains(folder.key);

    return Column(
      children: [
        _FolderRow(
          name: folder.folder.name,
          requestCount: folder.folder.requestCount,
          expanded: expanded,
          depth: depth,
          onTap: () => onToggle(folder.key),
          onLongPress: () => onLongPress(folder),
        ),
        Divider(
          color: colors.divider,
          thickness: 1,
          indent: 52.0 + (depth * 40),
        ),
        if (expanded) ...[
          for (final request in folder.visibleRequests)
            _RequestRow(
              request: request,
              depth: depth + 1,
              onTap: () => onRequestTap(request),
              onLongPress: () => onRequestLongPress(
                request: request,
                folderKey: folder.key,
              ),
            ),
          for (final child in folder.visibleChildren)
            _CollectionFolderNode(
              folder: child,
              depth: depth + 1,
              expandedKeys: expandedKeys,
              onToggle: onToggle,
              onLongPress: onLongPress,
              onRequestTap: onRequestTap,
              onRequestLongPress: onRequestLongPress,
            ),
        ],
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.name,
    required this.requestCount,
    required this.expanded,
    required this.depth,
    required this.onTap,
    required this.onLongPress,
  });

  final String name;
  final int requestCount;
  final bool expanded;
  final int depth;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final leftPadding = depth * 40.0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.fromLTRB(leftPadding, 14, 0, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, color: colors.methodGet, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$requestCount',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_right_rounded,
              color: colors.textPrimary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.depth,
    required this.onTap,
    required this.onLongPress,
  });

  final ImportedCollectionRequestEntity request;
  final int depth;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final methodLabel = _chipMethodLabel(request.method);
    final methodColor = colors.methodColor(methodLabel);
    final leftPadding = (depth * 40.0) + 40;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.fromLTRB(leftPadding, 16, 0, 18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 84),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: methodColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    methodLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textOnPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        request.url,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: colors.divider, thickness: 1),
          ],
        ),
      ),
    );
  }

  String _chipMethodLabel(String rawMethod) {
    switch (rawMethod.trim().toUpperCase()) {
      case 'DELETE':
        return 'DEL';
      case 'PATCH':
        return 'PAT';
      case 'OPTIONS':
        return 'OPT';
      case 'CONNECT':
        return 'CON';
      default:
        return rawMethod.trim().toUpperCase();
    }
  }
}

class _VisibleFolderNode {
  const _VisibleFolderNode({
    required this.folder,
    required this.key,
    required this.visibleChildren,
    required this.visibleRequests,
  });

  final ImportedCollectionFolderEntity folder;
  final String key;
  final List<_VisibleFolderNode> visibleChildren;
  final List<ImportedCollectionRequestEntity> visibleRequests;
}

enum _CollectionListAction { edit, export, delete }

class _CollectionActionsSheet extends StatelessWidget {
  const _CollectionActionsSheet({required this.collection});

  final ImportedCollectionEntity collection;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.modalShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CollectionActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.of(context).pop(_CollectionListAction.edit),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.ios_share_rounded,
                  label: 'Export...',
                  onTap: () =>
                      Navigator.of(context).pop(_CollectionListAction.export),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_CollectionListAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionActionMenuItem extends StatelessWidget {
  const _CollectionActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = danger ? const Color(0xFFFF453A) : colors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: foreground),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FolderTreeAction { rename, newRequest, newFolder, importCurl, delete }

enum _RequestTreeAction { edit, duplicate, viewCurl, delete }

class _FolderActionsSheet extends StatelessWidget {
  const _FolderActionsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.modalShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CollectionActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Rename...',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.rename),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'New Request',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.newRequest),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.create_new_folder_outlined,
                  label: 'New Folder',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.newFolder),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.code_rounded,
                  label: 'Import curl...',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.importCurl),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestActionsSheet extends StatelessWidget {
  const _RequestActionsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.modalShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CollectionActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.edit),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.copy_rounded,
                  label: 'Duplicate',
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.duplicate),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.code_rounded,
                  label: 'View curl',
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.viewCurl),
                ),
                _CollectionActionMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderNameDialog extends StatelessWidget {
  const _FolderNameDialog({
    required this.title,
    required this.actionLabel,
    required this.initialValue,
  });

  final String title;
  final String actionLabel;
  final String initialValue;

  @override
  Widget build(BuildContext context) {
    return _FolderNameDialogBody(
      title: title,
      actionLabel: actionLabel,
      initialValue: initialValue,
      confirmButtonBuilder: (label, onTap) => _CollectionDialogButton(
        label: label,
        onTap: onTap,
      ),
      cancelButtonBuilder: (label, onTap) => _CollectionDialogButton(
        label: label,
        onTap: onTap,
      ),
    );
  }
}

class _FolderNameDialogBody extends StatefulWidget {
  const _FolderNameDialogBody({
    required this.title,
    required this.actionLabel,
    required this.initialValue,
    required this.confirmButtonBuilder,
    required this.cancelButtonBuilder,
  });

  final String title;
  final String actionLabel;
  final String initialValue;
  final Widget Function(String label, VoidCallback onTap) confirmButtonBuilder;
  final Widget Function(String label, VoidCallback onTap) cancelButtonBuilder;

  @override
  State<_FolderNameDialogBody> createState() => _FolderNameDialogBodyState();
}

class _FolderNameDialogBodyState extends State<_FolderNameDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Folder Name',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: widget.cancelButtonBuilder(
                    'Cancel',
                    () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.confirmButtonBuilder(
                    widget.actionLabel,
                    () {
                      final value = _controller.text.trim();
                      if (value.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteFolderDialog extends StatelessWidget {
  const _DeleteFolderDialog({required this.folderName});

  final String folderName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Folder',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you would like to delete this folder? This will delete all sub-folders and requests inside.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              folderName,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _CollectionDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CollectionDialogButton(
                    label: 'Delete',
                    danger: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteRequestDialog extends StatelessWidget {
  const _DeleteRequestDialog({required this.requestTitle});

  final String requestTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Request',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you would like to delete this request?',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              requestTitle,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _CollectionDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CollectionDialogButton(
                    label: 'Delete',
                    danger: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurlImportPage extends StatefulWidget {
  const _CurlImportPage();

  @override
  State<_CurlImportPage> createState() => _CurlImportPageState();
}

class _CurlImportPageState extends State<_CurlImportPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  _HeaderCircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Import curl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _HeaderCircleButton(
                    icon: Icons.check_rounded,
                    filled: true,
                    onTap: () => Navigator.of(context).pop(_controller.text),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _EditorCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: _controller,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'curl https://api.example.com -X GET',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteCollectionDialog extends StatelessWidget {
  const _DeleteCollectionDialog({required this.collectionName});

  final String collectionName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Collection',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you would like to delete "$collectionName"?',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _CollectionDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CollectionDialogButton(
                    label: 'Delete',
                    danger: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionDialogButton extends StatelessWidget {
  const _CollectionDialogButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: danger ? const Color(0xFFFF453A) : colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionEditorPage extends StatefulWidget {
  const _CollectionEditorPage({required this.collection});

  final ImportedCollectionEntity collection;

  @override
  State<_CollectionEditorPage> createState() => _CollectionEditorPageState();
}

class _CollectionEditorPageState extends State<_CollectionEditorPage> {
  late final TextEditingController _nameController;
  late List<ImportedCollectionVariableEntity> _variables;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _variables = widget.collection.variables.isEmpty
        ? <ImportedCollectionVariableEntity>[
            const ImportedCollectionVariableEntity(name: 'baseUrl', value: ''),
          ]
        : widget.collection.variables
              .map((item) => item.copyWith())
              .toList(growable: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                _HeaderCircleButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'Collection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _HeaderCircleButton(
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: _save,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _EditorCard(
              child: TextField(
                controller: _nameController,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Collection name',
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Variables',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _EditorCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _variables.length; i++) ...[
                    _VariableRow(
                      variable: _variables[i],
                      onChanged: (updated) =>
                          setState(() => _variables[i] = updated),
                    ),
                    if (i != _variables.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.divider,
                        indent: 64,
                      ),
                  ],
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.divider,
                    indent: 64,
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _variables.add(
                        const ImportedCollectionVariableEntity(
                          name: '',
                          value: '',
                        ),
                      );
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          const _VariableStateDot(
                            icon: Icons.add_rounded,
                            filled: true,
                          ),
                          const SizedBox(width: 18),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Auth',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _EditorCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Auth',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    widget.collection.authLabel,
                    style: TextStyle(
                      color: colors.methodGet,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    color: colors.methodGet,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final cleanedVariables = _variables
        .where((item) => item.name.trim().isNotEmpty)
        .map(
          (item) =>
              item.copyWith(name: item.name.trim(), value: item.value.trim()),
        )
        .toList(growable: false);

    Navigator.of(context).pop(
      widget.collection.copyWith(
        name: _nameController.text.trim().isEmpty
            ? widget.collection.name
            : _nameController.text.trim(),
        variables: cleanedVariables,
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: child,
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: filled ? colors.methodGet : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            color: filled ? colors.textOnPrimary : colors.textPrimary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({required this.variable, required this.onChanged});

  final ImportedCollectionVariableEntity variable;
  final ValueChanged<ImportedCollectionVariableEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                onChanged(variable.copyWith(isEnabled: !variable.isEnabled)),
            child: _VariableStateDot(
              icon: variable.isEnabled
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              filled: variable.isEnabled,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: TextFormField(
              initialValue: variable.name,
              onChanged: (value) => onChanged(variable.copyWith(name: value)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Variable',
              ),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: variable.value,
              textAlign: TextAlign.right,
              onChanged: (value) => onChanged(variable.copyWith(value: value)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Value',
              ),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariableStateDot extends StatelessWidget {
  const _VariableStateDot({required this.icon, required this.filled});

  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.methodGet : Colors.transparent,
        border: Border.all(
          color: filled ? colors.methodGet : colors.border,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: filled ? colors.textOnPrimary : colors.secondary,
      ),
    );
  }
}
