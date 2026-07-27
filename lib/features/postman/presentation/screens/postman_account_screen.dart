import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../cubit/postman_account_cubit.dart';
import '../cubit/postman_account_state.dart';

class PostmanAccountScreen extends StatelessWidget {
  const PostmanAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostmanAccountCubit, PostmanAccountState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final account = state.account;
        final maskedApiKey = _maskApiKey(state.apiKey);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.small,
            AppSpacing.medium,
            AppSpacing.medium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _UnlinkButton(
                  isLoading: state.isUnlinking,
                  onTap: state.isLinked && !state.isUnlinking
                      ? () async {
                          await context.read<PostmanAccountCubit>().unlink();
                        }
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              if (!state.isLinked)
                const Expanded(
                  child: _EmptyAccountView(
                    title: 'Postman is not linked',
                    message:
                        'Link a Postman API key from the Postman tab to see your account details here.',
                  ),
                )
              else if (account == null)
                Expanded(
                  child: _EmptyAccountView(
                    title: 'Unable to load account',
                    message: state.errorMessage ??
                        'We could not load your Postman account right now.',
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.xLarge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: AppSpacing.xSmall,
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Name', value: account.displayName),
                        const _RowDivider(),
                        _InfoRow(label: 'Email', value: account.email),
                        const _RowDivider(),
                        _InfoRow(label: 'API Key', value: maskedApiKey),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _maskApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      return '-';
    }

    if (apiKey.length <= 12) {
      return '${apiKey.substring(0, 4)}...';
    }

    return '${apiKey.substring(0, 12)}...';
  }
}

class _UnlinkButton extends StatelessWidget {
  const _UnlinkButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        minimumSize: const Size(108, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xLarge),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onError,
              ),
            )
          : const Text('Unlink'),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 78),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: context.appColors.border,
    );
  }
}

class _EmptyAccountView extends StatelessWidget {
  const _EmptyAccountView({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 52,
              color: colors.iconSecondary,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
