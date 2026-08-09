import 'help_topic.dart';

class HelpArticle {
  const HelpArticle({
    required this.topic,
    required this.title,
    required this.blocks,
  });

  final HelpTopic topic;
  final String title;
  final List<HelpArticleBlock> blocks;
}

sealed class HelpArticleBlock {
  const HelpArticleBlock();
}

class HelpSectionTitleBlock extends HelpArticleBlock {
  const HelpSectionTitleBlock(this.text);

  final String text;
}

class HelpParagraphBlock extends HelpArticleBlock {
  const HelpParagraphBlock(this.content);

  final List<HelpInlineSegment> content;
}

class HelpBulletBlock extends HelpArticleBlock {
  const HelpBulletBlock(this.content);

  final List<HelpInlineSegment> content;
}

class HelpNumberedBlock extends HelpArticleBlock {
  const HelpNumberedBlock(this.number, this.content);

  final int number;
  final List<HelpInlineSegment> content;
}

class HelpDividerBlock extends HelpArticleBlock {
  const HelpDividerBlock();
}

class HelpCalloutBlock extends HelpArticleBlock {
  const HelpCalloutBlock(this.content);

  final List<HelpInlineSegment> content;
}

enum HelpInlineStyle { normal, bold, code, link, proBadge }

class HelpInlineSegment {
  const HelpInlineSegment(
    this.text, {
    this.style = HelpInlineStyle.normal,
    this.topic,
  });

  const HelpInlineSegment.bold(this.text)
    : style = HelpInlineStyle.bold,
      topic = null;

  const HelpInlineSegment.code(this.text)
    : style = HelpInlineStyle.code,
      topic = null;

  const HelpInlineSegment.link(this.text, this.topic)
    : style = HelpInlineStyle.link;

  const HelpInlineSegment.proBadge()
    : text = 'PRO',
      style = HelpInlineStyle.proBadge,
      topic = null;

  final String text;
  final HelpInlineStyle style;
  final HelpTopic? topic;
}
