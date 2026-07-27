import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/body_empty.dart';
import '../../domain/entities/postman_auth_entity.dart';
import '../../domain/entities/postman_body_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_folder_entity.dart';
import '../../domain/entities/postman_key_value_entity.dart';
import '../../domain/entities/postman_request_entity.dart';
import '../../domain/entities/postman_url_entity.dart';
import '../../domain/entities/postman_variable_entity.dart';
import '../../presentation/cubit/postman_cubit.dart';
import '../../presentation/cubit/postman_state.dart';
import '../mappers/postman_request_to_request_draft_mapper.dart';
import '../model/postman_list_item_model.dart';
import '../widget/postman_list_item.dart';
import '../../../request_builder/domain/entities/request_body_draft.dart';
import '../../../request_builder/domain/entities/request_draft.dart';
import '../../../request_builder/domain/entities/request_variable.dart';
import '../../../request_builder/domain/entities/request_variable_store.dart';
import '../../../request_builder/domain/helpers/curl_command_builder.dart';
import '../../../request_builder/domain/helpers/simple_curl_request_parser.dart';
import '../../../request_builder/presentation/models/request_editor_result.dart';
import '../../../request_builder/presentation/widgets/request_editor_sheet.dart';
import '../../../request_builder/presentation/widgets/view_curl_sheet.dart';

class PostmanScreen extends StatelessWidget {
  const PostmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostmanCubit, PostmanState>(
      builder: (context, state) {
        if (state.isLoadingCollections || state.isLoadingCollectionDetail) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedCollection = state.selectedCollection;
        if (selectedCollection != null) {
          return _PostmanDetailView(collection: selectedCollection);
        }

        if (state.hasLinkedApi && !state.hasWorkspaces) {
          return const BodyEmpty(
            title: 'No Workspaces',
            subtitle: 'No Postman workspaces were found for this API key',
          );
        }

        if (state.collections.isEmpty) {
          return const BodyEmpty(
            title: 'No Collections',
            subtitle: "Tap '+' to create or import a new collection",
          );
        }

        final items = state.collections
            .map(
              (collection) => PostmanListItemModel(
                folderName: collection.name,
                itemCount: collection.totalRequestCount,
              ),
            )
            .toList(growable: false);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final collection = state.collections[index];

            return PostmanListItem(
              item: item,
              onTap: () async {
                await context.read<PostmanCubit>().loadCollectionDetail(
                  collection: collection,
                );
              },
              onMoreTap: () => _showCollectionActions(context, collection),
            );
          },
        );
      },
    );
  }

  Future<void> _showCollectionActions(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final action = await showModalBottomSheet<_PostmanListAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PostmanActionsSheet(),
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _PostmanListAction.edit:
        await _editCollection(context, collection);
        break;
      case _PostmanListAction.export:
        await _exportCollection(collection);
        break;
      case _PostmanListAction.delete:
        await _deleteCollection(context, collection);
        break;
    }
  }

  Future<void> _editCollection(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final updated = await Navigator.of(context).push<PostmanCollectionEntity>(
      MaterialPageRoute<PostmanCollectionEntity>(
        fullscreenDialog: true,
        builder: (_) => _PostmanCollectionEditorPage(collection: collection),
      ),
    );

    if (!context.mounted || updated == null) {
      return;
    }

    await context.read<PostmanCubit>().updateCollection(updated);
  }

  Future<void> _deleteCollection(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DeletePostmanCollectionDialog(
        collectionName: collection.name,
      ),
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    await context.read<PostmanCubit>().deleteCollection(collection.id);
  }

  Future<void> _exportCollection(PostmanCollectionEntity collection) {
    final payload = _collectionToExportPayload(collection);
    return SharePlus.instance.share(
      ShareParams(
        subject: collection.name,
        text: const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );
  }

  Map<String, Object?> _collectionToExportPayload(
    PostmanCollectionEntity collection,
  ) {
    return <String, Object?>{
      'id': collection.id,
      'name': collection.name,
      'description': collection.description,
      'auth': collection.auth.type.name,
      'variables': collection.variables
          .map(
            (variable) => <String, Object?>{
              'key': variable.key,
              'value': variable.value,
              'type': variable.type,
              'enabled': variable.isEnabled,
            },
          )
          .toList(growable: false),
      'folders': collection.folders
          .map(_folderToJson)
          .toList(growable: false),
      'requests': collection.requests
          .map(_requestToJson)
          .toList(growable: false),
    };
  }

  Map<String, Object?> _folderToJson(PostmanFolderEntity folder) {
    return <String, Object?>{
      'id': folder.id,
      'name': folder.name,
      'folders': folder.folders.map(_folderToJson).toList(growable: false),
      'requests': folder.requests.map(_requestToJson).toList(growable: false),
    };
  }

  Map<String, Object?> _requestToJson(PostmanRequestEntity request) {
    return <String, Object?>{
      'id': request.id,
      'name': request.name,
      'description': request.description,
      'method': request.method,
      'url': request.rawUrl,
      'queryParameters': request.queryParameters
          .map(
            (item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'enabled': item.isEnabled,
              'type': item.type.name,
              'contentType': item.contentType,
              'description': item.description,
            },
          )
          .toList(growable: false),
      'headers': request.headers
          .map(
            (item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'enabled': item.isEnabled,
              'type': item.type.name,
              'contentType': item.contentType,
              'description': item.description,
            },
          )
          .toList(growable: false),
      'body': <String, Object?>{
        'type': request.body.type.name,
        'raw': request.body.raw,
        'rawSubtype': request.body.rawSubtype.name,
        'graphQlQuery': request.body.graphQlQuery,
        'graphQlVariables': request.body.graphQlVariables,
        'filePath': request.body.filePath,
      },
      'auth': request.auth.type.name,
    };
  }
}

