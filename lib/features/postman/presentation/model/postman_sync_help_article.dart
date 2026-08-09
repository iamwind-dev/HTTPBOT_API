import '../../../../core/help/help_article.dart';
import '../../../../core/help/help_topic.dart';

const postmanSyncHelpArticle = HelpArticle(
  topic: HelpTopic.postmanSync,
  title: 'Postman Sync',
  blocks: [
    HelpParagraphBlock([
      HelpInlineSegment('Instead of a one-off '),
      HelpInlineSegment.link('file import', HelpTopic.importing),
      HelpInlineSegment(
        ', you can connect your Postman account to browse your Postman cloud '
        'content and import the collections and environments you want. Linking '
        "your account doesn't sync everything automatically — you choose what "
        'to bring in, and the items you import then stay in sync with the '
        'cloud.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Connecting an account'),
    HelpNumberedBlock(1, [
      HelpInlineSegment('Go to '),
      HelpInlineSegment.bold('Settings → Postman Account'),
      HelpInlineSegment('.'),
    ]),
    HelpNumberedBlock(2, [
      HelpInlineSegment('Enter your Postman '),
      HelpInlineSegment.bold('API Key'),
      HelpInlineSegment('. Tap '),
      HelpInlineSegment.bold('Get API Key'),
      HelpInlineSegment(
        " if you need to create one — it opens Postman's site where you can "
        'generate a key.',
      ),
    ]),
    HelpNumberedBlock(3, [HelpInlineSegment('Link the account.')]),
    HelpParagraphBlock([
      HelpInlineSegment(
        'Once linked, you can browse your Postman content and import what you '
        'need. ',
      ),
      HelpInlineSegment.bold('Nothing is synced until you import it'),
      HelpInlineSegment(
        ' — linking only lets HTTPBot reach your workspaces so you can pick '
        'collections and environments to bring in:',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Collections'),
      HelpInlineSegment(' — open the separate '),
      HelpInlineSegment.bold('Postman'),
      HelpInlineSegment(
        ' area in Collections (kept apart from your own Collections) and tap ',
      ),
      HelpInlineSegment.bold('+'),
      HelpInlineSegment(
        ' to choose collections from a workspace to import. Imported '
        'collections then stay in sync with Postman, re-fetching the latest '
        'version when you open them.',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Environments'),
      HelpInlineSegment(" — use the Environments list's "),
      HelpInlineSegment.bold('+'),
      HelpInlineSegment(' menu → '),
      HelpInlineSegment.bold('Import from Postman...'),
      HelpInlineSegment(
        ' to import specific environments. Imported ones appear alongside '
        'your Local Environments. See ',
      ),
      HelpInlineSegment.link(
        'Environments & Variables',
        HelpTopic.environmentsVariables,
      ),
      HelpInlineSegment('.'),
    ]),
    HelpParagraphBlock([
      HelpInlineSegment(
        'Sending a request from a Postman-synced Collection requires HTTPBot '
        'Pro — see ',
      ),
      HelpInlineSegment.link('Importing', HelpTopic.importing),
      HelpInlineSegment(" for details on what's free versus Pro."),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Unlinking'),
    HelpParagraphBlock([
      HelpInlineSegment('Unlinking your Postman account from '),
      HelpInlineSegment.bold('Settings → Postman Account'),
      HelpInlineSegment(
        ' removes the imported collections and environments locally. Your '
        'content in Postman itself is untouched.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Related'),
    HelpBulletBlock([
      HelpInlineSegment.link('Importing', HelpTopic.importing),
      HelpInlineSegment(' — one-off file and spec imports'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link(
        'Collections & Folders',
        HelpTopic.collectionsFolders,
      ),
      HelpInlineSegment(' — your Collections vs. the Postman area'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link(
        'Environments & Variables',
        HelpTopic.environmentsVariables,
      ),
      HelpInlineSegment(' — Postman Environments and variable precedence'),
    ]),
  ],
);
