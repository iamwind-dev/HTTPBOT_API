abstract final class AppWidgetKeys {
  static const requestsSearchField = 'requests_search_field';
  static const requestsFavoriteButton = 'requests_favorite_button';
  static const requestsFab = 'requests_fab';
  static const websocketsFab = 'websockets_fab';
  static const collectionsFab = 'collections_fab';
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
  static const requestsResponseSheet = 'requests_response_sheet';
  static const requestsResponseCloseButton = 'requests_response_close_button';
  static const requestsResponseSendButton = 'requests_response_send_button';
  static const requestsResponseSummaryBadge = 'requests_response_summary_badge';
  static const settingsList = 'settings_list';
  static const settingsBackButton = 'settings_back_button';
  static const settingsThemeModeSwitch = 'settings_theme_mode_switch';
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
}
