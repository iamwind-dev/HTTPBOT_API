import 'package:flutter/material.dart';

import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';

enum CollectionActionMenuItem {
  help,
  importHar,
  importFromUrl,
  importFromDirectory,
  importSpec,
  importCollection,
  newCollection,
}

class CollectionsActionMenu extends StatelessWidget {
  const CollectionsActionMenu({super.key, required this.onSelected});

  final ValueChanged<CollectionActionMenuItem> onSelected;

  /// Builds the complete Collections creation and import action menu.
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CollectionsActionRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help',
                        onTap: () => onSelected(CollectionActionMenuItem.help),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const _CollectionsActionDivider(),
                      const SizedBox(height: AppSpacing.small),
                      const _CollectionsSectionLabel(label: 'HAR Format'),
                      const SizedBox(height: AppSpacing.xSmall),
                      _CollectionsActionRow(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Import HAR',
                        onTap: () =>
                            onSelected(CollectionActionMenuItem.importHar),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const _CollectionsActionDivider(),
                      const SizedBox(height: AppSpacing.small),
                      const _CollectionsSectionLabel(
                        label: 'OpenAPI/Swagger (Beta)',
                      ),
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
                      const _CollectionsActionDivider(),
                      const SizedBox(height: AppSpacing.small),
                      const _CollectionsSectionLabel(label: 'Postman Format'),
                      const SizedBox(height: AppSpacing.xSmall),
                      _CollectionsActionRow(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Import Collection',
                        onTap: () => onSelected(
                          CollectionActionMenuItem.importCollection,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const _CollectionsActionDivider(),
                      const SizedBox(height: AppSpacing.small),
                      _CollectionsActionRow(
                        itemKey: const ValueKey<String>(
                          AppWidgetKeys.collectionsNewCollectionAction,
                        ),
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
  const _CollectionsActionDivider();

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
    this.itemKey,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Key? itemKey;

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
        key: itemKey,
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
