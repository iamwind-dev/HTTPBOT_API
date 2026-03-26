import 'package:equatable/equatable.dart';

import '../models/settings_section.dart';

enum SettingsStatus { initial, ready }

class SettingsState extends Equatable {
  const SettingsState({required this.status, required this.sections});

  const SettingsState.initial()
    : status = SettingsStatus.initial,
      sections = const <SettingsSection>[];

  final SettingsStatus status;
  final List<SettingsSection> sections;

  /// Indicates whether the overview has any configured settings content to render.
  bool get hasSections => sections.isNotEmpty;

  /// Creates an updated immutable state for the settings overview.
  SettingsState copyWith({
    SettingsStatus? status,
    List<SettingsSection>? sections,
  }) => SettingsState(
    status: status ?? this.status,
    sections: sections ?? this.sections,
  );

  @override
  List<Object?> get props => [status, sections];
}
