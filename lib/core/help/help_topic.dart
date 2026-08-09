enum HelpTopic {
  collectionsFolders,
  buildingRequest,
  authentication,
  environmentsVariables,
  importing,
  postmanSync,
  requestSettings,
}

extension HelpTopicLabel on HelpTopic {
  String get label => switch (this) {
    HelpTopic.collectionsFolders => 'Collections & Folders',
    HelpTopic.buildingRequest => 'Building a Request',
    HelpTopic.authentication => 'Authentication',
    HelpTopic.environmentsVariables => 'Environments & Variables',
    HelpTopic.importing => 'Importing',
    HelpTopic.postmanSync => 'Postman Sync',
    HelpTopic.requestSettings => 'Request Settings',
  };
}
