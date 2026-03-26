import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode_store.dart';

class SharedPreferencesThemeModeStore implements ThemeModeStore {
  static const _themeModeKey = 'app_theme_mode';

  @override
  Future<ThemeMode> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_themeModeKey);

    return switch (rawValue) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_themeModeKey, mode.name);
  }
}
