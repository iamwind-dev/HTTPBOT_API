import '../../../../core/help/help_article.dart';
import '../../../../core/help/help_topic.dart';

const collectionsHelpArticle = HelpArticle(
  topic: HelpTopic.collectionsFolders,
  title: 'Collections & Folders',
  blocks: [
    HelpParagraphBlock([
      HelpInlineSegment('A '),
      HelpInlineSegment.bold('Collection'),
      HelpInlineSegment(
        ' is a named group of saved requests. Collections are how you keep '
        'your work organized in HTTPBot — group the endpoints for one API, '
        "one project, or one feature together so they're easy to find and "
        're-run.',
      ),
    ]),
    HelpParagraphBlock([
      HelpInlineSegment('Within a Collection you can nest '),
      HelpInlineSegment.bold('folders'),
      HelpInlineSegment(
        ' to add more structure and attach shared settings like '
        'Collection-level variables and authentication. Collections and their '
        'requests can also carry descriptions — typically brought in from an '
        'imported spec — that travel with the requests.',
      ),
    ]),
    HelpSectionTitleBlock('What a Collection can hold'),
    HelpBulletBlock([
      HelpInlineSegment.bold('Requests'),
      HelpInlineSegment(
        ' — the saved HTTP (and WebSocket) requests that make up your API '
        'workspace.',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Folders'),
      HelpInlineSegment(
        ' — optional sub-groups for organizing requests inside a Collection. '
        'Folders can be nested.',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Collection variables'),
      HelpInlineSegment(
        ' — key/value pairs scoped to the requests in this Collection. '
        "They're resolved as ",
      ),
      HelpInlineSegment.code('{{variables}}'),
      HelpInlineSegment(
        ' and sit between Global Variables and the active Environment in '
        'precedence. See ',
      ),
      HelpInlineSegment.link(
        'Environments & Variables',
        HelpTopic.environmentsVariables,
      ),
      HelpInlineSegment('.'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Collection-level authentication'),
      HelpInlineSegment(
        ' — a default auth configuration for the whole Collection. Individual '
        'requests can set their auth type to ',
      ),
      HelpInlineSegment.bold('Inherit'),
      HelpInlineSegment(
        ' to use it, so you configure credentials once and every request in '
        'the Collection picks them up. See ',
      ),
      HelpInlineSegment.link('Authentication', HelpTopic.authentication),
      HelpInlineSegment('.'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('A description / documentation'),
      HelpInlineSegment(
        ' — descriptive notes shown for the Collection and its requests. '
        'These are read-only in HTTPBot and usually come from an imported spec '
        '(such as an OpenAPI or Postman collection).',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Creating a Collection'),
    HelpNumberedBlock(1, [
      HelpInlineSegment('Open the '),
      HelpInlineSegment.bold('Collections'),
      HelpInlineSegment(' tab.'),
    ]),
    HelpNumberedBlock(2, [
      HelpInlineSegment('Tap the '),
      HelpInlineSegment.bold('+'),
      HelpInlineSegment(' floating action button in the bottom corner.'),
    ]),
    HelpNumberedBlock(3, [
      HelpInlineSegment('Choose '),
      HelpInlineSegment.bold('New Collection'),
      HelpInlineSegment('.'),
    ]),
    HelpNumberedBlock(4, [HelpInlineSegment('Give it a name and save.')]),
    HelpParagraphBlock([
      HelpInlineSegment('The same '),
      HelpInlineSegment.bold('+'),
      HelpInlineSegment(
        ' menu is also where you import existing API definitions — Postman '
        'collections, OpenAPI/Swagger specs, and HAR files. See ',
      ),
      HelpInlineSegment.link('Importing', HelpTopic.importing),
      HelpInlineSegment(' for those formats.'),
    ]),
    HelpParagraphBlock([
      HelpInlineSegment(
        "The collection editor is also where you attach a Collection's shared "
        'settings — its name, Collection variables, and Collection-level '
        'authentication.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Adding requests and folders'),
    HelpBulletBlock([
      HelpInlineSegment.bold('Add a request'),
      HelpInlineSegment(' to a Collection by saving a request into it.'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Add a folder'),
      HelpInlineSegment(
        ' to group related requests within the Collection. Folders can contain '
        'both requests and other folders.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Renaming, organizing, and deleting'),
    HelpBulletBlock([
      HelpInlineSegment.bold('Rename'),
      HelpInlineSegment(
        ' a Collection or folder to keep your structure tidy as a project '
        'grows.',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Organize'),
      HelpInlineSegment(
        ' by creating folders to break up a large flat list, then saving new '
        'requests directly into the folder where you want them.',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Delete'),
      HelpInlineSegment(
        ' a Collection, folder, or request when you no longer need it. '
        'Deleting a Collection removes the requests and folders it contains.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Searching'),
    HelpParagraphBlock([
      HelpInlineSegment(
        'Use the search field at the top of the Collections list to search '
        'across your Collections. This is the quickest way to jump to a '
        'specific endpoint when you have many Collections.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Collection-level authentication & Inherit'),
    HelpParagraphBlock([
      HelpInlineSegment(
        "Set authentication once on the Collection, then leave each request's "
        'auth type as ',
      ),
      HelpInlineSegment.bold('Inherit'),
      HelpInlineSegment(
        ". At send time, an inheriting request uses the Collection's auth "
        'configuration — so rotating a token or changing the auth type in one '
        'place updates every request that inherits it. You can still override '
        'auth on any individual request when an endpoint needs something '
        'different. Full details are in ',
      ),
      HelpInlineSegment.link('Authentication', HelpTopic.authentication),
      HelpInlineSegment('.'),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Request Documentation'),
    HelpParagraphBlock([
      HelpInlineSegment(
        "Every request can show its own documentation: the URL, description, "
        'and a summary of its headers, parameters, and body. Open it from the '
        "request's … menu → ",
      ),
      HelpInlineSegment.bold('View Documentation'),
      HelpInlineSegment(
        '. This is a convenient, read-only view to remind yourself how an '
        'endpoint is configured. Any description text shown here typically '
        'comes from an imported spec.',
      ),
    ]),
    HelpParagraphBlock([
      HelpInlineSegment(
        'Collections themselves can also carry a description, so when one is '
        'present the Collection and its requests together form lightweight '
        'reference docs.',
      ),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Two Collection areas: yours and Postman'),
    HelpParagraphBlock([
      HelpInlineSegment('HTTPBot keeps two separate areas for Collections:'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Collections'),
      HelpInlineSegment(
        ' — your own Collections, created in HTTPBot or imported from a file. '
        'You have full control to edit, organize, and run them.',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.bold('Postman'),
      HelpInlineSegment(
        ' — Collections synced live from a connected Postman account, '
        "organized by workspace. These mirror what's in your Postman cloud "
        'account.',
      ),
    ]),
    HelpParagraphBlock([
      HelpInlineSegment(
        'Browsing and importing Postman (and other) collections is free. ',
      ),
      HelpInlineSegment.bold(
        'Sending a request that lives in an imported or synced Collection '
        'requires HTTPBot Pro.',
      ),
      HelpInlineSegment(' '),
      HelpInlineSegment.proBadge(),
    ]),
    HelpCalloutBlock([
      HelpInlineSegment.bold('Requires HTTPBot Pro.'),
      HelpInlineSegment(
        ' Browsing imported/synced Collections is free; firing a request from '
        'one is a Pro feature.',
      ),
    ]),
    HelpParagraphBlock([
      HelpInlineSegment('See '),
      HelpInlineSegment.link('Importing', HelpTopic.importing),
      HelpInlineSegment(' to import files, or '),
      HelpInlineSegment.link('Postman Sync', HelpTopic.postmanSync),
      HelpInlineSegment(' to connect a Postman account.'),
    ]),
    HelpDividerBlock(),
    HelpSectionTitleBlock('Related'),
    HelpBulletBlock([
      HelpInlineSegment.link('Building a Request', HelpTopic.buildingRequest),
      HelpInlineSegment(
        ' — creating and editing the requests inside a Collection',
      ),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link('Authentication', HelpTopic.authentication),
      HelpInlineSegment(' — Collection-level auth and Inherit'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link(
        'Environments & Variables',
        HelpTopic.environmentsVariables,
      ),
      HelpInlineSegment(' — Collection variables and precedence'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link('Importing', HelpTopic.importing),
      HelpInlineSegment(' — bringing in external Collections from files'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link('Postman Sync', HelpTopic.postmanSync),
      HelpInlineSegment(' — connecting a live Postman account'),
    ]),
    HelpBulletBlock([
      HelpInlineSegment.link('Request Settings', HelpTopic.requestSettings),
      HelpInlineSegment(' — request settings and cookies'),
    ]),
  ],
);
