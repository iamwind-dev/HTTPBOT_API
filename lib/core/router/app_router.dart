import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/request_builder/domain/usecases/get_request_draft_use_case.dart';
import '../../features/request_builder/presentation/cubit/request_builder_cubit.dart';
import '../../features/request_builder/presentation/pages/request_builder_page.dart';
import '../../injection/injection.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              RequestBuilderCubit(getIt<GetRequestDraftUseCase>())..load(),
          child: const RequestBuilderPage(),
        ),
      ),
    ],
  );
}
