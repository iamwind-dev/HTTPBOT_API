import '../../domain/entities/request_settings.dart';

class RequestSettingsModel {
  const RequestSettingsModel({
    required this.savedResponsesInHistory,
    required this.timeoutSeconds,
    required this.userAgent,
    required this.followRedirects,
    required this.sendCookies,
    required this.storeCookies,
    required this.verifySsl,
  });

  final int savedResponsesInHistory;
  final int timeoutSeconds;
  final String userAgent;
  final bool followRedirects;
  final bool sendCookies;
  final bool storeCookies;
  final bool verifySsl;

  factory RequestSettingsModel.fromEntity(RequestSettings entity) =>
      RequestSettingsModel(
        savedResponsesInHistory: entity.savedResponsesInHistory,
        timeoutSeconds: entity.timeoutSeconds,
        userAgent: entity.userAgent,
        followRedirects: entity.followRedirects,
        sendCookies: entity.sendCookies,
        storeCookies: entity.storeCookies,
        verifySsl: entity.verifySsl,
      );

  factory RequestSettingsModel.fromJson(
    Map<String, dynamic> json, {
    int? legacyTimeoutSeconds,
    bool? legacyVerifySsl,
  }) {
    final savedResponses = (json['savedResponsesInHistory'] as num?)?.toInt();
    final timeoutSeconds =
        (json['timeoutSeconds'] as num?)?.toInt() ?? legacyTimeoutSeconds;

    return RequestSettingsModel.fromEntity(
      RequestSettings.normalized(
        savedResponsesInHistory: savedResponses,
        timeoutSeconds: timeoutSeconds,
        userAgent: json['userAgent'] as String?,
        followRedirects: json['followRedirects'] as bool?,
        sendCookies: json['sendCookies'] as bool?,
        storeCookies: json['storeCookies'] as bool?,
        verifySsl: json['verifySsl'] as bool? ?? legacyVerifySsl,
      ),
    );
  }

  RequestSettings toEntity() => RequestSettings(
    savedResponsesInHistory: savedResponsesInHistory,
    timeoutSeconds: timeoutSeconds,
    userAgent: userAgent,
    followRedirects: followRedirects,
    sendCookies: sendCookies,
    storeCookies: storeCookies,
    verifySsl: verifySsl,
  );

  Map<String, Object?> toJson() => {
    'savedResponsesInHistory': savedResponsesInHistory,
    'timeoutSeconds': timeoutSeconds,
    'userAgent': userAgent,
    'followRedirects': followRedirects,
    'sendCookies': sendCookies,
    'storeCookies': storeCookies,
    'verifySsl': verifySsl,
  };
}
