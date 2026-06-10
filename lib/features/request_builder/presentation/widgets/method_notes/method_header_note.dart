import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme_context.dart';
import '../../../domain/entities/request_body_draft.dart';
import '../../../domain/entities/request_key_value.dart';
import '../../../domain/entities/requests_method.dart';
import '../../../domain/helpers/body_content_type_policy.dart';
import '../../../domain/helpers/header_method_policy.dart';

class MethodHeaderNote extends StatelessWidget {
  const MethodHeaderNote({
    super.key,
    required this.method,
    required this.body,
    required this.headers,
  });

  final HttpMethod method;
  final RequestBodyDraft body;
  final List<KeyValueItem> headers;

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.appColors.textSecondary),
      ),
    );
  }

  String? get _message {
    if (!shouldAutoAttachContentTypeForMethod(method)) {
      return 'Content-Type will not be auto-added for ${method.wireName}.';
    }

    final suggestedContentType = contentTypeForBodyType(body.type);

    if (suggestedContentType == null) {
      return null;
    }

    if (_hasEnabledContentTypeHeader) {
      return 'Your enabled Content-Type header will be kept as-is.';
    }

    return 'Suggested Content-Type: $suggestedContentType. It will be synced into Headers automatically.';
  }

  bool get _hasEnabledContentTypeHeader => headers.any(
    (header) =>
        header.isEnabled && header.key.trim().toLowerCase() == 'content-type',
  );
}
