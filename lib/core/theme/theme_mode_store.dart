import 'package:flutter/material.dart';
abstract interface class ThemeModeStore {
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}
