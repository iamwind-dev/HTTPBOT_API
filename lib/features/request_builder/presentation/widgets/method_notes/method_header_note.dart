import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme_context.dart';
import '../../../domain/entities/request_body_draft.dart';
import '../../../domain/entities/request_key_value.dart';
import '../../../domain/entities/requests_method.dart';

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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }

  String? get _message {
    if (method == HttpMethod.get) {
      return 'Content-Type will not be auto-added for GET.';
    }

    if (method != HttpMethod.post && method != HttpMethod.patch) {
      return null;
    }

    final suggestedContentType = switch (body.type) {
      RequestBodyType.xWwwFormUrlEncoded =>
        'application/x-www-form-urlencoded',
      RequestBodyType.formData => 'multipart/form-data',
      RequestBodyType.graphql => 'application/json',
      RequestBodyType.raw => body.raw.syncedContentType,
      RequestBodyType.none => null,
    };

    if (suggestedContentType == null) {
      return null;
    }

    if (_hasEnabledContentTypeHeader) {
      return 'Your enabled Content-Type header will be kept as-is.';
    }

    return 'Suggested Content-Type: $suggestedContentType. It will be auto-attached when sending.';
  }

  bool get _hasEnabledContentTypeHeader => headers.any(
    (header) =>
        header.isEnabled &&
        header.key.trim().toLowerCase() == 'content-type',
  );
}
