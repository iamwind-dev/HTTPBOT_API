import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsItem extends Equatable {
  const SettingsItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;

  /// Provides a stable widget-key suffix for settings entry widgets.
  String get widgetKey => 'settings_item_$id';

  @override
  List<Object?> get props => [id, title, icon];
}
