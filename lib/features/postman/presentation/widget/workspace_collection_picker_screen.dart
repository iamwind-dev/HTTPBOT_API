import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../domain/entities/postman_workspace_entity.dart';
import '../cubit/postman_cubit.dart';
import '../cubit/postman_state.dart';

class WorkspaceCollectionPickerScreen extends StatelessWidget {
  const WorkspaceCollectionPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: screenHeight * 0.94,
      child: BlocBuilder<PostmanCubit, PostmanState>(
        builder: (context, state) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xLarge),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.surface, colors.background],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  AppSpacing.medium,
                  AppSpacing.medium,
                  0,
                ),
                child: Column(
                  children: [
                    _Header(state: state),
                    const SizedBox(height: AppSpacing.medium),
                    Expanded(child: _Body(state: state)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final PostmanState state;

  @override
  Widget build(BuildContext context) {
    final workspace = state.selectedWorkspace;
    final colors = context.appColors;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: workspace == null
                ? const _HeaderTitle(title: 'No workspace')
                : _WorkspaceDropdown(
                    value: workspace.id,
                    workspaces: state.workspaces,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      context.read<PostmanCubit>().selectWorkspace(value);
                    },
                  ),
          ),
          const SizedBox(width: AppSpacing.small),
          _CircleIconButton(
            icon: Icons.check_rounded,
            backgroundColor: state.canImportSelectedCollection
                ? colors.methodGet
                : colors.headerActionSurface,
            iconColor: state.canImportSelectedCollection
                ? colors.textOnPrimary
                : colors.iconSecondary,
            onTap: () async {
              final didImport = await context
                  .read<PostmanCubit>()
                  .importSelectedCollection();
              if (didImport) {
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final PostmanState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingCollections && !state.hasWorkspaces) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasWorkspaces) {
      return const _EmptyCollectionsView(
        title: 'No Workspaces',
        message: 'No Postman workspaces were found for this API key.',
      );
    }

    if (state.isLoadingCollectionDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final workspace = state.selectedWorkspace;
    if (workspace == null) {
      return const _EmptyCollectionsView(
        title: 'No Workspace',
        message: 'Please select a workspace to continue.',
      );
    }

    if (workspace.collections.isEmpty) {
      return const _EmptyCollectionsView(
        title: 'No Collections',
        message:
            'There are no collections in this workspace.\nPlease select a different workspace.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      itemCount: workspace.collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final collection = workspace.collections[index];
        final isSelected = state.pickerSelectedCollectionId == collection.id;

        return _CollectionTile(
          title: collection.name,
          selected: isSelected,
          onTap: () {
            context.read<PostmanCubit>().selectPickerCollection(collection.id);
          },
        );
      },
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _WorkspaceDropdown extends StatelessWidget {
  const _WorkspaceDropdown({
    required this.value,
    required this.workspaces,
    required this.onChanged,
  });

  final String value;
  final List<PostmanWorkspaceEntity> workspaces;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        canvasColor: colors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 240,
          iconSize: 18,
          borderRadius: BorderRadius.circular(24),
          dropdownColor: colors.surface,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
          icon: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.headerActionSurface,
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.iconSecondary,
              size: 16,
            ),
          ),
          selectedItemBuilder: (context) {
            return workspaces.map((workspace) {
              return Center(
                child: Text(
                  workspace.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              );
            }).toList();
          },
          items: workspaces.map((workspace) {
            return DropdownMenuItem<String>(
              value: workspace.id,
              child: Text(
                workspace.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, color: colors.methodGet, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _SelectionIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.methodGet : Colors.transparent,
        border: Border.all(
          color: selected ? colors.methodGet : colors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: colors.textOnPrimary, size: 18)
          : null,
    );
  }
}

class _EmptyCollectionsView extends StatelessWidget {
  const _EmptyCollectionsView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fadedStrong = colors.textPrimary.withValues(alpha: 0.72);
    final fadedLight = colors.textSecondary.withValues(alpha: 0.92);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 60,
              color: colors.iconSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fadedStrong,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: fadedLight, fontSize: 15, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? colors.headerActionSurface,
            border: Border.all(color: colors.border.withValues(alpha: 0.35)),
          ),
          child: Center(
            child: Icon(icon, color: iconColor ?? colors.iconPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}
