import 'package:flutter/material.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';
import 'package:httpbot_api/features/postman/domain/entities/postman_folder_entity.dart';
import 'package:httpbot_api/features/postman/presentation/widget/postman_request_item.dart';

class PostmanFolderItem extends StatefulWidget {
  const PostmanFolderItem({
    super.key,
    required this.folder,
  });

  final PostmanFolderEntity folder;

  @override
  State<PostmanFolderItem> createState() => _PostmanFolderItemState();
}

class _PostmanFolderItemState extends State<PostmanFolderItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.folder.name,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 35,
                height: 23,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${widget.folder.itemCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.arrow_forward_ios,
                color: colors.secondary.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(
          color: colors.divider,
          thickness: 1,
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          ...widget.folder.requests.map(
            (request) => PostmanRequestItem(request: request),
          ),
        ],
      ],
    );
  }
}