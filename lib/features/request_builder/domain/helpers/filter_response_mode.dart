/// The query languages offered by the Filter Response sheet.
enum FilterResponseMode { jq, jsonPath, xPath }

extension FilterResponseModeX on FilterResponseMode {
  /// Stable label shown in the mode picker.
  String get label => switch (this) {
    FilterResponseMode.jq => 'jq',
    FilterResponseMode.jsonPath => 'JSONPath',
    FilterResponseMode.xPath => 'XPath',
  };
}
