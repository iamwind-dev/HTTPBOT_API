import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme_mode_store.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._themeModeStore) : super(ThemeMode.light);

  final ThemeModeStore _themeModeStore;

  Future<void> loadThemeMode() async {
    emit(await _themeModeStore.loadThemeMode());
  }

  Future<void> setDarkModeEnabled(bool isEnabled) async {
    final nextMode = isEnabled ? ThemeMode.dark : ThemeMode.light;

    if (state == nextMode) {
      return;
    }

    emit(nextMode);
    await _themeModeStore.saveThemeMode(nextMode);
  }
}