class _PostmanDetailView extends StatefulWidget {
  const _PostmanDetailView({required this.collection});

  final PostmanCollectionEntity collection;

  @override
  State<_PostmanDetailView> createState() => _PostmanDetailViewState();
}

class _PostmanDetailViewState extends State<_PostmanDetailView> {
  final Set<String> _expandedFolders = <String>{};
  late final TextEditingController _searchController;
  static const _curlParser = SimpleCurlRequestParser();

  String get _searchQuery => _searchController.text;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PostmanDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection.id != widget.collection.id) {
      _expandedFolders.clear();
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
    final visibleRootRequests = widget.collection.requests
        .where((request) => _requestMatchesQuery(request, _searchQuery))
        .toList(growable: false);
    final hasVisibleItems =
        visibleFolders.isNotEmpty || visibleRootRequests.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _PostmanSearchBar(
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
          _PostmanRequestRow(
            request: request,
            depth: 0,
            onTap: () => _editOrOpenRequest(request: request),
            onLongPress: () => _showRequestActions(request: request),
          ),
        for (final folder in visibleFolders)
          _PostmanFolderNode(
            folder: folder,
            depth: 0,
            expandedKeys: _expandedFolders,
            forceExpanded: _searchQuery.trim().isNotEmpty,
            onToggle: (folderKey) => setState(() {
              if (_expandedFolders.contains(folderKey)) {
                _expandedFolders.remove(folderKey);
              } else {
                _expandedFolders.add(folderKey);
              }
            }),
            onLongPress: _showFolderActions,
            onRequestLongPress: ({
              required request,
              required folderKey,
            }) => _showRequestActions(
              request: request,
              folderKey: folderKey,
            ),
            onRequestTap: ({
              required request,
              required folderKey,
            }) => _editOrOpenRequest(request: request, folderKey: folderKey),
          ),
      ],
    );
  }

  Future<void> _showFolderActions(_VisiblePostmanFolderNode folder) async {
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
    required PostmanRequestEntity request,
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
        await _editOrOpenRequest(request: request, folderKey: folderKey);
        break;
      case _RequestTreeAction.duplicate:
        await _duplicateRequest(request: request, folderKey: folderKey);
        break;
      case _RequestTreeAction.viewCurl:
        await _viewCurlRequest(request);
        break;
      case _RequestTreeAction.delete:
        await _deleteRequest(request: request, folderKey: folderKey);
        break;
    }
  }

  List<_VisiblePostmanFolderNode> _filterFolders(
    List<PostmanFolderEntity> folders,
    String query, [
    String parentKey = '',
  ]) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return folders
          .map(
            (folder) => _VisiblePostmanFolderNode(
              folder: folder,
              key: _folderKey(parentKey, folder.id),
              visibleChildren: _filterFolders(
                folder.folders,
                normalizedQuery,
                _folderKey(parentKey, folder.id),
              ),
              visibleRequests: folder.requests,
            ),
          )
          .toList(growable: false);
    }

    final visible = <_VisiblePostmanFolderNode>[];
    for (final folder in folders) {
      final folderKey = _folderKey(parentKey, folder.id);
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
        _VisiblePostmanFolderNode(
          folder: folder,
          key: folderKey,
          visibleChildren: childFolders,
          visibleRequests: folderMatches ? folder.requests : matchingRequests,
        ),
      );
    }

    return visible;
  }

  bool _requestMatchesQuery(PostmanRequestEntity request, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return request.name.toLowerCase().contains(normalizedQuery) ||
        request.rawUrl.toLowerCase().contains(normalizedQuery) ||
        request.method.toLowerCase().contains(normalizedQuery);
  }

  String _folderKey(String parentKey, String folderId) {
    if (parentKey.isEmpty) {
      return folderId;
    }
    return '$parentKey/$folderId';
  }

  Future<void> _renameFolder(_VisiblePostmanFolderNode folder) async {
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
    await context.read<PostmanCubit>().updateCollection(updatedCollection);
  }

  Future<void> _createChildFolder(_VisiblePostmanFolderNode folder) async {
    final folderName = await _showNameEditorDialog(
      title: 'New Folder',
      actionLabel: 'Create',
      initialValue: '',
    );
    if (!mounted || folderName == null) {
      return;
    }

    final childId =
        '${folder.folder.id}_${DateTime.now().microsecondsSinceEpoch}';
    final updatedCollection = widget.collection.copyWith(
      folders: _updateFolderTree(
        widget.collection.folders,
        folder.key,
        (target) => target.copyWith(
          folders: [
            ...target.folders,
            PostmanFolderEntity(id: childId, name: folderName),
          ],
        ),
      ),
    );

    await context.read<PostmanCubit>().updateCollection(updatedCollection);
    setState(() => _expandedFolders.add(folder.key));
  }

  Future<void> _deleteFolder(_VisiblePostmanFolderNode folder) async {
    final confirmed = await _showDeleteFolderDialog(folder.folder.name);
    if (!mounted || confirmed != true) {
      return;
    }

    final updatedCollection = widget.collection.copyWith(
      folders: _deleteFolderFromTree(widget.collection.folders, folder.key),
    );
    await context.read<PostmanCubit>().updateCollection(updatedCollection);
  }

  Future<void> _createFolderRequest(_VisiblePostmanFolderNode folder) async {
    final result = await showRequestEditorSheet(
      context,
      title: 'Untitled Request',
      initialDraft: const RequestDraft(),
      variableStore: _variableStoreFromCollection(),
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

    await context.read<PostmanCubit>().updateCollection(updatedCollection);
    setState(() => _expandedFolders.add(folder.key));
  }

  Future<void> _editOrOpenRequest({
    required PostmanRequestEntity request,
    String? folderKey,
  }) async {
    const mapper = PostmanRequestToRequestDraftMapper();
    final result = await showRequestEditorSheet(
      context,
      title: request.name.trim().isEmpty ? 'Untitled Request' : request.name,
      initialDraft: mapper(request),
      variableStore: _variableStoreFromCollection(),
    );

    if (!mounted || result == null) {
      return;
    }

    final updatedRequest = _requestFromEditorResult(result);
    final updatedCollection = folderKey == null
        ? widget.collection.copyWith(
            requests: _replaceRootRequest(
              widget.collection.requests,
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

    await context.read<PostmanCubit>().updateCollection(updatedCollection);
  }

  Future<void> _importCurlIntoFolder(_VisiblePostmanFolderNode folder) async {
    final curlCommand = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const _CurlImportPage(),
      ),
    );

    if (!mounted || curlCommand == null || curlCommand.trim().isEmpty) {
      return;
    }

    final result = await showRequestEditorSheet(
      context,
      title: 'Imported cURL Request',
      initialDraft: _curlParser.parse(curlCommand),
      variableStore: _variableStoreFromCollection(),
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

    await context.read<PostmanCubit>().updateCollection(updatedCollection);
    setState(() => _expandedFolders.add(folder.key));
  }

  Future<void> _viewCurlRequest(PostmanRequestEntity request) async {
    const mapper = PostmanRequestToRequestDraftMapper();
    final curlCommand = const CurlCommandBuilder().build(
      draft: mapper(request),
    );
    await showViewCurlSheet(context, curlCommand: curlCommand);
  }

  Future<void> _duplicateRequest({
    required PostmanRequestEntity request,
    String? folderKey,
  }) async {
    final duplicate = request.copyWith(name: '${request.name} Copy');
    final updatedCollection = folderKey == null
        ? widget.collection.copyWith(
            requests: _duplicateRootRequest(
              widget.collection.requests,
              request,
              duplicate,
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
                  duplicate,
                ),
              ),
            ),
          );

    await context.read<PostmanCubit>().updateCollection(updatedCollection);
  }

  Future<void> _deleteRequest({
    required PostmanRequestEntity request,
    String? folderKey,
  }) async {
    final confirmed = await _showDeleteRequestDialog(
      request.name.trim().isEmpty ? 'Untitled Request' : request.name,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final updatedCollection = folderKey == null
        ? widget.collection.copyWith(
            requests: _deleteRootRequest(widget.collection.requests, request),
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

    await context.read<PostmanCubit>().updateCollection(updatedCollection);
  }

  RequestVariableStore _variableStoreFromCollection() {
    final variables = widget.collection.variables
        .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
        .map(
          (item) => RequestVariable(
            key: item.key,
            currentValue: item.value,
            initialValue: item.value,
            description: 'Imported from the selected collection',
          ),
        )
        .toList(growable: false);

    return RequestVariableStore(
      globalVariables: variables,
      environments: const [],
    );
  }

  List<PostmanFolderEntity> _updateFolderTree(
    List<PostmanFolderEntity> folders,
    String targetKey,
    PostmanFolderEntity Function(PostmanFolderEntity) transform, [
    String parentKey = '',
  ]) {
    return folders.map((folder) {
      final currentKey = _folderKey(parentKey, folder.id);
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

  List<PostmanFolderEntity> _deleteFolderFromTree(
    List<PostmanFolderEntity> folders,
    String targetKey, [
    String parentKey = '',
  ]) {
    final nextFolders = <PostmanFolderEntity>[];
    for (final folder in folders) {
      final currentKey = _folderKey(parentKey, folder.id);
      if (currentKey == targetKey) {
        continue;
      }
      nextFolders.add(
        folder.copyWith(
          folders: _deleteFolderFromTree(folder.folders, targetKey, currentKey),
        ),
      );
    }
    return nextFolders;
  }

  List<PostmanRequestEntity> _replaceRootRequest(
    List<PostmanRequestEntity> requests,
    PostmanRequestEntity source,
    PostmanRequestEntity replacement,
  ) {
    final index = requests.indexOf(source);
    if (index < 0) {
      return requests;
    }
    final updated = [...requests];
    updated[index] = replacement;
    return List<PostmanRequestEntity>.unmodifiable(updated);
  }

  List<PostmanRequestEntity> _replaceFolderRequest(
    List<PostmanRequestEntity> requests,
    PostmanRequestEntity source,
    PostmanRequestEntity replacement,
  ) {
    return _replaceRootRequest(requests, source, replacement);
  }

  List<PostmanRequestEntity> _duplicateRootRequest(
    List<PostmanRequestEntity> requests,
    PostmanRequestEntity source,
    PostmanRequestEntity duplicate,
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

  List<PostmanRequestEntity> _duplicateFolderRequest(
    List<PostmanRequestEntity> requests,
    PostmanRequestEntity source,
    PostmanRequestEntity duplicate,
  ) {
    return _duplicateRootRequest(requests, source, duplicate);
  }

  List<PostmanRequestEntity> _deleteRootRequest(
    List<PostmanRequestEntity> requests,
    PostmanRequestEntity source,
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

  List<PostmanRequestEntity> _deleteFolderRequest(
    List<PostmanRequestEntity> requests,
    PostmanRequestEntity source,
  ) {
    return _deleteRootRequest(requests, source);
  }

  PostmanRequestEntity _requestFromEditorResult(RequestEditorResult result) {
    final draft = result.draft;
    return PostmanRequestEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: result.title.trim().isEmpty ? 'Untitled Request' : result.title,
      method: draft.method.wireName,
      url: PostmanUrlEntity(raw: draft.url),
      queryParameters: draft.queryParameters
          .where((item) => item.key.trim().isNotEmpty || item.value.trim().isNotEmpty)
          .map(
            (item) => PostmanKeyValueEntity(
              key: item.key,
              value: item.value,
              isEnabled: item.isEnabled,
              contentType: item.contentType,
              description: item.description,
            ),
          )
          .toList(growable: false),
      headers: draft.headers
          .where((item) => item.key.trim().isNotEmpty || item.value.trim().isNotEmpty)
          .map(
            (item) => PostmanKeyValueEntity(
              key: item.key,
              value: item.value,
              isEnabled: item.isEnabled,
              contentType: item.contentType,
              description: item.description,
            ),
          )
          .toList(growable: false),
      body: _bodyFromDraft(draft),
    );
  }

  PostmanBodyEntity _bodyFromDraft(RequestDraft draft) {
    return switch (draft.body.type) {
      RequestBodyType.raw => PostmanBodyEntity(
          type: PostmanBodyType.raw,
          raw: draft.body.raw.content,
          rawSubtype: switch (draft.body.raw.subtype) {
            RawBodySubtype.json => PostmanRawBodySubtype.json,
            RawBodySubtype.xml => PostmanRawBodySubtype.xml,
            RawBodySubtype.html => PostmanRawBodySubtype.html,
            RawBodySubtype.text => PostmanRawBodySubtype.text,
          },
        ),
      RequestBodyType.none => const PostmanBodyEntity(),
      _ => const PostmanBodyEntity(),
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

class _PostmanSearchBar extends StatelessWidget {
  const _PostmanSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
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
          contentPadding: const EdgeInsets.only(
            top: 16,
            right: 20,
            bottom: 16,
          ),
        ),
      ),
    );
  }
}

class _PostmanFolderNode extends StatelessWidget {
  const _PostmanFolderNode({
    required this.folder,
    required this.depth,
    required this.expandedKeys,
    required this.forceExpanded,
    required this.onToggle,
    required this.onLongPress,
    required this.onRequestLongPress,
    required this.onRequestTap,
  });

  final _VisiblePostmanFolderNode folder;
  final int depth;
  final Set<String> expandedKeys;
  final bool forceExpanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<_VisiblePostmanFolderNode> onLongPress;
  final Future<void> Function({
    required PostmanRequestEntity request,
    required String folderKey,
  })
  onRequestLongPress;
  final Future<void> Function({
    required PostmanRequestEntity request,
    required String folderKey,
  })
  onRequestTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expanded = forceExpanded || expandedKeys.contains(folder.key);

    return Column(
      children: [
        _PostmanFolderRow(
          name: folder.folder.name,
          requestCount: folder.folder.itemCount,
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
            _PostmanRequestRow(
              request: request,
              depth: depth + 1,
              onTap: () => onRequestTap(
                request: request,
                folderKey: folder.key,
              ),
              onLongPress: () => onRequestLongPress(
                request: request,
                folderKey: folder.key,
              ),
            ),
          for (final child in folder.visibleChildren)
            _PostmanFolderNode(
              folder: child,
              depth: depth + 1,
              expandedKeys: expandedKeys,
              forceExpanded: forceExpanded,
              onToggle: onToggle,
              onLongPress: onLongPress,
              onRequestLongPress: onRequestLongPress,
              onRequestTap: onRequestTap,
            ),
        ],
      ],
    );
  }
}

class _PostmanFolderRow extends StatelessWidget {
  const _PostmanFolderRow({
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

class _PostmanRequestRow extends StatelessWidget {
  const _PostmanRequestRow({
    required this.request,
    required this.depth,
    required this.onTap,
    required this.onLongPress,
  });

  final PostmanRequestEntity request;
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
                        request.name.trim().isEmpty
                            ? 'Untitled Request'
                            : request.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        request.rawUrl,
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

class _VisiblePostmanFolderNode {
  const _VisiblePostmanFolderNode({
    required this.folder,
    required this.key,
    required this.visibleChildren,
    required this.visibleRequests,
  });

  final PostmanFolderEntity folder;
  final String key;
  final List<_VisiblePostmanFolderNode> visibleChildren;
  final List<PostmanRequestEntity> visibleRequests;
}

enum _PostmanListAction { edit, export, delete }

class _PostmanActionsSheet extends StatelessWidget {
  const _PostmanActionsSheet();

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
                _PostmanActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.of(context).pop(_PostmanListAction.edit),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.ios_share_rounded,
                  label: 'Export...',
                  onTap: () =>
                      Navigator.of(context).pop(_PostmanListAction.export),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_PostmanListAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostmanActionMenuItem extends StatelessWidget {
  const _PostmanActionMenuItem({
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
                _PostmanActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Rename...',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.rename),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'New Request',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.newRequest),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.create_new_folder_outlined,
                  label: 'New Folder',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.newFolder),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.code_rounded,
                  label: 'Import curl...',
                  onTap: () =>
                      Navigator.of(context).pop(_FolderTreeAction.importCurl),
                ),
                _PostmanActionMenuItem(
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
                _PostmanActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.edit),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.copy_rounded,
                  label: 'Duplicate',
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.duplicate),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.code_rounded,
                  label: 'View curl',
                  onTap: () =>
                      Navigator.of(context).pop(_RequestTreeAction.viewCurl),
                ),
                _PostmanActionMenuItem(
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
      confirmButtonBuilder: (label, onTap) => _PostmanDialogButton(
        label: label,
        onTap: onTap,
      ),
      cancelButtonBuilder: (label, onTap) => _PostmanDialogButton(
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
                  child: _PostmanDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PostmanDialogButton(
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
                  child: _PostmanDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PostmanDialogButton(
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

class _DeletePostmanCollectionDialog extends StatelessWidget {
  const _DeletePostmanCollectionDialog({required this.collectionName});

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
                  child: _PostmanDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PostmanDialogButton(
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

class _PostmanDialogButton extends StatelessWidget {
  const _PostmanDialogButton({
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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

class _PostmanCollectionEditorPage extends StatefulWidget {
  const _PostmanCollectionEditorPage({required this.collection});

  final PostmanCollectionEntity collection;

  @override
  State<_PostmanCollectionEditorPage> createState() =>
      _PostmanCollectionEditorPageState();
}

class _PostmanCollectionEditorPageState
    extends State<_PostmanCollectionEditorPage> {
  late final TextEditingController _nameController;
  late List<PostmanVariableEntity> _variables;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _variables = widget.collection.variables.isEmpty
        ? <PostmanVariableEntity>[
            const PostmanVariableEntity(key: 'baseUrl', value: ''),
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
                    _PostmanVariableRow(
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
                        const PostmanVariableEntity(key: '', value: ''),
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
                    _postmanAuthLabel(widget.collection.auth.type),
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
        .where((item) => item.key.trim().isNotEmpty)
        .map(
          (item) => item.copyWith(
            key: item.key.trim(),
            value: item.value.trim(),
          ),
        )
        .toList(growable: false);

    final updated = widget.collection.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.collection.name
          : _nameController.text.trim(),
      variables: cleanedVariables,
    );
    Navigator.of(context).pop(updated);
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

class _PostmanVariableRow extends StatelessWidget {
  const _PostmanVariableRow({
    required this.variable,
    required this.onChanged,
  });

  final PostmanVariableEntity variable;
  final ValueChanged<PostmanVariableEntity> onChanged;

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
              initialValue: variable.key,
              onChanged: (value) => onChanged(variable.copyWith(key: value)),
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

String _postmanAuthLabel(PostmanAuthType type) {
  switch (type) {
    case PostmanAuthType.none:
      return 'No Auth';
    case PostmanAuthType.apiKey:
      return 'API Key';
    case PostmanAuthType.bearerToken:
      return 'Bearer Token';
    case PostmanAuthType.awsSignature:
      return 'AWS Signature';
    case PostmanAuthType.oauth1:
      return 'OAuth 1.0';
    case PostmanAuthType.oauth2:
      return 'OAuth 2.0';
    case PostmanAuthType.ntlm:
      return 'NTLM';
    default:
      return type.name[0].toUpperCase() + type.name.substring(1);
  }
}
