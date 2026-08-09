import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/help/help_topic.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/router/help_router.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../data/services/collection_file_importer.dart';
import '../../domain/entities/collection_import_type.dart';
import '../cubits/collection_cubit.dart';
import 'collection_editor_page.dart';
import 'collections_action_menu.dart';
import 'import_from_url_sheet.dart';
import 'openapi_directory_dialog.dart';

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

  /// Shows the Collections action menu and dispatches the selected workflow.
  Future<void> _showActionMenu(BuildContext context) async {
    final selectedItem = await showGeneralDialog<CollectionActionMenuItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Collections action menu',
      barrierColor: context.appColors.modalBarrier,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, __, ___) => CollectionsActionMenu(
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
      case CollectionActionMenuItem.help:
        await _showCollectionsHelp(context);
        break;
      case CollectionActionMenuItem.importHar:
        await _importCollectionFile(context, CollectionImportType.har);
        break;
      case CollectionActionMenuItem.importSpec:
        await _importCollectionFile(context, CollectionImportType.openApiSpec);
        break;
      case CollectionActionMenuItem.importCollection:
        await _importCollectionFile(
          context,
          CollectionImportType.postmanCollection,
        );
        break;
      case CollectionActionMenuItem.importFromUrl:
        await _showImportFromUrlDialog(context);
        break;
      case CollectionActionMenuItem.importFromDirectory:
        await _showOpenApiDirectoryDialog(context);
        break;
      case CollectionActionMenuItem.newCollection:
        await _showNewCollectionEditor(context);
        break;
    }
  }

  /// Opens Collections Help above the application tab shell.
  Future<void> _showCollectionsHelp(BuildContext context) {
    return HelpRouter.open(context, HelpTopic.collectionsFolders);
  }

  Future<void> _showNewCollectionEditor(BuildContext context) async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CollectionEditorPage(
          initialCollection: CollectionEditorPage.createDraft(),
          isCreating: true,
        ),
      ),
    );

    if (!context.mounted || created == null) {
      return;
    }

    final didCreate = context.read<CollectionCubit>().createCollection(created);
    if (!didCreate || !context.mounted) {
      return;
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
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImportFromUrlSheet(),
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
    final selection = await showDialog<DirectoryImportSelection>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CollectionCubit>(),
        child: const OpenApiDirectoryDialog(),
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
}
