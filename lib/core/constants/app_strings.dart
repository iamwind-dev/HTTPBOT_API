abstract final class AppStrings {
  static const appName = 'HTTPBot API';
  static const requestsTitle = 'Requests';
  static const requestsSearchHint = 'Search';
  static const requestsFavoriteTooltip = 'Favorite requests';
  static const requestsShowAllTooltip = 'Show all requests';
  static const requestsAddTooltip = 'Create request';
  static const requestsEmptyTitle = 'No requests yet';
  static const requestsEmptyMessage =
      'Create your first request to start testing APIs.';
  static const requestsNoResultsTitle = 'No matching requests';
  static const requestsNoResultsMessage =
      'Try a different search term or create a new request.';
  static const requestsNoFavouritesTitle = 'No favourite requests';
  static const requestsNoFavouritesMessage =
      'Mark a request as favourite to keep it here.';
  static const requestsImportHar = 'Import HAR';
  static const requestsImportCurl = 'Import curl';
  static const requestsNewRequest = 'New Request';
  static const requestEditorCloseTooltip = 'Close request editor';
  static const requestEditorQueryParams = 'Query Params';
  static const requestEditorHeaders = 'Headers';
  static const requestEditorBody = 'Body';
  static const requestEditorAuth = 'Auth';
  static const requestEditorMethod = 'Method';
  static const requestEditorOptions = 'Options';
  static const requestEditorTimeout = 'Timeout (seconds)';
  static const requestEditorVerifySsl = 'Verify SSL';
  static const requestEditorType = 'Type';
  static const requestEditorAdd = 'Add';
  static const requestEditorSend = 'Send';
  static const requestEditorBodyEmptyMessage =
      'This request does not send a body.';
  static const requestEditorUnsupportedAuthMessage =
      'This auth mode is modeled in the editor, but execution support is not implemented yet.';
  static const requestEditorApiKeyName = 'Key Name';
  static const requestEditorApiKeyCustomName = 'Custom Key Name';
  static const requestEditorApiKeyValue = 'Value';
  static const requestEditorApiKeyCustomOption = 'Custom';
  static const requestEditorApiKeySendAsHeader = 'Send as Header';
  static const requestEditorApiKeyManageCredentials = 'Manage Credentials';
  static const requestEditorApiKeyManageCredentialsNotImplemented =
      'Manage Credentials is not implemented yet.';
  static const requestEditorOAuth2Token = 'Token';
  static const requestEditorOAuth2AsHeader = 'As Header';
  static const requestEditorOAuth2HeaderPrefix = 'Header Prefix';
  static const requestEditorOAuth2Validity = 'Validity';
  static const requestEditorOAuth2NoExpiry = 'No expiry';
  static const requestEditorOAuth2Configure = 'Configure';
  static const requestEditorOAuth2Configuration = 'Configuration';
  static const requestEditorOAuth2GrantType = 'Grant Type';
  static const requestEditorOAuth2ImplementedLater =
      'This grant type will be implemented later.';
  static const requestEditorOAuth2AuthUrl = 'Auth URL';
  static const requestEditorOAuth2AccessTokenUrl = 'Access Token URL';
  static const requestEditorOAuth2ClientId = 'Client ID';
  static const requestEditorOAuth2ClientSecret = 'Client Secret';
  static const requestEditorOAuth2RedirectUri = 'Redirect URI';
  static const requestEditorOAuth2Scope = 'Scope';
  static const requestEditorOAuth2Advanced = 'Advanced';
  static const requestEditorOAuth2UsePkce = 'Use PKCE';
  static const requestEditorOAuth2PkceMethod = 'PKCE Method';
  static const requestEditorOAuth2State = 'State';
  static const requestEditorOAuth2ClientAuthentication =
      'Client Authentication';
  static const requestEditorOAuth2AuthUrlParams = 'Auth URL Params';
  static const requestEditorOAuth2TokenRequestParams = 'Token Request Params';
  static const requestEditorOAuth2RefreshTokenUrl = 'Refresh Token URL';
  static const requestEditorOAuth2RefreshTokenUrlHint =
      'Defaults to Access Token URL';
  static const requestEditorOAuth2AuthorizationCode = 'Authorization Code';
  static const requestEditorOAuth2GetAccessToken = 'Get Access Token';
  static const requestEditorOAuth2FlowFailed = 'Flow Failed';
  static const requestEditorOAuth2Status = 'Status';
  static const requestEditorOAuth2MalformedResponse =
      'The token response was malformed.';
  static const requestEditorOAuth2BuildUrlFailed =
      'Could not build authorize URL.';
  static const requestEditorOAuth2OpenBrowserFailed =
      'Could not open the authorize URL.';
  static const requestEditorOAuth2Username = 'Username';
  static const requestEditorOAuth2Password = 'Password';
  static const requestEditorOAuth2RequestingToken = 'Requesting token...';
  static const requestEditorOAuth2RedirectUriInvalid =
      'Redirect URI must be httpbot://oauth/callback.';
  static const requestEditorOAuth2AuthUrlParamsTitle = 'Auth URL Params';
  static const requestEditorOAuth2TokenRequestParamsTitle =
      'Token Request Params';
  static const requestEditorOAuth2ManualAuthorization =
      'Authorization callback is not implemented yet.';
  static const requestEditorOAuth2OpenAuthorizeUrl =
      'Open the authorize URL in your browser, then paste the returned code below.';
  static const requestEditorOAuth2CopyAuthorizeUrl = 'Copy URL';
  static const requestEditorOAuth2ExchangeCode = 'Exchange Code';
  static const requestEditorOAuth2WaitingForCallback =
      'Waiting for OAuth callback...';
  static const requestEditorOAuth2TokenDetailsTitle = 'Token Details';
  static const requestEditorOAuth2TokenAcquired = 'Access Token Acquired';
  static const requestEditorOAuth2ResolvedAuthUrl = 'Resolved Auth URL';
  static const requestEditorOAuth2TokenState = 'Token State';
  static const requestEditorOAuth2RequestTab = 'Request';
  static const requestEditorOAuth2ResponseTab = 'Response';
  static const requestEditorOAuth2Method = 'Method';
  static const requestEditorOAuth2Url = 'URL';
  static const requestEditorOAuth2Headers = 'Headers';
  static const requestEditorOAuth2Body = 'Body';
  static const requestEditorOAuth2AccessToken = 'Access Token';
  static const requestEditorOAuth2TokenType = 'Token Type';
  static const requestEditorOAuth2RefreshToken = 'Refresh Token';
  static const requestEditorOAuth2ExpiresIn = 'Expires In';
  static const requestEditorOAuth2Copied = 'Copied';
  static const requestEditorOAuth2NoValue = '—';
  static const cookiesTitle = 'Cookies';
  static const cookiesManageTitle = 'Manage Cookies';
  static const cookiesNoCookiesTitle = 'No Cookies';
  static const cookiesNoCookiesMessage =
      'No cookies found. Tap + to add a new cookie.';
  static const cookiesManageLink = 'Manage Cookies';
  static const cookiesAllDomains = 'All Domains';
  static const cookiesAddTitle = 'Add Cookie';
  static const cookiesEditTitle = 'Edit Cookie';
  static const cookiesName = 'Name';
  static const cookiesDomain = 'Domain';
  static const cookiesValue = 'Value';
  static const cookiesPath = 'Path';
  static const cookiesExpires = 'Expires';
  static const cookiesSameSite = 'SameSite';
  static const cookiesSession = 'Session';
  static const cookiesDeleteTitle = 'Delete Item?';
  static const cookiesDeleteMessage =
      'Are you sure you would like to delete this item?';
  static const cookiesDeleteAction = 'Delete';
  static const cookiesEditAction = 'Edit';
  static const cookiesSecure = 'Secure';
  static const cookiesHttpOnly = 'HttpOnly';
  static const cookiesEmptyManageMessage =
      'No cookies have been saved yet. Tap + to add a new cookie.';
  static const testsTitle = 'Tests';
  static const testsNoTestsTitle = 'No Tests';
  static const testsNoTestsMessage = 'Add tests to validate your API responses';
  static const testsAddTitle = 'New Test';
  static const testsEditTitle = 'Edit Test';
  static const testsDeleteTitle = 'Delete Item?';
  static const testsDeleteMessage =
      'Are you sure you would like to delete this item?';
  static const testsDeleteAction = 'Delete';
  static const testsEditAction = 'Edit';
  static const testsType = 'Test Type';
  static const testsTypePlaceholder = 'Select Test Type';
  static const testsComparator = 'Comparator';
  static const testsExpectedValue = 'Expected Value';
  static const testsMinValue = 'Min Value';
  static const testsMaxValue = 'Max Value';
  static const testsHeaderName = 'Header Name';
  static const testsCookieName = 'Cookie Name';
  static const testsJsonPath = 'JSON Path';
  static const testsXPath = 'XPath';
  static const testsTimeUnit = 'Time Unit';
  static const testsSizeUnit = 'Size Unit';
  static const testsCaseSensitive = 'Case-Sensitive';
  static const testsUpdateValue = 'Update Value';
  static const testsNoResultsTitle = 'No Tests Available';
  static const testsNoResultsMessage =
      'No tests have been created for this request';
  static const testsNoResponseRunMessage =
      'No tests were run for this request.';
  static const requestSettingsTitle = 'Settings';
  static const requestSettingsSavedResponsesInHistory =
      'Saved responses in history';
  static const requestSettingsTimeoutIntervalInSeconds =
      'Timeout Interval in Seconds';
  static const requestSettingsUserAgent = 'User-Agent';
  static const requestSettingsFollowRedirects = 'Follow Redirects';
  static const requestSettingsSendCookies = 'Send Cookies';
  static const requestSettingsStoreCookies = 'Store Cookies';
  static const requestSettingsVerifySsl = 'Verify SSL';
  static const requestSettingsSavedResponsesError =
      'Saved responses in history must be between 0 and 100.';
  static const requestSettingsTimeoutError =
      'Timeout must be between 1 and 600 seconds.';
  static const requestSettingsDisableSslWarning =
      'Disabling SSL verification is unsafe and should only be used for debugging.';
  static const requestResponseViewRequest = 'Request';
  static const requestResponseViewMetrics = 'Metrics';
  static const requestResponseViewTests = 'Tests';
  static const requestResponseViewCookies = 'Cookies';
  static const requestResponseViewHeaders = 'Headers';
  static const requestResponseViewBody = 'Body';
  static const requestResponseNoHeaders = 'No Headers';
  static const requestResponseNoCookies = 'No Cookies';
  static const requestResponseNoMetrics = 'No metrics available.';
  static const requestResponseNoRequestData = 'No request data available.';
  static const requestResponseRequestHeaders = 'Headers';
  static const requestResponseRequestBody = 'Body';
  static const requestResponseRequestBodyEmpty = '<empty>';
  static const requestResponseSentCookies = 'Sent Cookies';
  static const requestResponseReceivedCookies = 'Received Cookies';
  static const requestResponseStatus = 'Status';
  static const requestResponseSize = 'Size';
  static const requestResponseDuration = 'Duration';
  static const requestResponseMethod = 'Method';
  static const requestResponseUrl = 'URL';
  static const requestResponseCopiedRequest = 'Request copied.';
  static const requestResponseCopiedMetrics = 'Metrics copied.';
  static String requestResponseExchangeTitle(int index) => 'Request #$index';
  static const requestMetricUrl = 'URL';
  static const requestMetricMethod = 'HTTP Method';
  static const requestMetricResponseCode = 'Response Code';
  static const requestMetricProtocol = 'Protocol';
  static const requestMetricRemoteAddress = 'Remote Address';
  static const requestMetricTls = 'TLS';
  static const requestMetricKeptAlive = 'Kept Alive';
  static const requestMetricRequestHeaderSize = 'Request Header Size';
  static const requestMetricRequestSize = 'Request Size';
  static const requestMetricResponseHeaderSize = 'Response Header Size';
  static const requestMetricResponseSize = 'Response Size';
  static const requestMetricRequestStart = 'Request Start';
  static const requestMetricRequestEnd = 'Request End';
  static const requestMetricResponseStart = 'Response Start';
  static const requestMetricResponseEnd = 'Response End';
  static const requestMetricDnsLookupDuration = 'DNS Lookup Duration';
  static const requestMetricConnectDuration = 'Connect Duration';
  static const requestMetricTlsHandshake = 'TLS Handshake';
  static const requestMetricRequestDuration = 'Request Duration';
  static const requestMetricResponseDuration = 'Response Duration';
  static const filterResponseTitle = 'Filter Response';
  static const filterResponseCloseTooltip = 'Close filter response';
  static const filterResponseEmptyBody = 'No response body to filter.';
  static const filterResponseCopyResult = 'Copy Result';
  static const filterResponseCopyQuery = 'Copy Query';
  static const filterResponseResultCopied = 'Result copied.';
  static const filterResponseQueryCopied = 'Query copied.';
  static const filterResponseJqPlaceholder = 'Enter jq Query';
  static const filterResponseJsonPathPlaceholder = 'Enter JSONPath Query';
  static const filterResponseXPathPlaceholder = 'Enter XPath Query';
  static const filterResponseHelp = 'Help';
  static const filterResponseWrap = 'Wrap Response';
  static const filterResponseSaveQuery = 'Save Query';
  static const filterResponseManageQueries = 'Manage Queries';
  static const filterResponseSaveEmpty = 'Enter a query to save.';
  static const filterResponseSaved = 'Query saved.';
  static const filterResponseHelpTitle = 'Filter Help';
  static const filterResponseHelpBody =
      'jq        .headers.Host\n'
      'JSONPath  \$.headers.Host\n'
      'XPath     //item/name';
  static const responseFiltersTitle = 'Response Filters';
  static const responseFiltersEmptyTitle = 'No Saved Filters';
  static const responseFiltersEmptyMessage =
      'Save a query from Filter Response to reuse it later.';
  static const responseFilterEditorAddTitle = 'New Filter';
  static const responseFilterEditorEditTitle = 'Edit Filter';
  static const responseFilterNameLabel = 'Name';
  static const responseFilterQueryLabel = 'Query';
  static const responseFilterModeLabel = 'Mode';
  static const responseFilterNameRequired = 'Name is required.';
  static const responseFilterQueryRequired = 'Query is required.';
  static const responseFilterSave = 'Save';
  static const responseFilterDelete = 'Delete';
  static const historyTitle = 'History';
  static const historyCloseTooltip = 'Close history';
  static const historyEmptyTitle = 'No History';
  static const historyFooter =
      'The last 10 responses will be saved here. You can change this in the '
      'request settings.';
  static const savedCredentialsTitle = 'Saved Credentials';
  static const savedCredentialsEmptyTitle = 'No Saved Credentials';
  static const savedCredentialsEmptyMessage =
      "You haven't saved any credentials yet. Tap the '+' button to add one.";
  static const savedCredentialsDeleteAll = 'Delete All';
  static const createAuthTitle = 'Create Auth';
  static const createAuthNameHint = 'Enter Name';
  static const credentialsOnlyApiKeySupported =
      'Only API Key credentials are supported in this version.';
  static const requestResponseCloseTooltip = 'Close response viewer';
  static const requestResponseBodySelector = 'Body';
  static const requestsSoonMessage = 'This section is not available yet.';
  static const sectionUnavailableMessage = 'This section is not available yet.';
  static const requestsTabLabel = 'Requests';
  static const websocketsTabLabel = 'WebSockets';
  static const collectionsTabLabel = 'Collections';
  static const postmanTabLabel = 'Postman';
  static const settingsTabLabel = 'Settings';
  static const settingsTitle = 'Settings';
  static const settingsSectionSavedItems = 'Saved Items';
  static const settingsSectionPostman = 'Postman';
  static const settingsSectionHttpbot = 'HTTPBot';
  static const settingsRequestSettings = 'Request Settings';
  static const settingsDiskUsage = 'Disk Usage';
  static const settingsCookies = 'Cookies';
  static const settingsEnvironments = 'Environments';
  static const settingsGlobalVariables = 'Global Variables';
  static const settingsSavedAuth = 'Saved Auth';
  static const settingsResponseFilters = 'Response Filters';
  static const settingsResponseFiltersEmpty = 'No Saved Filters';
  static const settingsResponseFilterTitle = 'Response Filter';
  static const settingsResponseFilterNameHint = 'Enter a Name (Optional)';
  static const settingsResponseFilterType = 'Filter Type';
  static const settingsResponseFilterValue = 'Value';
  static const settingsResponseFilterDeleteAll = 'Delete All';
  static const settingsResponseFilterSaveQuery = 'Save Query';
  static const settingsResponseFilterManageQueries = 'Manage Queries';
  static const settingsResponseFilterWrapResponse = 'Wrap Response';
  static const settingsResponseFilterQueryRequired =
      'Filter query is required.';
  static const settingsResponseFilterUnableToSave = 'Unable to save filter.';
  static const settingsResponseFilterUnableToLoad = 'Unable to load filters.';
  static const settingsResponseFilterUnableToDelete =
      'Unable to delete filter.';
  static const settingsResponseFilterInvalidQuery = 'Invalid filter query.';
  static const settingsResponseFilterTextOnly =
      'Filtering only works on text responses.';
  static const settingsResponseFilterUnsupportedResponse =
      'This response cannot be filtered.';
  static const settingsResponseFilterUnsupportedType =
      'Unsupported filter type.';
  static const settingsResponseFilterDeleteTitle = 'Delete Filter';
  static const settingsResponseFilterDeleteMessage =
      'Are you sure you want to delete this filter?';
  static const settingsResponseFilterDeleteNote =
      'This saved filter will be removed.';
  static const settingsResponseFilterCancel = 'Cancel';
  static const settingsResponseFilterDelete = 'Delete';
  static const requestResponseFilterAction = 'Filter Response';
  static const settingsGraphql = 'GraphQL';
  static const settingsGraphqlQueries = 'Queries';
  static const settingsGraphqlVariables = 'Variables';
  static const settingsGraphqlSavedQueries = 'Saved Queries';
  static const settingsGraphqlSavedVariables = 'Saved Variables';
  static const settingsGraphqlNoSavedQueries = 'No Saved GraphQL Queries';
  static const settingsGraphqlNoSavedVariables = 'No Saved GraphQL Variables';
  static const settingsGraphqlQueryRequired = 'Query is required.';
  static const settingsGraphqlVariablesJsonInvalid =
      'Variables must be a valid JSON object.';
  static const settingsGraphqlVariablesJsonObject =
      'Variables must be a JSON object.';
  static const settingsGraphqlOperationName = 'Operation Name';
  static const settingsGraphqlViewSchema = 'View Schema';
  static const settingsGraphqlSaveQuery = 'Save Query';
  static const settingsGraphqlLoadQuery = 'Load Query';
  static const settingsGraphqlSaveVariables = 'Save Variables';
  static const settingsGraphqlLoadVariables = 'Load Variables';
  static const settingsGraphqlUnableToFetchSchema = 'Unable to fetch schema.';
  static const settingsGraphqlSchemaUnavailable =
      'Schema is not available for this endpoint.';
  static const settingsGraphqlHelp = 'GraphQL Help';
  static const settingsPostmanAccount = 'Postman Account';
  static const settingsDarkMode = 'Dark Mode';
  static const settingsMoreSettings = 'More Settings';
  static const settingsDetailUnavailableMessage =
      'This feature is not available yet.';
}
