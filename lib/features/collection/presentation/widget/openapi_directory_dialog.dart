import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../data/services/collection_file_importer.dart';
import '../../domain/entities/openapi_directory_entry.dart';
import '../cubits/collection_cubit.dart';
import '../cubits/collection_ui_cubits.dart';

class DirectoryImportSelection {
  const DirectoryImportSelection({required this.title, required this.specUrl});

  final String title;
  final String specUrl;
}

class OpenApiDirectoryDialog extends StatefulWidget {
  const OpenApiDirectoryDialog({super.key});

  @override
  State<OpenApiDirectoryDialog> createState() => _OpenApiDirectoryDialogState();
}

class _OpenApiDirectoryDialogState extends State<OpenApiDirectoryDialog> {
  final TextEditingController _searchController = TextEditingController();
  final OpenApiDirectoryCubit _uiCubit = OpenApiDirectoryCubit();
  late final Future<List<OpenApiDirectoryEntry>> _futureEntries;

  @override
  void initState() {
    super.initState();
    _futureEntries = context.read<CollectionCubit>().loadDirectoryEntries();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }
    _uiCubit.updateQuery(_searchController.text.trim().toLowerCase());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _uiCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OpenApiDirectoryCubit, OpenApiDirectoryState>(
      bloc: _uiCubit,
      builder: (context, state) {
        final colors = context.appColors;
        final theme = Theme.of(context);
        final entry = state.selectedEntry;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xSmall,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.9,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: colors.border.withValues(alpha: 0.35)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      AppSpacing.medium,
                      AppSpacing.medium,
                      AppSpacing.medium,
                    ),
                    child: Row(
                      children: [
                        _CircleHeaderButton(
                          icon: entry == null
                              ? Icons.close_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (entry == null) {
                              Navigator.of(context).pop();
                              return;
                            }

                            _uiCubit.clearEntry();
                          },
                        ),
                        Expanded(
                          child: Text(
                            entry?.title ?? 'OpenAPI Directory',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: entry == null
                              ? null
                              : Align(
                                  alignment: Alignment.centerRight,
                                  child: _ConfirmHeaderButton(
                                    onTap: _confirmSelectedVersion,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (entry == null)
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF173452),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.medium,
                      ),
                      child: Text(
                        'Powered by APIs.guru',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textOnPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Expanded(
                    child: entry == null
                        ? _DirectoryListStep(
                            futureEntries: _futureEntries,
                            query: state.query,
                            onEntrySelected: _uiCubit.selectEntry,
                          )
                        : _DirectoryVersionStep(
                            entry: entry,
                            selectedVersionName: state.selectedVersionName,
                            onVersionSelected: _uiCubit.selectVersion,
                          ),
                  ),
                  if (entry == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.medium,
                        AppSpacing.small,
                        AppSpacing.medium,
                        AppSpacing.medium,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(AppRadius.xLarge),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: colors.iconSecondary,
                              size: 30,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Search APIs',
                                  hintStyle: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: colors.textSecondary.withValues(
                                          alpha: 0.78,
                                        ),
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String directoryErrorMessage(Object? error) {
    if (error is CollectionImportException) {
      return error.message;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return 'Unable to load the OpenAPI directory. HTTP $statusCode.';
      }

      return 'Unable to load the OpenAPI directory. Please check your internet connection.';
    }

    return 'Unable to load the OpenAPI directory.';
  }

  void _confirmSelectedVersion() {
    final entry = _uiCubit.state.selectedEntry;
    final versionName = _uiCubit.state.selectedVersionName;
    if (entry == null || versionName == null) {
      return;
    }

    for (final version in entry.versions) {
      if (version.name == versionName) {
        Navigator.of(context).pop(
          DirectoryImportSelection(
            title: entry.title,
            specUrl: version.specUrl,
          ),
        );
        return;
      }
    }
  }
}

class _DirectoryListStep extends StatelessWidget {
  const _DirectoryListStep({
    required this.futureEntries,
    required this.query,
    required this.onEntrySelected,
  });

  final Future<List<OpenApiDirectoryEntry>> futureEntries;
  final String query;
  final ValueChanged<OpenApiDirectoryEntry> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return FutureBuilder<List<OpenApiDirectoryEntry>>(
      future: futureEntries,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message =
              (context.findAncestorStateOfType<_OpenApiDirectoryDialogState>())
                  ?.directoryErrorMessage(snapshot.error) ??
              'Unable to load the OpenAPI directory.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          );
        }

        final entries = snapshot.data ?? const <OpenApiDirectoryEntry>[];
        final filtered = query.isEmpty
            ? entries.take(60).toList(growable: false)
            : entries
                  .where((entry) {
                    final haystack = '${entry.title} ${entry.providerLabel}'
                        .toLowerCase();
                    return haystack.contains(query);
                  })
                  .take(60)
                  .toList(growable: false);

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.medium,
          ),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: colors.divider.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final entry = filtered[index];
            return _DirectoryEntryTile(
              entry: entry,
              onTap: () => onEntrySelected(entry),
            );
          },
        );
      },
    );
  }
}

