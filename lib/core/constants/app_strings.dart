abstract final class AppStrings {
  static const appName = 'HTTPBot API';
  static const requestsTitle = 'Requests';
  static const requestsSearchHint = 'Search';
  static const requestsFavoriteTooltip = 'Favorite requests';
  static const requestsAddTooltip = 'Create request';
  static const requestsEmptyTitle = 'No requests yet';
  static const requestsEmptyMessage =
      'Create your first request to start testing APIs.';
  static const requestsNoResultsTitle = 'No matching requests';
  static const requestsNoResultsMessage =
      'Try a different search term or create a new request.';
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
  static const testsNoTestsMessage =
      'Add tests to validate your API responses';
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
  static const testsNoResponseRunMessage = 'No tests were run for this request.';
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
  static const requestResponseNoMetrics = 'No Metrics';
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
  static const settingsGraphql = 'GraphQL';
  static const settingsPostmanAccount = 'Postman Account';
  static const settingsDarkMode = 'Dark Mode';
  static const settingsMoreSettings = 'More Settings';
  static const settingsDetailUnavailableMessage =
      'This feature is not available yet.';
}
