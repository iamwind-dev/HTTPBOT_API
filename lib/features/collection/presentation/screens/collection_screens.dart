import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:httpbot_api/core/widgets/body_empty.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';
import 'package:httpbot_api/features/collection/presentation/model/list_collections.dart';
import 'package:httpbot_api/features/collection/presentation/widget/collections_list_item.dart';

import '../cubits/collection_cubit.dart';
import '../cubits/collection_state.dart';
import '../../domain/entities/imported_collection_entity.dart';

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
                  title: "No Collections",
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

  @override
  void initState() {
    super.initState();
    for (final folder in widget.collection.folders) {
      _expandedFolders.add(folder.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final folders = widget.collection.folders;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Divider(color: colors.divider, thickness: 1),
        const SizedBox(height: 8),
        for (final folder in folders) ...[
          _FolderRow(
            name: folder.name,
            requestCount: folder.requests.length,
            expanded: _expandedFolders.contains(folder.name),
            onTap: () => setState(() {
              if (_expandedFolders.contains(folder.name)) {
                _expandedFolders.remove(folder.name);
              } else {
                _expandedFolders.add(folder.name);
              }
            }),
          ),
          if (_expandedFolders.contains(folder.name))
            ...folder.requests.map((request) => _RequestRow(request: request)),
          Divider(color: colors.divider, thickness: 1),
          const SizedBox(height: 8),
        ],
        if (folders.isEmpty)
          ...widget.collection.rootRequests.map(
            (request) => _RequestRow(request: request),
          ),
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.name,
    required this.requestCount,
    required this.expanded,
    required this.onTap,
  });

  final String name;
  final int requestCount;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, color: colors.methodGet, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$requestCount',
                  style: TextStyle(fontSize: 15, color: colors.secondary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_right_rounded,
              color: colors.textPrimary,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final ImportedCollectionRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 8, 0, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.methodGet,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              request.method,
              style: TextStyle(
                color: colors.textOnPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.url,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
