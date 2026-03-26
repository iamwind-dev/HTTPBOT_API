import 'package:equatable/equatable.dart';

import 'settings_item.dart';

class SettingsSection extends Equatable {
  const SettingsSection({required this.items, this.title});

  final String? title;
  final List<SettingsItem> items;

  @override
  List<Object?> get props => [title, items];
}
