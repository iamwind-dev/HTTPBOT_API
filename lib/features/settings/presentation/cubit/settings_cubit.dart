import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/settings_catalog.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState.initial());

  /// Loads the typed settings sections used by the overview screen.
  void load() {
    emit(
      state.copyWith(
        status: SettingsStatus.ready,
        sections: SettingsCatalog.sections(),
      ),
    );
  }
}
