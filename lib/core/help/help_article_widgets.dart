import 'package:flutter/material.dart';

import '../keys/widget_keys.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_context.dart';
import 'help_article.dart';
import 'help_topic.dart';

class HelpArticleBody extends StatelessWidget {
  const HelpArticleBody({
    super.key,
    required this.article,
    required this.onTopicTap,
  });

  final HelpArticle article;
  final ValueChanged<HelpTopic> onTopicTap;

  /// Renders structured article blocks using reusable documentation widgets.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          article.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 32),
        ),
        const SizedBox(height: AppSpacing.large),
        for (final block in article.blocks) _buildBlock(block),
      ],
    );
  }

  /// Maps one article block to its visual representation.
  Widget _buildBlock(HelpArticleBlock block) => switch (block) {
    HelpSectionTitleBlock(:final text) => HelpSectionTitle(text),
    HelpParagraphBlock(:final content) => HelpParagraph(
      content,
      onTopicTap: onTopicTap,
    ),
    HelpBulletBlock(:final content) => HelpBullet(
      content,
      onTopicTap: onTopicTap,
    ),
    HelpNumberedBlock(:final number, :final content) => HelpNumberedItem(
      number: number,
      content: content,
      onTopicTap: onTopicTap,
    ),
    HelpDividerBlock() => const HelpDivider(),
    HelpCalloutBlock(:final content) => HelpCallout(
      content,
      onTopicTap: onTopicTap,
    ),
  };
}

class HelpSectionTitle extends StatelessWidget {
  const HelpSectionTitle(this.text, {super.key});

  final String text;

  /// Displays a major article section heading with consistent spacing.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.small,
      bottom: AppSpacing.medium,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class HelpParagraph extends StatelessWidget {
  const HelpParagraph(this.content, {super.key, required this.onTopicTap});

  final List<HelpInlineSegment> content;
  final ValueChanged<HelpTopic> onTopicTap;

  /// Displays one article paragraph with inline formatting support.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
    child: HelpInlineText(content, onTopicTap: onTopicTap),
  );
}

class HelpBullet extends StatelessWidget {
  const HelpBullet(this.content, {super.key, required this.onTopicTap});

  final List<HelpInlineSegment> content;
  final ValueChanged<HelpTopic> onTopicTap;

  /// Displays one bulleted article item with wrapped inline content.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.small),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(
            Icons.circle,
            size: 6,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(child: HelpInlineText(content, onTopicTap: onTopicTap)),
      ],
    ),
  );
}

class HelpNumberedItem extends StatelessWidget {
  const HelpNumberedItem({
    super.key,
    required this.number,
    required this.content,
    required this.onTopicTap,
  });

  final int number;
  final List<HelpInlineSegment> content;
  final ValueChanged<HelpTopic> onTopicTap;

  /// Displays one numbered instruction while preserving responsive wrapping.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.small),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSpacing.large,
          child: Text(
            '$number.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: HelpInlineText(content, onTopicTap: onTopicTap)),
      ],
    ),
  );
}

class HelpDivider extends StatelessWidget {
  const HelpDivider({super.key});

  /// Separates major documentation sections using the active theme divider.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
    child: Divider(color: context.appColors.divider),
  );
}

class HelpInlineText extends StatelessWidget {
  const HelpInlineText(this.content, {super.key, required this.onTopicTap});

  final List<HelpInlineSegment> content;
  final ValueChanged<HelpTopic> onTopicTap;

  /// Builds mixed text, code, links, and badges without flattening the article.
  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (final segment in content)
            _buildSpan(context, segment, baseStyle),
        ],
      ),
    );
  }

  /// Converts one inline segment into a styled text or embedded widget span.
  InlineSpan _buildSpan(
    BuildContext context,
    HelpInlineSegment segment,
    TextStyle? baseStyle,
  ) => switch (segment.style) {
    HelpInlineStyle.normal => TextSpan(text: segment.text),
    HelpInlineStyle.bold => TextSpan(
      text: segment.text,
      style: baseStyle?.copyWith(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
    HelpInlineStyle.code => TextSpan(
      text: segment.text,
      style: baseStyle?.copyWith(
        color: context.appColors.codeLiteral,
        backgroundColor: context.appColors.surfaceMuted,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ),
    ),
    HelpInlineStyle.link => WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: HelpLink(
        label: segment.text,
        onTap: () => onTopicTap(segment.topic!),
      ),
    ),
    HelpInlineStyle.proBadge => const WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: ProBadge(),
    ),
  };
}

class HelpLink extends StatelessWidget {
  const HelpLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  /// Displays a safe, accessible inline documentation link.
  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.appColors.primary,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: context.appColors.primary,
        ),
      ),
    ),
  );
}

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  /// Displays the compact subscription badge used within article text.
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>(AppWidgetKeys.helpProBadge),
    margin: const EdgeInsets.only(left: AppSpacing.xxSmall),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: context.appColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      'PRO',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 11),
    ),
  );
}

class HelpCallout extends StatelessWidget {
  const HelpCallout(this.content, {super.key, required this.onTopicTap});

  final List<HelpInlineSegment> content;
  final ValueChanged<HelpTopic> onTopicTap;

  /// Displays Pro information in an outlined card with a blue accent edge.
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>(AppWidgetKeys.helpProCallout),
    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
    decoration: BoxDecoration(
      color: context.appColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      boxShadow: [
        BoxShadow(
          color: context.appColors.modalShadow,
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Container(
      margin: const EdgeInsets.only(left: AppSpacing.xxSmall),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(AppRadius.medium),
        ),
        border: Border.all(color: context.appColors.border),
      ),
      child: HelpInlineText(content, onTopicTap: onTopicTap),
    ),
  );
}
