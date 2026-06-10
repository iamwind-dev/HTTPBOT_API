import 'package:flutter/material.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';
import 'package:httpbot_api/features/collection/presentation/model/list_collections.dart';
import 'package:httpbot_api/generated/assets.gen.dart';

class CollectionsListItem extends StatelessWidget {
  const CollectionsListItem({super.key, required this.item});

  final CollectionItemModel item;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Row(
          children: [
            Assets.icons.collections.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(Colors.blue, BlendMode.srcIn),
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
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '${item.itemCount}',
                  style: TextStyle(fontSize: 14, color: colors.secondary),
                ),
              ),
            ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios,
              color: colors.secondary.withValues(alpha: 0.3),
            ),
          ],
        ),
        SizedBox(height: 10),
        Divider(color: colors.divider, thickness: 1),
      ],
    );
  }
}
