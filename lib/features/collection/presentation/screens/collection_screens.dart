import 'package:flutter/material.dart';
import 'package:httpbot_api/core/widgets/body_empty.dart';
import 'package:httpbot_api/features/collection/presentation/widget/collections_list_item.dart';
import 'package:httpbot_api/features/collection/presentation/model/list_collections.dart';

class CollectionScreen extends StatelessWidget {
  CollectionScreen({super.key});

  final List<CollectionItemModel> fakeCollections = const [
    CollectionItemModel(folderName: 'User APIs', itemCount: 12),
    CollectionItemModel(folderName: 'Authentication', itemCount: 5),
    CollectionItemModel(folderName: 'Products', itemCount: 18),
    CollectionItemModel(folderName: 'Orders', itemCount: 9),
    CollectionItemModel(folderName: 'Payment', itemCount: 6),
    CollectionItemModel(folderName: 'Notifications', itemCount: 4),
    CollectionItemModel(folderName: 'Analytics', itemCount: 11),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: fakeCollections.isEmpty
          ? const BodyEmpty(
              title: "No Collections",
              subtitle: "Tap '+' to create or import a new collection",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: fakeCollections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return CollectionsListItem(
                  item: fakeCollections[index],
                );
              },
            ),
    );
  }
}