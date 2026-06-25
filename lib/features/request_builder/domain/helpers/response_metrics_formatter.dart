/// Placeholder rendered for any metric value that the transport could not supply.
const String metricsEmptyValue = '—';

/// Formats an exact byte count for the Metrics rows (e.g. `130 bytes`).
String formatBytes(int? bytes) {
  if (bytes == null) {
    return metricsEmptyValue;
  }
  return '$bytes bytes';
}

/// Formats a duration in seconds with millisecond precision (e.g. `0.057 secs`).
String formatDuration(Duration? duration) {
  if (duration == null) {
    return metricsEmptyValue;
  }
  if (duration == Duration.zero) {
    return '0 secs';
  }

  final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
  return '${seconds.toStringAsFixed(3)} secs';
}

/// Formats a timestamp as an ISO-8601 UTC string with a trailing `Z`.
String formatDateUtc(DateTime? dateTime) {
  if (dateTime == null) {
    return metricsEmptyValue;
  }
  return dateTime.toUtc().toIso8601String();
}

/// Formats an HTTP status code with its reason phrase (e.g. `200 No Error`).
String formatStatus(int? statusCode, String? reasonPhrase) {
  if (statusCode == null) {
    return metricsEmptyValue;
  }

  final reason = reasonPhrase?.trim();
  if (reason == null || reason.isEmpty) {
    return '$statusCode';
  }
  return '$statusCode $reason';
}

/// Returns the protocol label or the empty placeholder.
String formatProtocol(String? protocol) => formatText(protocol);

/// Returns the trimmed text or the empty placeholder when blank.
String formatText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return metricsEmptyValue;
  }
  return trimmed;
}

/// Formats a nullable boolean as `True` / `False`, or the empty placeholder.
String formatBool(bool? value) {
  if (value == null) {
    return metricsEmptyValue;
  }
  return value ? 'True' : 'False';
}
