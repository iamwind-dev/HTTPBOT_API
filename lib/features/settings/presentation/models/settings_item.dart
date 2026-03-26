import 'package:equatable/equatable.dart';

import '../../../../generated/assets.gen.dart';

enum SettingsItemKind { navigation, themeToggle }

class SettingsItem extends Equatable {
  const SettingsItem({
    required this.id,
    required this.title,
    required this.icon,
    this.kind = SettingsItemKind.navigation,
  });

  final String id;
  final String title;
  final SvgGenImage icon;
  final SettingsItemKind kind;

  /// Provides a stable widget-key suffix for settings entry widgets.
  String get widgetKey => 'settings_item_$id';

  bool get isThemeToggle => kind == SettingsItemKind.themeToggle;

  @override
  List<Object?> get props => [id, title, icon, kind];
}
