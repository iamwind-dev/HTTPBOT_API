import 'package:flutter/material.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';
import 'package:httpbot_api/features/postman/domain/entities/postman_request_entity.dart';
import 'package:httpbot_api/features/postman/presentation/mappers/postman_request_to_request_draft_mapper.dart';
import 'package:httpbot_api/features/postman/presentation/widget/postman_request_method_chip.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_variable_store.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/request_editor_sheet.dart';

class PostmanRequestItem extends StatelessWidget {
  const PostmanRequestItem({
    super.key,
    required this.request,
  });

  final PostmanRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const mapper = PostmanRequestToRequestDraftMapper();

    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await showRequestEditorSheet(
            context,
            title: request.name.trim().isEmpty ? 'Untitled Request' : request.name,
            initialDraft: mapper(request),
            variableStore: const RequestVariableStore(),
          );
        },
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostmanRequestMethodChip(method: request.method),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.rawUrl,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: colors.divider,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
