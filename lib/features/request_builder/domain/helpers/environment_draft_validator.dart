/// One editable variable line as typed by the user, before cleanup.
typedef EnvironmentVariableDraftRow = ({String key, String value});

abstract final class EnvironmentDraftValidator {
  /// Returns the first validation error for an environment draft, or null when valid.
  ///
  /// Rows with both key and value empty are ignored, matching the editor
  /// behavior of silently dropping blank lines.
  static String? validate({
    required String name,
    required List<EnvironmentVariableDraftRow> rows,
  }) {
    if (name.trim().isEmpty) {
      return 'Environment name is required.';
    }

    final seenKeys = <String>{};
    for (final row in rows) {
      final key = row.key.trim();
      final value = row.value.trim();

      if (key.isEmpty && value.isEmpty) {
        continue;
      }

      if (key.isEmpty) {
        return 'Variable key is required.';
      }

      if (key.contains('{{') || key.contains('}}')) {
        return 'Variable key must not include braces.';
      }

      if (!seenKeys.add(key)) {
        return 'Duplicate variable key: $key';
      }
    }

    return null;
  }
}
