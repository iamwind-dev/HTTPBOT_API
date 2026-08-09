abstract final class AppWidgetKeys {
  static const requestsSearchField = 'requests_search_field';
  static const requestsFavoriteButton = 'requests_favorite_button';
  static const requestsFab = 'requests_fab';
  static const websocketsFab = 'websockets_fab';
  static const websocketsUrlField = 'websockets_url_field';
  static const websocketsConnectButton = 'websockets_connect_button';
  static const websocketsMessageField = 'websockets_message_field';
  static const websocketsSendButton = 'websockets_send_button';
  static const websocketsBinaryButton = 'websockets_binary_button';
  static const websocketsTimeoutField = 'websockets_timeout_field';
  static const websocketsVerifySslSwitch = 'websockets_verify_ssl_switch';
  static const websocketsAuthTypeField = 'websockets_auth_type_field';
  static const websocketsBasicUsernameField = 'websockets_basic_username_field';
  static const websocketsBasicPasswordField = 'websockets_basic_password_field';
  static const collectionsFab = 'collections_fab';
  static const collectionsDetailFab = 'collections_detail_fab';
  static const collectionsSearchField = 'collections_search_field';
  static const collectionsNewCollectionNameField =
      'collections_new_collection_name_field';
  static const collectionsNewCollectionSaveButton =
      'collections_new_collection_save_button';
  static const collectionsNewCollectionCloseButton =
      'collections_new_collection_close_button';
  static const collectionsNewCollectionAction =
      'collections_new_collection_action';
  static const collectionsNewCollectionAuthTypeField =
      'collections_new_collection_auth_type_field';
  static const collectionsMoreButton = 'collections_more_button';
  static const collectionsHelpMenuAction = 'collections_help_menu_action';
  static const postmanMoreButton = 'postman_more_button';
  static const postmanHelpMenuAction = 'postman_help_menu_action';
  static const helpCloseButton = 'help_close_button';
  static const helpProBadge = 'help_pro_badge';
  static const helpProCallout = 'help_pro_callout';

  static String helpPage(String topic) => 'help_page_$topic';

  static String helpScrollView(String topic) => 'help_scroll_view_$topic';
  static const collectionsDetailMenuSheet = 'collections_detail_menu_sheet';
  static const collectionsDetailNewFolderAction =
      'collections_detail_new_folder_action';
  static const collectionsDetailNewRequestAction =
      'collections_detail_new_request_action';
  static const collectionsDetailImportCurlAction =
      'collections_detail_import_curl_action';
  static const collectionsNewFolderNameField =
      'collections_new_folder_name_field';
  static const collectionsNewFolderCreateButton =
      'collections_new_folder_create_button';
  static const postmanFab = 'postman_fab';
  static const requestsListItemPrefix = 'requests_list_item';
  static const requestsEditorSheet = 'requests_editor_sheet';
  static const requestsEditorCloseButton = 'requests_editor_close_button';
  static const requestsEditorMoreButton = 'requests_editor_more_button';
  static const requestsEditorTitleField = 'requests_editor_title_field';
  static const requestsEditorUrlField = 'requests_editor_url_field';
  static const requestsEditorMethodField = 'requests_editor_method_field';
  static const requestsEditorBodyModeField = 'requests_editor_body_mode_field';
  static const requestsEditorAuthTypeField = 'requests_editor_auth_type_field';
  static const requestsEditorTimeoutField = 'requests_editor_timeout_field';
  static const requestsEditorVerifySslSwitch =
      'requests_editor_verify_ssl_switch';
  static const requestsEditorRawBodyAction = 'requests_editor_raw_body_action';
  static const requestsEditorRawBodyEditor = 'requests_editor_raw_body_editor';
  static const requestsEditorRawSubtypeField =
      'requests_editor_raw_subtype_field';
  static const requestsEditorGraphQlQueryField =
      'requests_editor_graphql_query_field';
  static const requestsEditorGraphQlVariablesField =
      'requests_editor_graphql_variables_field';
  static const requestsEditorFormDataFileSelector =
      'requests_editor_form_data_file_selector';
  static const requestsEditorSendButton = 'requests_editor_send_button';
  static const requestsEditorResponseBadge = 'requests_editor_response_badge';
  static const requestsCookiesSheet = 'requests_cookies_sheet';
  static const requestsCookiesManageSheet = 'requests_cookies_manage_sheet';
  static const requestsCookieEditorSheet = 'requests_cookie_editor_sheet';
  static const requestsCookiesAddButton = 'requests_cookies_add_button';
  static const requestsCookiesManageButton = 'requests_cookies_manage_button';
  static const requestsCookiesCloseButton = 'requests_cookies_close_button';
  static const requestsCookiesFilterButton = 'requests_cookies_filter_button';
  static const requestsTestsSheet = 'requests_tests_sheet';
  static const requestsTestEditorSheet = 'requests_test_editor_sheet';
  static const requestsTestValueEditorSheet =
      'requests_test_value_editor_sheet';
  static const requestsTestsAddButton = 'requests_tests_add_button';
  static const requestsTestsCloseButton = 'requests_tests_close_button';
  static const requestsSettingsSheet = 'requests_settings_sheet';
  static const requestsSettingsCloseButton = 'requests_settings_close_button';
  static const requestsResponseViewSelectorButton =
      'requests_response_view_selector_button';
  static const requestsResponseViewSelectorMenu =
      'requests_response_view_selector_menu';
  static const requestsResponseSheet = 'requests_response_sheet';
  static const requestsResponseCloseButton = 'requests_response_close_button';
  static const requestsResponseSendButton = 'requests_response_send_button';
  static const requestsResponseSummaryBadge = 'requests_response_summary_badge';
  static const requestsResponseRawRequestCard =
      'requests_response_raw_request_card';
  static const requestsResponseShareButton = 'requests_response_share_button';
  static const requestsResponseWrapButton = 'requests_response_wrap_button';
  static const requestsResponseFilterButton = 'requests_response_filter_button';

  static const filterResponseSheet = 'filter_response_sheet';
  static const filterResponseCloseButton = 'filter_response_close_button';
  static const filterResponseMoreButton = 'filter_response_more_button';
  static const filterResponseQueryField = 'filter_response_query_field';
  static const filterResponseModePicker = 'filter_response_mode_picker';
  static const requestsResponseFilterMenuButton = filterResponseMoreButton;

  static String filterResponseModeOption(String mode) =>
      'filter_response_mode_option_$mode';

  static String filterResponseToken(String token) =>
      'filter_response_token_$token';

  static const responseFiltersSheet = 'response_filters_sheet';
  static const responseFiltersAddButton = 'response_filters_add_button';
  static const responseFilterEditorSheet = 'response_filter_editor_sheet';
  static const responseFilterEditorNameField =
      'response_filter_editor_name_field';
  static const responseFilterEditorQueryField =
      'response_filter_editor_query_field';
  static const responseFilterEditorSaveButton =
      'response_filter_editor_save_button';

  static String responseFilterListItemAt(int index) =>
      'response_filter_item_$index';

  static const requestHistorySheet = 'request_history_sheet';
  static const requestHistoryCloseButton = 'request_history_close_button';

  static String requestHistoryItemAt(int index) =>
      'request_history_item_$index';
  static const viewCurlSheet = 'view_curl_sheet';
  static const viewCurlCloseButton = 'view_curl_close_button';
  static const viewCurlShareButton = 'view_curl_share_button';
  static const settingsList = 'settings_list';
  static const settingsBackButton = 'settings_back_button';
  static const settingsThemeModeSwitch = 'settings_theme_mode_switch';
  static const settingsGraphQlSegmentedControl =
      'settings_graphql_segmented_control';
  static const settingsGraphQlAddButton = 'settings_graphql_add_button';
  static const settingsGraphQlHelpButton = 'settings_graphql_help_button';
  static const settingsGraphQlEmptyState = 'settings_graphql_empty_state';
  static const settingsGraphQlEditorNameField =
      'settings_graphql_editor_name_field';
  static const settingsGraphQlEditorValueField =
      'settings_graphql_editor_value_field';
  static const settingsGraphQlEditorOperationNameField =
      'settings_graphql_editor_operation_name_field';
  static const settingsResponseFiltersEmptyState =
      'settings_response_filters_empty_state';
  static const settingsResponseFiltersAddButton =
      'settings_response_filters_add_button';
  static const settingsResponseFiltersMoreButton =
      'settings_response_filters_more_button';
  static const settingsResponseFiltersSheet = 'settings_response_filters_sheet';
  static const settingsResponseFilterNameField =
      'settings_response_filter_name_field';
  static const settingsResponseFilterTypeField =
      'settings_response_filter_type_field';
  static const settingsResponseFilterValueField =
      'settings_response_filter_value_field';
  static const requestsTab = 'requests_tab';
  static const websocketsTab = 'websockets_tab';
  static const websocketsList = 'websockets_list';
  static const collectionsTab = 'collections_tab';
  static const postmanTab = 'postman_tab';
  static const settingsTab = 'settings_tab';

  /// Builds a stable key for a request list item by index.
  static String requestsListItemAt(int index) =>
      '${requestsListItemPrefix}_$index';

  /// Builds a stable key for a section add button inside the request editor.
  static String requestsEditorSectionAddButton(String section) =>
      'requests_editor_${section}_add_button';

  /// Builds a stable key for a toggleable key-value row checkbox in the editor.
  static String requestsEditorKeyValueToggle(String section, int index) =>
      'requests_editor_${section}_${index}_toggle';

  /// Builds a stable key for a key input inside a key-value editor row.
  static String requestsEditorKeyValueKeyField(String section, int index) =>
      'requests_editor_${section}_${index}_key_field';

  /// Builds a stable key for a value input inside a key-value editor row.
  static String requestsEditorKeyValueValueField(String section, int index) =>
      'requests_editor_${section}_${index}_value_field';

  /// Builds a stable key for a remove button inside a key-value editor row.
  static String requestsEditorKeyValueRemoveButton(String section, int index) =>
      'requests_editor_${section}_${index}_remove_button';

  /// Builds a stable key for an inline option inside a key-value editor row.
  static String requestsEditorKeyValueOptionField(String section, int index) =>
      'requests_editor_${section}_${index}_option_field';

  /// Builds a stable key for a row-level action inside a key-value editor row.
  static String requestsEditorKeyValueActionButton(String section, int index) =>
      'requests_editor_${section}_${index}_action_button';

  /// Builds a stable key for an auth credential field keyed by semantic name.
  static String requestsEditorAuthField(String fieldName) =>
      'requests_editor_auth_${fieldName}_field';

  /// Builds a stable key for a WebSocket auth credential field.
  static String websocketsAuthField(String fieldName) =>
      'websockets_auth_${fieldName}_field';

  /// Builds a stable key for the active WebSocket auth-mode field subtree.
  static String websocketsAuthFields(String authType) =>
      'websockets_auth_${authType}_fields';

  static String requestsCookieField(String fieldName) =>
      'requests_cookie_${fieldName}_field';

  static String requestsCookieListItemAt(int index) =>
      'requests_cookie_item_$index';

  static String requestsTestField(String fieldName) =>
      'requests_test_${fieldName}_field';

  static String requestsTestListItemAt(int index) =>
      'requests_test_item_$index';

  static String requestsSettingsField(String fieldName) =>
      'requests_settings_${fieldName}_field';

  static String requestsResponseViewSelectorItem(String mode) =>
      'requests_response_view_selector_item_$mode';

  static String settingsGraphQlListItemAt(String section, int index) =>
      'settings_graphql_${section}_item_$index';

  static String settingsResponseFilterListItemAt(int index) =>
      'settings_response_filter_item_$index';

  static String requestsResponseMetricsExchangeAt(int index) =>
      'requests_response_metrics_exchange_$index';

  static const requestsEditorManageCredentialsButton =
      'requests_editor_manage_credentials_button';
  static const requestsEditorOAuth2AsHeaderSwitch =
      'requests_editor_oauth2_as_header_switch';
  static const requestsEditorOAuth2ConfigureButton =
      'requests_editor_oauth2_configure_button';
  static const requestsEditorOAuth2ConfigSheet =
      'requests_editor_oauth2_config_sheet';
  static const requestsEditorOAuth2ConfigDoneButton =
      'requests_editor_oauth2_config_done_button';
  static const requestsEditorOAuth2GetAccessTokenButton =
      'requests_editor_oauth2_get_access_token_button';
  static const requestsEditorOAuth2FlowFailedSheet =
      'requests_editor_oauth2_flow_failed_sheet';
  static const requestsEditorOAuth2AuthorizeAssistSheet =
      'requests_editor_oauth2_authorize_assist_sheet';
  static const requestsEditorOAuth2TokenDetailsSheet =
      'requests_editor_oauth2_token_details_sheet';
  static const requestsEditorOAuth2TokenDetailsCopyUrlButton =
      'requests_editor_oauth2_token_details_copy_url_button';
  static const requestsEditorOAuth2TokenDetailsSegmentedControl =
      'requests_editor_oauth2_token_details_segmented_control';
  static const savedCredentialsSheet = 'saved_credentials_sheet';
  static const savedCredentialsCloseButton = 'saved_credentials_close_button';
  static const savedCredentialsMoreButton = 'saved_credentials_more_button';
  static const savedCredentialsAddButton = 'saved_credentials_add_button';
  static const createAuthSheet = 'create_auth_sheet';
  static const createAuthCloseButton = 'create_auth_close_button';
  static const createAuthSaveButton = 'create_auth_save_button';
  static const createAuthNameField = 'create_auth_name_field';
  static const createAuthTypeField = 'create_auth_type_field';

  /// Builds a stable key for a saved credential list item by index.
  static String savedCredentialsItemAt(int index) =>
      'saved_credentials_item_$index';

  static const requestsEnvironmentMenuSheet = 'requests_environment_menu_sheet';
  static const requestsEnvironmentMenuGlobalVariables =
      'requests_environment_menu_global_variables';
  static const requestsEnvironmentMenuManage =
      'requests_environment_menu_manage';
  static const requestsEnvironmentMenuDeactivate =
      'requests_environment_menu_deactivate';
  static const requestsEnvironmentMenuEdit = 'requests_environment_menu_edit';
  static const globalVariablesSheet = 'global_variables_sheet';
  static const globalVariablesCloseButton = 'global_variables_close_button';
  static const globalVariablesSaveButton = 'global_variables_save_button';
  static const globalVariablesAddRow = 'global_variables_add_row';
  static const globalVariablesKeyField = 'global_variables_key_field';
  static const globalVariablesValueField = 'global_variables_value_field';
  static const manageEnvironmentsSheet = 'manage_environments_sheet';
  static const manageEnvironmentsAddButton = 'manage_environments_add_button';
  static const manageEnvironmentsCloseButton =
      'manage_environments_close_button';
  static const manageEnvironmentsMoreButton = 'manage_environments_more_button';
  static const manageEnvironmentsSourcePill = 'manage_environments_source_pill';
  static const manageEnvironmentsEmptyState = 'manage_environments_empty_state';
  static const environmentEditorSheet = 'environment_editor_sheet';
  static const environmentEditorNameField = 'environment_editor_name_field';
  static const environmentEditorSaveButton = 'environment_editor_save_button';
  static const environmentEditorDeleteButton =
      'environment_editor_delete_button';

  /// Builds a stable key for a variable key input inside reusable variable rows.
  static String variableRowsEditorKeyField(int index) =>
      'variable_rows_editor_${index}_key';

  /// Builds a stable key for a variable value input inside reusable variable rows.
  static String variableRowsEditorValueField(int index) =>
      'variable_rows_editor_${index}_value';

  /// Builds a stable key for the variable row remove affordance.
  static String variableRowsEditorRemoveButton(int index) =>
      'variable_rows_editor_${index}_remove';

  /// Builds a stable key for an environment row inside the Environment menu.
  static String requestsEnvironmentMenuItem(String environmentId) =>
      'requests_environment_menu_item_$environmentId';
}
