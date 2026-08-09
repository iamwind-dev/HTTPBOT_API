import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme_context.dart';
import '../../../../core/widgets/body_empty.dart';
import '../../domain/entities/postman_auth_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_folder_entity.dart';
import '../../domain/entities/postman_request_entity.dart';
import '../../domain/entities/postman_variable_entity.dart';
import '../../presentation/cubit/postman_cubit.dart';
import '../../presentation/cubit/postman_state.dart';
import '../../presentation/cubit/postman_ui_cubits.dart';
import '../model/postman_list_item_model.dart';
import '../widget/postman_list_item.dart';
import 'postman_collection_detail_page.dart';

class PostmanScreen extends StatelessWidget {
  const PostmanScreen({super.key});

  @override
  Widget build(BuildContext pageContext) {
    return BlocBuilder<PostmanCubit, PostmanState>(
      builder: (context, state) {
        if (state.isLoadingCollections || state.isLoadingCollectionDetail) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasLinkedApi && !state.hasWorkspaces) {
          return const BodyEmpty(
            title: 'No Workspaces',
            subtitle: 'No Postman workspaces were found for this API key',
          );
        }

        if (state.collections.isEmpty) {
          return const BodyEmpty(
            title: 'No Collections',
            subtitle: "Tap '+' to create or import a new collection",
          );
        }

        final items = state.collections
            .map(
              (collection) => PostmanListItemModel(
                folderName: collection.name,
                itemCount: collection.totalRequestCount,
              ),
            )
            .toList(growable: false);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final collection = state.collections[index];

            return PostmanListItem(
              item: item,
              onTap: () => _openCollectionDetail(pageContext, collection),
              onMoreTap: () => _showCollectionActions(context, collection),
            );
          },
        );
      },
    );
  }

  /// Selects a local collection before pushing it above the bottom navigation.
  Future<void> _openCollectionDetail(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final cubit = context.read<PostmanCubit>();
    cubit.selectImportedCollection(collection);
    if (!context.mounted) {
      return;
    }

    final loadedCollection = cubit.state.selectedCollection;
    if (loadedCollection == null) {
      return;
    }

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PostmanCollectionDetailPage(collection: loadedCollection),
        ),
      ),
    );
    if (context.mounted) {
      cubit.clearSelectedCollection();
    }
  }

  Future<void> _showCollectionActions(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final action = await showModalBottomSheet<_PostmanListAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PostmanActionsSheet(),
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _PostmanListAction.edit:
        await _editCollection(context, collection);
        break;
      case _PostmanListAction.export:
        await _exportCollection(collection);
        break;
      case _PostmanListAction.delete:
        await _deleteCollection(context, collection);
        break;
    }
  }

  Future<void> _editCollection(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final updated = await Navigator.of(context).push<PostmanCollectionEntity>(
      MaterialPageRoute<PostmanCollectionEntity>(
        fullscreenDialog: true,
        builder: (_) => _PostmanCollectionEditorPage(collection: collection),
      ),
    );

    if (!context.mounted || updated == null) {
      return;
    }

    await context.read<PostmanCubit>().updateCollection(updated);
  }

  Future<void> _deleteCollection(
    BuildContext context,
    PostmanCollectionEntity collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          _DeletePostmanCollectionDialog(collectionName: collection.name),
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    await context.read<PostmanCubit>().deleteCollection(collection.id);
  }

  Future<void> _exportCollection(PostmanCollectionEntity collection) {
    final payload = _collectionToExportPayload(collection);
    return SharePlus.instance.share(
      ShareParams(
        subject: collection.name,
        text: const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );
  }

  Map<String, Object?> _collectionToExportPayload(
    PostmanCollectionEntity collection,
  ) {
    return <String, Object?>{
      'id': collection.id,
      'name': collection.name,
      'description': collection.description,
      'auth': collection.auth.type.name,
      'variables': collection.variables
          .map(
            (variable) => <String, Object?>{
              'key': variable.key,
              'value': variable.value,
              'type': variable.type,
              'enabled': variable.isEnabled,
            },
          )
          .toList(growable: false),
      'folders': collection.folders.map(_folderToJson).toList(growable: false),
      'requests': collection.requests
          .map(_requestToJson)
          .toList(growable: false),
    };
  }

  Map<String, Object?> _folderToJson(PostmanFolderEntity folder) {
    return <String, Object?>{
      'id': folder.id,
      'name': folder.name,
      'folders': folder.folders.map(_folderToJson).toList(growable: false),
      'requests': folder.requests.map(_requestToJson).toList(growable: false),
    };
  }

  Map<String, Object?> _requestToJson(PostmanRequestEntity request) {
    return <String, Object?>{
      'id': request.id,
      'name': request.name,
      'description': request.description,
      'method': request.method,
      'url': request.rawUrl,
      'queryParameters': request.queryParameters
          .map(
            (item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'enabled': item.isEnabled,
              'type': item.type.name,
              'contentType': item.contentType,
              'description': item.description,
            },
          )
          .toList(growable: false),
      'headers': request.headers
          .map(
            (item) => <String, Object?>{
              'key': item.key,
              'value': item.value,
              'enabled': item.isEnabled,
              'type': item.type.name,
              'contentType': item.contentType,
              'description': item.description,
            },
          )
          .toList(growable: false),
      'body': <String, Object?>{
        'type': request.body.type.name,
        'raw': request.body.raw,
        'rawSubtype': request.body.rawSubtype.name,
        'graphQlQuery': request.body.graphQlQuery,
        'graphQlVariables': request.body.graphQlVariables,
        'filePath': request.body.filePath,
      },
      'auth': request.auth.type.name,
    };
  }
}

