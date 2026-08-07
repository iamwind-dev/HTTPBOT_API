import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../widget/search_postman.dart';
import '../widget/postman_folder_item.dart';

class PostmanCollectionDetailPage extends StatelessWidget {
  const PostmanCollectionDetailPage({super.key, required this.collection});

  final PostmanCollectionEntity collection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.medium),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _CircleAction(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          collection.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    _CircleAction(
                      icon: Icons.more_horiz_rounded,
                      onTap: () {
                        //TODO:
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              const PostmanSearch(),
              const SizedBox(height: AppSpacing.small),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                  itemCount: collection.folders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xSmall),
                  itemBuilder: (context, index) {
                    final folder = collection.folders[index];
                    return PostmanFolderItem(folder: folder);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.headerActionSurface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: colors.iconPrimary),
        ),
      ),
    );
  }
}
