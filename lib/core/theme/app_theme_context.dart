import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
}
