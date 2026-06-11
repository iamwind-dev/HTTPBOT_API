import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/oauth2_token_details_entity.dart';
import '../../domain/helpers/oauth2_token_details_masker.dart';
import 'request_modal_sheet.dart';

/// Opens the OAuth2 token details sheet after a successful token exchange.
Future<void> showOAuth2TokenDetailsSheet(
  BuildContext context, {
  required OAuth2TokenDetailsEntity tokenDetails,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => OAuth2TokenDetailsSheet(tokenDetails: tokenDetails),
);

class OAuth2TokenDetailsSheet extends StatefulWidget {
  const OAuth2TokenDetailsSheet({super.key, required this.tokenDetails});

  final OAuth2TokenDetailsEntity tokenDetails;

  @override
  State<OAuth2TokenDetailsSheet> createState() =>
      _OAuth2TokenDetailsSheetState();
}

enum _OAuth2TokenDetailsSegment { request, response }

class _OAuth2TokenDetailsSheetState extends State<OAuth2TokenDetailsSheet> {
  _OAuth2TokenDetailsSegment _segment = _OAuth2TokenDetailsSegment.request;

  /// Copies the resolved authorization URL and confirms the action with a snackbar.
  Future<void> _copyResolvedAuthUrl() async {
    await Clipboard.setData(
      ClipboardData(text: widget.tokenDetails.resolvedAuthUrl),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.requestEditorOAuth2Copied)),
    );
  }

  /// Switches the details sheet between request and response tabs.
  void _selectSegment(_OAuth2TokenDetailsSegment? segment) {
    if (segment == null) {
      return;
    }

    setState(() {
      _segment = segment;
    });
  }

  /// Builds the request or response section selected by the segmented control.
  Widget _buildSegmentContent() => switch (_segment) {
    _OAuth2TokenDetailsSegment.request => _OAuth2RequestDebugView(
      details: widget.tokenDetails,
    ),
    _OAuth2TokenDetailsSegment.response => _OAuth2ResponseDebugView(
      details: widget.tokenDetails,
    ),
  };

  /// Builds the token details success sheet.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(
      AppWidgetKeys.requestsEditorOAuth2TokenDetailsSheet,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.requestEditorOAuth2TokenDetailsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TokenSectionTitle(
                    title: AppStrings.requestEditorOAuth2Status,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  const _OAuth2StatusCard(),
                  const SizedBox(height: AppSpacing.large),
                  _ResolvedAuthUrlCard(
                    resolvedAuthUrl: widget.tokenDetails.resolvedAuthUrl,
                    onCopy: _copyResolvedAuthUrl,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _OAuth2TokenStateCard(details: widget.tokenDetails),
                  const SizedBox(height: AppSpacing.large),
                  const _TokenSectionTitle(title: 'Segment'),
                  const SizedBox(height: AppSpacing.small),
                  _OAuth2SegmentedControl(
                    segment: _segment,
                    onChanged: _selectSegment,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _buildSegmentContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OAuth2StatusCard extends StatelessWidget {
  const _OAuth2StatusCard();

  /// Builds the success status card shown at the top of the token details sheet.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildSheetCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: context.appColors.methodGet,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              AppStrings.requestEditorOAuth2TokenAcquired,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResolvedAuthUrlCard extends StatelessWidget {
  const _ResolvedAuthUrlCard({
    required this.resolvedAuthUrl,
    required this.onCopy,
  });

  final VoidCallback onCopy;
  final String resolvedAuthUrl;

  /// Builds the resolved authorization URL card with copy action.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _TokenSectionTitle(
        title: AppStrings.requestEditorOAuth2ResolvedAuthUrl,
      ),
      const SizedBox(height: AppSpacing.small),
      DecoratedBox(
        decoration: _buildSheetCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(resolvedAuthUrl),
              const SizedBox(height: AppSpacing.medium),
              Divider(color: context.appColors.border),
              const SizedBox(height: AppSpacing.small),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey<String>(
                    AppWidgetKeys.requestsEditorOAuth2TokenDetailsCopyUrlButton,
                  ),
                  onPressed: onCopy,
                  icon: const Icon(CupertinoIcons.doc_on_doc),
                  label: const Text(
                    AppStrings.requestEditorOAuth2CopyAuthorizeUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _OAuth2TokenStateCard extends StatelessWidget {
  const _OAuth2TokenStateCard({required this.details});

  final OAuth2TokenDetailsEntity details;

  /// Builds the masked token state summary card.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _TokenSectionTitle(title: AppStrings.requestEditorOAuth2TokenState),
      const SizedBox(height: AppSpacing.small),
      DecoratedBox(
        decoration: _buildSheetCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              _TokenDetailRow(
                label: AppStrings.requestEditorOAuth2AccessToken,
                value: maskSecret(details.accessToken, visiblePrefix: 10),
              ),
              _TokenDetailRow(
                label: AppStrings.requestEditorOAuth2TokenType,
                value: details.resolvedTokenType,
              ),
              _TokenDetailRow(
                label: AppStrings.requestEditorOAuth2Scope,
                value: details.scope.trim().isEmpty
                    ? AppStrings.requestEditorOAuth2NoValue
                    : details.scope,
              ),
              _TokenDetailRow(
                label: AppStrings.requestEditorOAuth2RefreshToken,
                value: maskSecret(details.refreshToken ?? ''),
              ),
              if (details.expiresIn != null)
                _TokenDetailRow(
                  label: AppStrings.requestEditorOAuth2ExpiresIn,
                  value: '${details.expiresIn}s',
                )
              else
                const _TokenDetailRow(
                  label: AppStrings.requestEditorOAuth2Validity,
                  value: AppStrings.requestEditorOAuth2NoExpiry,
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _OAuth2SegmentedControl extends StatelessWidget {
  const _OAuth2SegmentedControl({
    required this.segment,
    required this.onChanged,
  });

  final ValueChanged<_OAuth2TokenDetailsSegment?> onChanged;
  final _OAuth2TokenDetailsSegment segment;

  /// Builds the request-response segmented control for the token details sheet.
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoSlidingSegmentedControl<_OAuth2TokenDetailsSegment>(
      key: const ValueKey<String>(
        AppWidgetKeys.requestsEditorOAuth2TokenDetailsSegmentedControl,
      ),
      groupValue: segment,
      onValueChanged: onChanged,
      children: const <_OAuth2TokenDetailsSegment, Widget>{
        _OAuth2TokenDetailsSegment.request: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.small,
          ),
          child: Text(AppStrings.requestEditorOAuth2RequestTab),
        ),
        _OAuth2TokenDetailsSegment.response: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.small,
          ),
          child: Text(AppStrings.requestEditorOAuth2ResponseTab),
        ),
      },
    ),
  );
}

class _OAuth2RequestDebugView extends StatelessWidget {
  const _OAuth2RequestDebugView({required this.details});

  final OAuth2TokenDetailsEntity details;

  /// Builds the token endpoint request debug view with masked headers and form body.
  @override
  Widget build(BuildContext context) {
    final maskedHeaders = <String, String>{
      for (final entry in details.request.headers.entries)
        entry.key: entry.key.trim().toLowerCase() == 'authorization'
            ? maskAuthorizationHeaderValue(entry.value)
            : entry.value,
    };
    final maskedBodyFields = maskSensitiveBodyFields(
      details.request.bodyFields,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TokenDetailsCard(
          child: Column(
            children: [
              _TokenDetailRow(
                label: AppStrings.requestEditorOAuth2Method,
                value: details.request.method,
              ),
              _TokenDetailRow(
                label: AppStrings.requestEditorOAuth2Url,
                value: details.request.url,
                multiline: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        _KeyValueSectionCard(
          title: AppStrings.requestEditorOAuth2Headers,
          values: maskedHeaders,
        ),
        const SizedBox(height: AppSpacing.small),
        _TextSectionCard(
          title: AppStrings.requestEditorOAuth2Body,
          value: buildEncodedBodyPreview(maskedBodyFields),
        ),
      ],
    );
  }
}

class _OAuth2ResponseDebugView extends StatelessWidget {
  const _OAuth2ResponseDebugView({required this.details});

  final OAuth2TokenDetailsEntity details;

  /// Builds the token endpoint response debug view with masked headers and masked body preview.
  @override
  Widget build(BuildContext context) {
    final responseJsonBody = details.response.jsonBody;
    final maskedBody = responseJsonBody == null
        ? details.response.rawBody
        : buildPrettyMaskedJson(responseJsonBody);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyValueSectionCard(
          title: AppStrings.requestEditorOAuth2Headers,
          values: details.response.headers,
          leadingRows: details.response.statusCode == null
              ? const <MapEntry<String, String>>[]
              : <MapEntry<String, String>>[
                  MapEntry(
                    AppStrings.requestEditorOAuth2Status,
                    '${details.response.statusCode}',
                  ),
                ],
        ),
        const SizedBox(height: AppSpacing.small),
        _TextSectionCard(
          title: AppStrings.requestEditorOAuth2Body,
          value: maskedBody.trim().isEmpty
              ? AppStrings.requestEditorOAuth2NoValue
              : maskedBody,
          monospace: true,
        ),
      ],
    );
  }
}

class _KeyValueSectionCard extends StatelessWidget {
  const _KeyValueSectionCard({
    required this.title,
    required this.values,
    this.leadingRows = const <MapEntry<String, String>>[],
  });

  final List<MapEntry<String, String>> leadingRows;
  final String title;
  final Map<String, String> values;

  /// Builds a card that renders one flat map of key-value data.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _TokenSectionTitle(title: title),
      const SizedBox(height: AppSpacing.small),
      _TokenDetailsCard(
        child: Column(
          children: [
            for (final entry in leadingRows)
              _TokenDetailRow(label: entry.key, value: entry.value),
            if (values.isEmpty && leadingRows.isEmpty)
              const _TokenDetailRow(
                label: '',
                value: AppStrings.requestEditorOAuth2NoValue,
              )
            else
              for (final entry in values.entries)
                _TokenDetailRow(
                  label: entry.key,
                  value: entry.value.isEmpty
                      ? AppStrings.requestEditorOAuth2NoValue
                      : entry.value,
                  multiline: true,
                  boldLabel: true,
                ),
          ],
        ),
      ),
    ],
  );
}

class _TextSectionCard extends StatelessWidget {
  const _TextSectionCard({
    required this.title,
    required this.value,
    this.monospace = false,
  });

  final bool monospace;
  final String title;
  final String value;

  /// Builds a multiline text card for encoded form bodies and JSON response bodies.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _TokenSectionTitle(title: title),
      const SizedBox(height: AppSpacing.small),
      _TokenDetailsCard(
        child: SelectionArea(
          child: Text(
            value,
            style: monospace
                ? Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    ],
  );
}

class _TokenDetailsCard extends StatelessWidget {
  const _TokenDetailsCard({required this.child});

  final Widget child;

  /// Wraps token detail content in the shared rounded card styling.
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _buildSheetCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class _TokenDetailRow extends StatelessWidget {
  const _TokenDetailRow({
    required this.label,
    required this.value,
    this.boldLabel = false,
    this.multiline = false,
  });

  final bool boldLabel;
  final String label;
  final bool multiline;
  final String value;

  /// Builds a compact label-value row for token details cards.
  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      maxLines: multiline ? null : 2,
      overflow: multiline ? null : TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: context.appColors.textSecondary,
        fontFamily: multiline ? 'monospace' : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: boldLabel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Flexible(
            child: multiline ? SelectionArea(child: valueWidget) : valueWidget,
          ),
        ],
      ),
    );
  }
}

class _TokenSectionTitle extends StatelessWidget {
  const _TokenSectionTitle({required this.title});

  final String title;

  /// Builds the muted section heading used throughout the token details sheet.
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: context.appColors.textSecondary),
  );
}

BoxDecoration _buildSheetCardDecoration(BuildContext context) => BoxDecoration(
  color: context.appColors.surfaceMuted,
  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
  border: Border.all(color: context.appColors.border),
);
