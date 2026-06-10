import 'package:flutter/material.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';
import 'package:httpbot_api/features/postman/presentation/model/postman_list_item_model.dart';
import 'package:httpbot_api/generated/assets.gen.dart';

class PostmanListItem extends StatelessWidget {
  const PostmanListItem({super.key, required this.item, required this.onTap});

  final PostmanListItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Assets.icons.collections.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colors.methodGet,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.folderName,
                  style: TextStyle(fontSize: 16, color: colors.textPrimary),
                ),
              ),
              Container(
                width: 35,
                height: 23,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${item.itemCount}',
                    style: TextStyle(fontSize: 14, color: colors.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios,
                color: colors.secondary.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: colors.divider, thickness: 1),
        ],
      ),
    );
  }
}
