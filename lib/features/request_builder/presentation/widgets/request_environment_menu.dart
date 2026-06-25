import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/request_environment.dart';
import '../../domain/entities/request_variable_store.dart';

enum RequestEnvironmentMenuAction {
  globalVariables,
  manageEnvironments,
  deactivate,
  edit,
  select,
}

class RequestEnvironmentMenuSelection {
  const RequestEnvironmentMenuSelection(this.action, {this.environmentId = ''});

  final RequestEnvironmentMenuAction action;
  final String environmentId;
}

/// Shows the Environment submenu for the request editor and returns the chosen action.
Future<RequestEnvironmentMenuSelection?> showRequestEnvironmentMenu(
  BuildContext context, {
  required RequestVariableStore store,
}) => showModalBottomSheet<RequestEnvironmentMenuSelection>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: context.appColors.surface,
  builder: (context) => _RequestEnvironmentMenu(store: store),
);

class _RequestEnvironmentMenu extends StatelessWidget {
  const _RequestEnvironmentMenu({required this.store});

  final RequestVariableStore store;

  void _close(BuildContext context, RequestEnvironmentMenuSelection selection) {
    Navigator.of(context).pop(selection);
  }

  /// Builds the submenu sections based on available environments and selection.
  @override
  Widget build(BuildContext context) {
    final selectedEnvironment = store.selectedEnvironment;
    final localEnvironments = store.environments
        .where(
          (environment) => environment.source == RequestEnvironmentSource.local,
        )
        .toList(growable: false);
    final postmanEnvironments = store.environments
        .where(
          (environment) =>
              environment.source == RequestEnvironmentSource.postman,
        )
        .toList(growable: false);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView(
          key: const ValueKey<String>(AppWidgetKeys.requestsEnvironmentMenuSheet),
          shrinkWrap: true,
          children: [
            const _MenuHeader(),
            if (selectedEnvironment != null) ...[
              _CurrentEnvironmentGroup(
                environment: selectedEnvironment,
                onDeactivate: () => _close(
                  context,
                  const RequestEnvironmentMenuSelection(
                    RequestEnvironmentMenuAction.deactivate,
                  ),
                ),
                onEdit: () => _close(
                  context,
                  RequestEnvironmentMenuSelection(
                    RequestEnvironmentMenuAction.edit,
                    environmentId: selectedEnvironment.id,
                  ),
                ),
              ),
              const Divider(height: 1),
            ],
            ListTile(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsEnvironmentMenuGlobalVariables,
              ),
              leading: Icon(
                CupertinoIcons.globe,
                color: context.appColors.iconPrimary,
              ),
              title: const Text('Global Variables'),
              onTap: () => _close(
                context,
                const RequestEnvironmentMenuSelection(
                  RequestEnvironmentMenuAction.globalVariables,
                ),
              ),
            ),
            ListTile(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsEnvironmentMenuManage,
              ),
              leading: Icon(
                CupertinoIcons.list_bullet,
                color: context.appColors.iconPrimary,
              ),
              title: const Text('Manage Environments'),
              onTap: () => _close(
                context,
                const RequestEnvironmentMenuSelection(
                  RequestEnvironmentMenuAction.manageEnvironments,
                ),
              ),
            ),
            if (localEnvironments.isNotEmpty) ...[
              const _SectionLabel(title: 'Local Environments'),
              for (final environment in localEnvironments)
                _EnvironmentRow(
                  environment: environment,
                  isSelected: environment.id == store.selectedEnvironmentId,
                  onTap: () => _close(
                    context,
                    RequestEnvironmentMenuSelection(
                      RequestEnvironmentMenuAction.select,
                      environmentId: environment.id,
                    ),
                  ),
                ),
            ],
            if (postmanEnvironments.isNotEmpty) ...[
              const _SectionLabel(title: 'Postman Environments'),
              for (final environment in postmanEnvironments)
                _EnvironmentRow(
                  environment: environment,
                  isSelected: environment.id == store.selectedEnvironmentId,
                  onTap: () => _close(
                    context,
                    RequestEnvironmentMenuSelection(
                      RequestEnvironmentMenuAction.select,
                      environmentId: environment.id,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.small),
          ],
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.large,
      AppSpacing.large,
      AppSpacing.large,
      AppSpacing.small,
    ),
    child: Text('Environment', style: Theme.of(context).textTheme.titleMedium),
  );
}

class _CurrentEnvironmentGroup extends StatelessWidget {
  const _CurrentEnvironmentGroup({
    required this.environment,
    required this.onDeactivate,
    required this.onEdit,
  });

  final RequestEnvironment environment;
  final VoidCallback onDeactivate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.xSmall,
          ),
          child: Text(
            environment.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListTile(
          key: const ValueKey<String>(
            AppWidgetKeys.requestsEnvironmentMenuDeactivate,
          ),
          leading: Icon(
            CupertinoIcons.xmark_circle,
            color: colors.methodDelete,
          ),
          title: Text(
            'Deactivate',
            style: TextStyle(color: colors.methodDelete),
          ),
          onTap: onDeactivate,
        ),
        ListTile(
          key: const ValueKey<String>(AppWidgetKeys.requestsEnvironmentMenuEdit),
          leading: Icon(CupertinoIcons.pencil, color: colors.iconPrimary),
          title: const Text('Edit'),
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.large,
      AppSpacing.medium,
      AppSpacing.large,
      AppSpacing.xSmall,
    ),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.appColors.textSecondary,
      ),
    ),
  );
}

class _EnvironmentRow extends StatelessWidget {
  const _EnvironmentRow({
    required this.environment,
    required this.isSelected,
    required this.onTap,
  });

  final RequestEnvironment environment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListTile(
      key: ValueKey<String>(
        AppWidgetKeys.requestsEnvironmentMenuItem(environment.id),
      ),
      title: Text(
        environment.displayName,
        style: TextStyle(
          color: isSelected ? colors.primary : colors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(CupertinoIcons.check_mark, color: colors.primary)
          : null,
      onTap: onTap,
    );
  }
}
