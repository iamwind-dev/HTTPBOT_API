import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';

enum RequestActionMenuItem { importHar, importCurl, newRequest }

class RequestShellActionButton extends StatelessWidget {
  const RequestShellActionButton({
    super.key,
    required this.onImportHar,
    required this.onImportCurl,
    required this.onNewRequest,
  });

  final Future<void> Function() onImportHar;
  final Future<void> Function() onImportCurl;
  final Future<void> Function() onNewRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FloatingActionButton(
      key: const ValueKey<String>(AppWidgetKeys.requestsFab),
      heroTag: AppWidgetKeys.requestsFab,
      tooltip: AppStrings.requestsAddTooltip,
      onPressed: () => _showActionMenu(context),
      backgroundColor: colors.methodGet,
      foregroundColor: colors.textOnPrimary,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded),
    );
  }

  Future<void> _showActionMenu(BuildContext context) async {
    final selectedItem = await showMenu<RequestActionMenuItem>(
      context: context,
      position: _menuPositionFor(context),
      color: context.appColors.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 188),
      items: const [
        PopupMenuItem<RequestActionMenuItem>(
          value: RequestActionMenuItem.importHar,
          child: _RequestActionMenuRow(
            icon: CupertinoIcons.doc_text,
            label: AppStrings.requestsImportHar,
          ),
        ),
        PopupMenuItem<RequestActionMenuItem>(
          value: RequestActionMenuItem.importCurl,
          child: _RequestActionMenuRow(
            icon: CupertinoIcons.chevron_left_slash_chevron_right,
            label: AppStrings.requestsImportCurl,
          ),
        ),
        PopupMenuItem<RequestActionMenuItem>(
          value: RequestActionMenuItem.newRequest,
          child: _RequestActionMenuRow(
            icon: CupertinoIcons.plus_circle,
            label: AppStrings.requestsNewRequest,
          ),
        ),
      ],
    );

    switch (selectedItem) {
      case RequestActionMenuItem.importHar:
        await onImportHar();
      case RequestActionMenuItem.importCurl:
        await onImportCurl();
      case RequestActionMenuItem.newRequest:
        await onNewRequest();
      case null:
        break;
    }
  }

  RelativeRect _menuPositionFor(BuildContext context) {
    final button = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;

    if (button == null || overlay == null) {
      return RelativeRect.fill;
    }

    final buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonBottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    return RelativeRect.fromRect(
      Rect.fromPoints(buttonTopLeft, buttonBottomRight),
      Offset.zero & overlay.size,
    );
  }
}

class _RequestActionMenuRow extends StatelessWidget {
  const _RequestActionMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.iconPrimary, size: AppSpacing.large),
        const SizedBox(width: AppSpacing.small),
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
