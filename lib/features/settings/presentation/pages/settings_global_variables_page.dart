import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection/injection.dart';
import '../../../request_builder/presentation/cubit/environment_menu_cubit.dart';
import '../../../request_builder/presentation/cubit/environment_menu_state.dart';
import '../../../request_builder/presentation/widgets/global_variables_sheet.dart';

class SettingsGlobalVariablesPage extends StatefulWidget {
  const SettingsGlobalVariablesPage({super.key, required this.controller});

  final GlobalVariablesController controller;

  @override
  State<SettingsGlobalVariablesPage> createState() =>
      _SettingsGlobalVariablesPageState();
}

class _SettingsGlobalVariablesPageState
    extends State<SettingsGlobalVariablesPage> {
  late final EnvironmentMenuCubit _cubit = EnvironmentMenuCubit(
    getIt(),
    getIt(),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.loadAvailableEnvironments());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EnvironmentMenuCubit, EnvironmentMenuState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.status == EnvironmentMenuStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return GlobalVariablesView(
            variables: state.store.globalVariables,
            onSave: _cubit.saveGlobalVariables,
            controller: widget.controller,
          );
        },
      );
}
