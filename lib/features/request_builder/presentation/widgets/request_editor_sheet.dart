import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../models/request_editor_response_badge_data.dart';
import '../models/request_editor_sheet_data.dart';
import 'request_modal_sheet.dart';
import 'request_response_sheet.dart';

/// Presents the request editor as a full-screen sheet that slides up from the bottom.
Future<void> showRequestEditorSheet(
  BuildContext context, {
  required RequestEditorSheetData data,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => _RequestEditorSheet(data: data),
);

class _RequestEditorSheet extends StatefulWidget {
  const _RequestEditorSheet({required this.data});

  final RequestEditorSheetData data;

  @override
  State<_RequestEditorSheet> createState() => _RequestEditorSheetState();
}

class _RequestEditorSheetState extends State<_RequestEditorSheet> {
  RequestEditorResponseBadgeData? _lastResponseBadge;

  /// Opens the response viewer and stores the latest response summary when it closes.
  Future<void> _openResponseSheet() async {
    final badgeData = await showRequestResponseSheet(
      context,
      requestData: widget.data,
    );

    if (!mounted || badgeData == null) {
      return;
    }

    setState(() {
      _lastResponseBadge = badgeData;
    });
  }

  /// Builds the floating editor card with iOS-style spacing and chrome.
  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsEditorSheet),
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.small),
        const _SheetHandle(),
        _EditorHeader(data: widget.data),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              0,
              AppSpacing.large,
              AppSpacing.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EditorUrlField(url: widget.data.url),
                const SizedBox(height: AppSpacing.large),
                const _EditorSectionTitle(
                  title: AppStrings.requestEditorQueryParams,
                ),
                const SizedBox(height: AppSpacing.small),
                const _AddRowCard(),
                const SizedBox(height: AppSpacing.large),
                const _EditorSectionTitle(title: AppStrings.requestEditorBody),
                const SizedBox(height: AppSpacing.small),
                _SelectionCard(
                  label: AppStrings.requestEditorType,
                  value: widget.data.bodyMode,
                ),
                const SizedBox(height: AppSpacing.large),
                const _EditorSectionTitle(
                  title: AppStrings.requestEditorHeaders,
                ),
                const SizedBox(height: AppSpacing.small),
                const _AddRowCard(),
                const SizedBox(height: AppSpacing.large),
                const _EditorSectionTitle(title: AppStrings.requestEditorAuth),
                const SizedBox(height: AppSpacing.small),
                _SelectionCard(
                  label: AppStrings.requestEditorAuth,
                  value: widget.data.authMode,
                ),
                const SizedBox(height: AppSpacing.xxxLarge),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            0,
            AppSpacing.large,
            AppSpacing.large,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _lastResponseBadge == null
                      ? const SizedBox.shrink()
                      : _ResponseBadge(data: _lastResponseBadge!),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              _SendButton(onPressed: _openResponseSheet),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  /// Draws the compact drag handle shown at the top of the sheet.
  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.xxLarge,
    height: AppSpacing.xxSmall,
    decoration: BoxDecoration(
      color: context.appColors.sheetHandle,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
    ),
  );
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.data});

  final RequestEditorSheetData data;

  /// Builds the top toolbar with close control and request identity.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey<String>(
              AppWidgetKeys.requestsEditorCloseButton,
            ),
            tooltip: AppStrings.requestEditorCloseTooltip,
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: colors.background,
              foregroundColor: colors.iconPrimary,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(CupertinoIcons.xmark, size: AppSpacing.large),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                _MethodBadge(method: data.method),
                Text(data.title, style: theme.textTheme.titleLarge),
                Icon(
                  CupertinoIcons.chevron_down_circle_fill,
                  color: colors.iconSecondary,
                  size: AppSpacing.large,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  /// Shows the request method using the shared method chip palette.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: colors.methodColor(method),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(method, style: theme.textTheme.labelMedium),
    );
  }
}

class _EditorUrlField extends StatelessWidget {
  const _EditorUrlField({required this.url});

  final String url;

  /// Renders the URL editor field prefilled from the tapped request.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextFormField(
      key: const ValueKey<String>(AppWidgetKeys.requestsEditorUrlField),
      initialValue: url,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'https://',
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.xxLarge),
          ),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.xxLarge),
          ),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.xxLarge),
          ),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}

class _EditorSectionTitle extends StatelessWidget {
  const _EditorSectionTitle({required this.title});

  final String title;

  /// Displays section labels with muted emphasis similar to native iOS forms.
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(color: context.appColors.textSecondary),
  );
}

class _AddRowCard extends StatelessWidget {
  const _AddRowCard();

  /// Shows the compact add row used by query params and headers.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.add_circled_solid,
              color: colors.navActive,
              size: AppSpacing.large,
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              AppStrings.requestEditorAdd,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.label, required this.value});

  final String label;
  final String value;

  /// Displays a single setting row for body mode and auth mode.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.navActive,
              ),
            ),
            const SizedBox(width: AppSpacing.xSmall),
            Icon(
              CupertinoIcons.chevron_up_chevron_down,
              color: colors.navActive,
              size: AppSpacing.medium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback onPressed;

  /// Draws the floating send affordance at the bottom of the editor.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      key: const ValueKey<String>(AppWidgetKeys.requestsEditorSendButton),
      color: colors.methodGet,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.xxLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Text(
            AppStrings.requestEditorSend,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colors.textOnPrimary),
          ),
        ),
      ),
    );
  }
}

class _ResponseBadge extends StatelessWidget {
  const _ResponseBadge({required this.data});

  final RequestEditorResponseBadgeData data;

  /// Shows the latest response summary in the editor footer after a send completes.
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return DecoratedBox(
      key: const ValueKey<String>(AppWidgetKeys.requestsEditorResponseBadge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.small,
              height: AppSpacing.small,
              decoration: BoxDecoration(
                color: colors.methodPost,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              data.displayLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
