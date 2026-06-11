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
import 'package:httpbot_api/features/request_builder/domain/usecases/get_request_variable_store_use_case.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/request_editor_sheet.dart';

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
                    return CollectionsListItem(
                      item: item,
                      onTap: () => context
                          .read<CollectionCubit>()
                          .selectCollection(item.id),
                    );
                  },
                ),
        );
      },
    );
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
            onRequestTap: _openRequestEditor,
          ),
      ],
    );
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
        request: request,
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
      variables: request.baseUrlValue.trim().isEmpty
          ? const <RequestVariable>[]
          : <RequestVariable>[
              RequestVariable(
                key: 'baseUrl',
                initialValue: request.baseUrlValue,
                description: 'Imported from the selected API spec',
              ),
            ],
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
    required ImportedCollectionRequestEntity request,
  }) {
    if (request.baseUrlValue.trim().isEmpty) {
      return existingStore;
    }

    final variables =
        existingStore.globalVariables
            .where((variable) => variable.key != 'baseUrl')
            .toList(growable: true)
          ..insert(
            0,
            RequestVariable(
              key: 'baseUrl',
              initialValue: request.baseUrlValue,
              scope: RequestVariableScope.global,
              description: 'Imported from the selected API spec',
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
    required this.onRequestTap,
  });

  final _VisibleFolderNode folder;
  final int depth;
  final Set<String> expandedKeys;
  final ValueChanged<String> onToggle;
  final ValueChanged<ImportedCollectionRequestEntity> onRequestTap;

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
            ),
          for (final child in folder.visibleChildren)
            _CollectionFolderNode(
              folder: child,
              depth: depth + 1,
              expandedKeys: expandedKeys,
              onToggle: onToggle,
              onRequestTap: onRequestTap,
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
  });

  final String name;
  final int requestCount;
  final bool expanded;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final leftPadding = depth * 40.0;

    return InkWell(
      onTap: onTap,
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
  });

  final ImportedCollectionRequestEntity request;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final methodLabel = _chipMethodLabel(request.method);
    final methodColor = colors.methodColor(methodLabel);
    final leftPadding = (depth * 40.0) + 40;

    return InkWell(
      onTap: onTap,
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
