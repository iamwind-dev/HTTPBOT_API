abstract final class AppWidgetKeys {
  static const requestsSearchField = 'requests_search_field';
  static const requestsFavoriteButton = 'requests_favorite_button';
  static const requestsFab = 'requests_fab';
  static const requestsListItemPrefix = 'requests_list_item';
  static const requestsEditorSheet = 'requests_editor_sheet';
  static const requestsEditorCloseButton = 'requests_editor_close_button';
  static const requestsEditorUrlField = 'requests_editor_url_field';
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
}
