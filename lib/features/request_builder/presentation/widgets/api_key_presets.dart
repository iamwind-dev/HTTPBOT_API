/// Preset key names offered for API Key auth before falling back to a custom name.
const List<String> apiKeyNamePresets = <String>[
  'X-API-Key',
  'api_key',
  'Authorization',
  'access_token',
  'client_id',
  'api_token',
];

/// Sentinel dropdown value representing the custom key-name option.
const String apiKeyCustomNameSentinel = '__api_key_custom__';
