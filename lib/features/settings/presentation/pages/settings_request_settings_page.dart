import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection/injection.dart';
import '../../../request_builder/domain/entities/request_draft.dart';
import '../../../request_builder/domain/entities/request_draft_session.dart';
import '../../../request_builder/domain/usecases/get_current_request_draft_session_use_case.dart';
import '../../../request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../../../request_builder/domain/usecases/save_current_request_draft_session_use_case.dart';
import '../../../request_builder/domain/usecases/save_request_draft_use_case.dart';
import '../../../request_builder/presentation/cubit/request_editor_cubit.dart';
import '../../../request_builder/presentation/widgets/request_settings_sheet.dart';

class SettingsRequestSettingsPage extends StatefulWidget {
  const SettingsRequestSettingsPage({super.key});

  @override
  State<SettingsRequestSettingsPage> createState() =>
      _SettingsRequestSettingsPageState();
}

class _SettingsRequestSettingsPageState
    extends State<SettingsRequestSettingsPage> {
  RequestEditorCubit? _requestEditorCubit;
  RequestDraftSession? _draftSession;
  StreamSubscription<dynamic>? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    final subscription = _subscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    final requestEditorCubit = _requestEditorCubit;
    if (requestEditorCubit != null) {
      unawaited(requestEditorCubit.close());
    }
    super.dispose();
  }

  Future<void> _load() async {
    final draftSession = await getIt<GetCurrentRequestDraftSessionUseCase>()();
    final draft = draftSession?.draft ?? await getIt<GetRequestDraftUseCase>()();
    final requestEditorCubit = RequestEditorCubit(
      title: draftSession?.title ?? 'Request Settings',
      initialDraft: draft,
    );

    _subscription = requestEditorCubit.stream.listen((state) {
      unawaited(_persist(state.draft));
    });

    if (!mounted) {
      await requestEditorCubit.close();
      return;
    }

    setState(() {
      _draftSession = draftSession;
      _requestEditorCubit = requestEditorCubit;
      _isLoading = false;
    });
  }

  Future<void> _persist(RequestDraft draft) async {
    await getIt<SaveRequestDraftUseCase>()(draft);
    final draftSession = _draftSession;
    if (draftSession == null) {
      return;
    }

    await getIt<SaveCurrentRequestDraftSessionUseCase>()(
      RequestDraftSession(
        title: draftSession.title,
        draft: draft,
        requestIndex: draftSession.requestIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestEditorCubit = _requestEditorCubit;
    if (_isLoading || requestEditorCubit == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocProvider<RequestEditorCubit>.value(
      value: requestEditorCubit,
      child: const RequestSettingsView(useSheetCard: false, showHeader: false),
    );
  }
}