enum _PostmanListAction { edit, export, delete }

class _PostmanActionsSheet extends StatelessWidget {
  const _PostmanActionsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.modalShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PostmanActionMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      Navigator.of(context).pop(_PostmanListAction.edit),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.ios_share_rounded,
                  label: 'Export...',
                  onTap: () =>
                      Navigator.of(context).pop(_PostmanListAction.export),
                ),
                _PostmanActionMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_PostmanListAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostmanActionMenuItem extends StatelessWidget {
  const _PostmanActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = danger ? const Color(0xFFFF453A) : colors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: foreground),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletePostmanCollectionDialog extends StatelessWidget {
  const _DeletePostmanCollectionDialog({required this.collectionName});

  final String collectionName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Collection',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you would like to delete "$collectionName"?',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PostmanDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PostmanDialogButton(
                    label: 'Delete',
                    danger: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostmanDialogButton extends StatelessWidget {
  const _PostmanDialogButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: danger ? const Color(0xFFFF453A) : colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostmanCollectionEditorPage extends StatefulWidget {
  const _PostmanCollectionEditorPage({required this.collection});

  final PostmanCollectionEntity collection;

  @override
  State<_PostmanCollectionEditorPage> createState() =>
      _PostmanCollectionEditorPageState();
}

class _PostmanCollectionEditorPageState
    extends State<_PostmanCollectionEditorPage> {
  late final TextEditingController _nameController;
  late final PostmanVariablesCubit _variablesCubit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    final variables = widget.collection.variables.isEmpty
        ? <PostmanVariableEntity>[
            const PostmanVariableEntity(key: 'baseUrl', value: ''),
          ]
        : widget.collection.variables
              .map((item) => item.copyWith())
              .toList(growable: true);
    _variablesCubit = PostmanVariablesCubit(variables);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _variablesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostmanVariablesCubit, List<PostmanVariableEntity>>(
      bloc: _variablesCubit,
      builder: (context, variables) {
        final colors = context.appColors;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Row(
                  children: [
                    _HeaderCircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Collection',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _HeaderCircleButton(
                      icon: Icons.check_rounded,
                      filled: true,
                      onTap: _save,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _EditorCard(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Collection name',
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Variables',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _EditorCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < variables.length; i++) ...[
                        _PostmanVariableRow(
                          variable: variables[i],
                          onChanged: (updated) =>
                              _variablesCubit.updateAt(i, updated),
                        ),
                        if (i != variables.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colors.divider,
                            indent: 64,
                          ),
                      ],
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.divider,
                        indent: 64,
                      ),
                      InkWell(
                        onTap: _variablesCubit.addEmpty,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              const _VariableStateDot(
                                icon: Icons.add_rounded,
                                filled: true,
                              ),
                              const SizedBox(width: 18),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Auth',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _EditorCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Auth',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _postmanAuthLabel(widget.collection.auth.type),
                        style: TextStyle(
                          color: colors.methodGet,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.unfold_more_rounded,
                        color: colors.methodGet,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _save() {
    final cleanedVariables = _variablesCubit.state
        .where((item) => item.key.trim().isNotEmpty)
        .map(
          (item) =>
              item.copyWith(key: item.key.trim(), value: item.value.trim()),
        )
        .toList(growable: false);

    final updated = widget.collection.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.collection.name
          : _nameController.text.trim(),
      variables: cleanedVariables,
    );
    Navigator.of(context).pop(updated);
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: child,
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: filled ? colors.methodGet : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            color: filled ? colors.textOnPrimary : colors.textPrimary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _PostmanVariableRow extends StatelessWidget {
  const _PostmanVariableRow({required this.variable, required this.onChanged});

  final PostmanVariableEntity variable;
  final ValueChanged<PostmanVariableEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                onChanged(variable.copyWith(isEnabled: !variable.isEnabled)),
            child: _VariableStateDot(
              icon: variable.isEnabled
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              filled: variable.isEnabled,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: TextFormField(
              initialValue: variable.key,
              onChanged: (value) => onChanged(variable.copyWith(key: value)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Variable',
              ),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: variable.value,
              textAlign: TextAlign.right,
              onChanged: (value) => onChanged(variable.copyWith(value: value)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Value',
              ),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariableStateDot extends StatelessWidget {
  const _VariableStateDot({required this.icon, required this.filled});

  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.methodGet : Colors.transparent,
        border: Border.all(
          color: filled ? colors.methodGet : colors.border,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: filled ? colors.textOnPrimary : colors.secondary,
      ),
    );
  }
}

String _postmanAuthLabel(PostmanAuthType type) {
  switch (type) {
    case PostmanAuthType.none:
      return 'No Auth';
    case PostmanAuthType.apiKey:
      return 'API Key';
    case PostmanAuthType.bearerToken:
      return 'Bearer Token';
    case PostmanAuthType.awsSignature:
      return 'AWS Signature';
    case PostmanAuthType.oauth1:
      return 'OAuth 1.0';
    case PostmanAuthType.oauth2:
      return 'OAuth 2.0';
    case PostmanAuthType.ntlm:
      return 'NTLM';
    default:
      return type.name[0].toUpperCase() + type.name.substring(1);
  }
}