class _DirectoryEntryTile extends StatelessWidget {
  const _DirectoryEntryTile({required this.entry, required this.onTap});

  final OpenApiDirectoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
          child: Row(
            children: [
              _DirectoryEntryLogo(logoUrl: entry.logoUrl),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxSmall),
                    Text(
                      entry.providerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.iconSecondary,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryVersionStep extends StatelessWidget {
  const _DirectoryVersionStep({
    required this.entry,
    required this.selectedVersionName,
    required this.onVersionSelected,
  });

  final OpenApiDirectoryEntry entry;
  final String? selectedVersionName;
  final ValueChanged<String> onVersionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium,
      ),
      children: [
        Text(
          'Description',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _ExpandableDescriptionCard(description: entry.description),
        const SizedBox(height: AppSpacing.xLarge),
        Text(
          'Versions',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        for (final version in entry.versions) ...[
          _VersionCard(
            label: version.name,
            selected: version.name == selectedVersionName,
            onTap: () => onVersionSelected(version.name),
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
      ],
    );
  }
}

class _ExpandableDescriptionCard extends StatefulWidget {
  const _ExpandableDescriptionCard({required this.description});

  final String description;

  @override
  State<_ExpandableDescriptionCard> createState() =>
      _ExpandableDescriptionCardState();
}

class _ExpandableDescriptionCardState
    extends State<_ExpandableDescriptionCard> {
  final ExpansionCubit _expansionCubit = ExpansionCubit();

  @override
  void dispose() {
    _expansionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpansionCubit, bool>(
      bloc: _expansionCubit,
      builder: (context, expanded) {
        final colors = context.appColors;
        final theme = Theme.of(context);
        final text = widget.description.isEmpty
            ? 'No description available.'
            : widget.description;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.large,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: expanded ? null : 5,
                overflow: expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              if (widget.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.medium),
                InkWell(
                  onTap: _expansionCubit.toggle,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxSmall,
                      vertical: AppSpacing.xxSmall,
                    ),
                    child: Text(
                      expanded ? 'Show less' : 'Read more',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.methodGet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.large,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            _VersionSelectionDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _VersionSelectionDot extends StatelessWidget {
  const _VersionSelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.methodGet : Colors.transparent,
        border: Border.all(
          color: selected ? colors.methodGet : colors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: colors.textOnPrimary, size: 22)
          : null,
    );
  }
}

class _DirectoryEntryLogo extends StatelessWidget {
  const _DirectoryEntryLogo({this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget fallback = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.image_outlined, color: colors.iconSecondary, size: 24),
    );

    final url = logoUrl;
    if (url == null || url.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  const _CircleHeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.background,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: colors.iconPrimary, size: 30),
        ),
      ),
    );
  }
}

class _ConfirmHeaderButton extends StatelessWidget {
  const _ConfirmHeaderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.methodGet,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.check_rounded,
            color: colors.textOnPrimary,
            size: 34,
          ),
        ),
      ),
    );
  }
}
