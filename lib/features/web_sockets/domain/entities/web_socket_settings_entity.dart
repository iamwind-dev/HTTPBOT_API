import 'package:equatable/equatable.dart';

class WebSocketSettingsEntity extends Equatable {
  const WebSocketSettingsEntity({
    this.handshakeTimeoutSeconds = 30,
    this.verifySsl = true,
  });

  final int handshakeTimeoutSeconds;
  final bool verifySsl;

  /// Creates settings with updated values while keeping the current defaults.
  WebSocketSettingsEntity copyWith({
    int? handshakeTimeoutSeconds,
    bool? verifySsl,
  }) => WebSocketSettingsEntity(
    handshakeTimeoutSeconds:
        handshakeTimeoutSeconds ?? this.handshakeTimeoutSeconds,
    verifySsl: verifySsl ?? this.verifySsl,
  );

  @override
  List<Object> get props => [handshakeTimeoutSeconds, verifySsl];
}
