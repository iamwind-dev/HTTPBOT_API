import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../data/services/collection_file_importer.dart';
import '../../domain/entities/collection_import_type.dart';
import '../../domain/entities/openapi_directory_entry.dart';
import '../cubits/collection_cubit.dart';

enum CollectionActionMenuItem {
  importHar,
  importFromUrl,
  importFromDirectory,
  importSpec,
  importCollection,
  newCollection,
}

class CollectionsShellActionButton extends StatelessWidget {
  const CollectionsShellActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FloatingActionButton(
      key: const ValueKey<String>(AppWidgetKeys.collectionsFab),
      heroTag: AppWidgetKeys.collectionsFab,
      tooltip: AppStrings.requestsAddTooltip,
      onPressed: () => _showActionMenu(context),
      backgroundColor: colors.methodGet,
      foregroundColor: colors.textOnPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded),
    );
  }

  Future<void> _showActionMenu(BuildContext context) async {
    final selectedItem = await showGeneralDialog<CollectionActionMenuItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Collections action menu',
      barrierColor: context.appColors.modalBarrier,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, __, ___) => _CollectionsActionMenu(
        onSelected: (item) => Navigator.of(dialogContext).pop(item),
      ),
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curvedAnimation),
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
    );

    if (!context.mounted || selectedItem == null) {
      return;
    }

    switch (selectedItem) {
      case CollectionActionMenuItem.importHar:
        await _importCollectionFile(context, CollectionImportType.har);
      case CollectionActionMenuItem.importSpec:
        await _importCollectionFile(context, CollectionImportType.openApiSpec);
      case CollectionActionMenuItem.importCollection:
        await _importCollectionFile(
          context,
          CollectionImportType.postmanCollection,
        );
      case CollectionActionMenuItem.importFromUrl:
        await _showImportFromUrlDialog(context);
      case CollectionActionMenuItem.importFromDirectory:
        await _showOpenApiDirectoryDialog(context);
      case CollectionActionMenuItem.newCollection:
        _showNotImplementedMessage(context, 'New Collection');
        break;
    }
  }

  Future<void> _importCollectionFile(
    BuildContext context,
    CollectionImportType type,
  ) async {
    try {
      final imported = await context.read<CollectionCubit>().importFile(type);
      if (!context.mounted || imported == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "${imported.name}" with ${imported.itemCount} requests.',
          ),
        ),
      );
    } on CollectionImportException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on MissingPluginException {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File picker is not ready. Please fully restart the app.',
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to open the file picker.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to import the selected file.')),
      );
    }
  }

  Future<void> _showImportFromUrlDialog(BuildContext context) async {
    final url = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ImportFromUrlDialog(),
    );

    if (!context.mounted || url == null || url.trim().isEmpty) {
      return;
    }

    try {
      final imported = await context.read<CollectionCubit>().importFromUrl(url);
      if (!context.mounted || imported == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "${imported.name}" with ${imported.itemCount} requests.',
          ),
        ),
      );
    } on CollectionImportException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to import the URL.')),
      );
    }
  }

  Future<void> _showOpenApiDirectoryDialog(BuildContext context) async {
    final selection = await showDialog<_DirectoryImportSelection>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CollectionCubit>(),
        child: const _OpenApiDirectoryDialog(),
      ),
    );

    if (!context.mounted || selection == null) {
      return;
    }

    try {
      final imported = await context.read<CollectionCubit>().importFromUrl(
        selection.specUrl,
        fallbackName: selection.title,
      );
      if (!context.mounted || imported == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "${imported.name}" with ${imported.itemCount} requests.',
          ),
        ),
      );
    } on CollectionImportException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to import from the directory.')),
      );
    }
  }

  void _showNotImplementedMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is not available yet.')));
  }
}

class _CollectionsActionMenu extends StatelessWidget {
  const _CollectionsActionMenu({required this.onSelected});

