import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:httpbot_api/core/widgets/body_empty.dart';
import 'package:httpbot_api/features/postman/presentation/cubit/postman_cubit.dart';
import 'package:httpbot_api/features/postman/presentation/cubit/postman_state.dart';
import 'package:httpbot_api/features/postman/presentation/model/postman_list_item_model.dart';
import 'package:httpbot_api/features/postman/presentation/widget/postman_folder_item.dart';
import 'package:httpbot_api/features/postman/presentation/widget/postman_list_item.dart';

class PostmanScreen extends StatelessWidget {
  const PostmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostmanCubit, PostmanState>(
      builder: (context, state) {
        if (state.isLoadingCollections || state.isLoadingCollectionDetail) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.selectedCollection != null) {
          final folders = state.selectedCollection!.folders;

          if (folders.isEmpty) {
            return const BodyEmpty(
              title: 'No Folders',
              subtitle: 'This workspace does not have folders yet',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final folder = folders[index];

              return PostmanFolderItem(folder: folder);
            },
          );
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
            .toList();

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
            );
          },
        );
      },
    );
  }
}