import 'package:equatable/equatable.dart';

const defaultRequestUserAgent = 'HTTPBot/2026.1.1';

class RequestSettings extends Equatable {
  const RequestSettings({
    this.savedResponsesInHistory = 10,
    this.timeoutSeconds = 30,
    this.userAgent = defaultRequestUserAgent,
    this.followRedirects = true,
    this.sendCookies = true,
    this.storeCookies = true,
    this.verifySsl = true,
  });

  final int savedResponsesInHistory;
  final int timeoutSeconds;
  final String userAgent;
  final bool followRedirects;
  final bool sendCookies;
  final bool storeCookies;
  final bool verifySsl;

  String? get normalizedUserAgent {
    final trimmed = userAgent.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  RequestSettings copyWith({
    int? savedResponsesInHistory,
    int? timeoutSeconds,
    String? userAgent,
    bool? followRedirects,
    bool? sendCookies,
    bool? storeCookies,
    bool? verifySsl,
  }) => RequestSettings(
    savedResponsesInHistory:
        savedResponsesInHistory ?? this.savedResponsesInHistory,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    userAgent: userAgent ?? this.userAgent,
    followRedirects: followRedirects ?? this.followRedirects,
    sendCookies: sendCookies ?? this.sendCookies,
    storeCookies: storeCookies ?? this.storeCookies,
    verifySsl: verifySsl ?? this.verifySsl,
  );

  factory RequestSettings.normalized({
    int? savedResponsesInHistory,
    int? timeoutSeconds,
    String? userAgent,
    bool? followRedirects,
    bool? sendCookies,
    bool? storeCookies,
    bool? verifySsl,
  }) => RequestSettings(
    savedResponsesInHistory: _normalizeSavedResponses(savedResponsesInHistory),
    timeoutSeconds: _normalizeTimeout(timeoutSeconds),
    userAgent: _normalizeUserAgent(userAgent),
    followRedirects: followRedirects ?? true,
    sendCookies: sendCookies ?? true,
    storeCookies: storeCookies ?? true,
    verifySsl: verifySsl ?? true,
  );

  static int _normalizeSavedResponses(int? value) {
    if (value == null) {
      return 10;
    }
    if (value < 0) {
      return 10;
    }
    if (value > 100) {
      return 100;
    }
    return value;
  }

  static int _normalizeTimeout(int? value) {
    if (value == null) {
      return 30;
    }
    if (value < 1) {
      return 30;
    }
    if (value > 600) {
      return 600;
    }
    return value;
  }

  static String _normalizeUserAgent(String? value) {
    if (value == null) {
      return defaultRequestUserAgent;
    }
    return value;
  }

  @override
  List<Object> get props => [
    savedResponsesInHistory,
    timeoutSeconds,
    userAgent,
    followRedirects,
    sendCookies,
    storeCookies,
    verifySsl,
  ];
}