  final ValueChanged<CollectionActionMenuItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.small,
          AppSpacing.medium,
          AppSpacing.medium,
          86,
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth < 420 ? screenWidth * 0.74 : 332,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.38),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.modalShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.medium,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CollectionsActionRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Help',
                      onTap: null,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsActionDivider(),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsSectionLabel(label: 'HAR Format'),
                    const SizedBox(height: AppSpacing.xSmall),
                    _CollectionsActionRow(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Import HAR',
                      onTap: () =>
                          onSelected(CollectionActionMenuItem.importHar),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsActionDivider(),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsSectionLabel(label: 'OpenAPI/Swagger (Beta)'),
                    const SizedBox(height: AppSpacing.xSmall),
                    _CollectionsActionRow(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Import from URL',
                      onTap: () =>
                          onSelected(CollectionActionMenuItem.importFromUrl),
                    ),
                    _CollectionsActionRow(
                      label: 'Import from Directory',
                      onTap: () => onSelected(
                        CollectionActionMenuItem.importFromDirectory,
                      ),
                    ),
                    _CollectionsActionRow(
                      label: 'Import Spec',
                      onTap: () =>
                          onSelected(CollectionActionMenuItem.importSpec),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsActionDivider(),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsSectionLabel(label: 'Postman Format'),
                    const SizedBox(height: AppSpacing.xSmall),
                    _CollectionsActionRow(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Import Collection',
                      onTap: () =>
                          onSelected(CollectionActionMenuItem.importCollection),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsActionDivider(),
                    const SizedBox(height: AppSpacing.small),
                    _CollectionsActionRow(
                      icon: Icons.add_rounded,
                      label: 'New Collection',
                      onTap: () =>
                          onSelected(CollectionActionMenuItem.newCollection),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionsSectionLabel extends StatelessWidget {
  const _CollectionsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: context.appColors.textSecondary.withValues(alpha: 0.88),
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _CollectionsActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.appColors.divider.withValues(alpha: 0.5),
    );
  }
}

class _CollectionsActionRow extends StatelessWidget {
  const _CollectionsActionRow({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w500,
      fontSize: 17,
      height: 1.45,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: icon == null
                    ? null
                    : Icon(icon, size: 22, color: colors.iconPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: textStyle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportFromUrlDialog extends StatefulWidget {
  const _ImportFromUrlDialog();

  @override
  State<_ImportFromUrlDialog> createState() => _ImportFromUrlDialogState();
}

class _ImportFromUrlDialogState extends State<_ImportFromUrlDialog> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: AppSpacing.large,
        right: AppSpacing.large,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xxLarge),
            border: Border.all(color: colors.border.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.large,
            AppSpacing.large,
            AppSpacing.large,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Import OpenAPI Spec',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.xLarge),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                ),
                child: TextField(
                  controller: _urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter URL',
                    hintStyle: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.textSecondary.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Row(
                children: [
                  Expanded(
                    child: _ImportDialogButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: _ImportDialogButton(label: 'Import', onTap: _submit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(_urlController.text.trim());
  }
}

class _ImportDialogButton extends StatelessWidget {
  const _ImportDialogButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xLarge),
        onTap: onTap,
        child: Ink(
          height: 72,
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.xLarge),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenApiDirectoryDialog extends StatefulWidget {
  const _OpenApiDirectoryDialog();

  @override
  State<_OpenApiDirectoryDialog> createState() =>
      _OpenApiDirectoryDialogState();
}

class _OpenApiDirectoryDialogState extends State<_OpenApiDirectoryDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<List<OpenApiDirectoryEntry>> _futureEntries;
  String _query = '';
  OpenApiDirectoryEntry? _selectedEntry;
  String? _selectedVersionName;

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
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final entry = _selectedEntry;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xSmall),
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

                        setState(() {
                          _selectedEntry = null;
                          _selectedVersionName = null;
                        });
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
                        query: _query,
                        onEntrySelected: (selected) {
                          setState(() {
                            _selectedEntry = selected;
                            _selectedVersionName =
                                selected.preferredVersionName;
                          });
                        },
                      )
                    : _DirectoryVersionStep(
                        entry: entry,
                        selectedVersionName: _selectedVersionName,
                        onVersionSelected: (versionName) {
                          setState(() => _selectedVersionName = versionName);
                        },
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
  }

  String _directoryErrorMessage(Object? error) {
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
    final entry = _selectedEntry;
    final versionName = _selectedVersionName;
    if (entry == null || versionName == null) {
      return;
    }

    for (final version in entry.versions) {
      if (version.name == versionName) {
        Navigator.of(context).pop(
          _DirectoryImportSelection(
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
                  ?._directoryErrorMessage(snapshot.error) ??
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.large,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            entry.description.isEmpty
                ? 'No description available.'
                : entry.description,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
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

class _DirectoryImportSelection {
  const _DirectoryImportSelection({required this.title, required this.specUrl});

  final String title;
  final String specUrl;
}
