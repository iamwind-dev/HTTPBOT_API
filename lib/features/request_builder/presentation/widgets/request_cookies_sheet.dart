import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../../injection/injection.dart';
import '../../domain/entities/http_cookie_entity.dart';
import '../../domain/helpers/http_cookie_utils.dart';
import '../../domain/repositories/http_cookie_repository.dart';
import 'request_modal_sheet.dart';

Future<void> showRequestCookiesSheet(
  BuildContext context, {
  required String requestUrl,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => _RequestCookiesSheet(requestUrl: requestUrl),
);

class _RequestCookiesSheet extends StatefulWidget {
  const _RequestCookiesSheet({required this.requestUrl});

  final String requestUrl;

  @override
  State<_RequestCookiesSheet> createState() => _RequestCookiesSheetState();
}

class _RequestCookiesSheetState extends State<_RequestCookiesSheet> {
  late final HttpCookieRepository _repository;
  late Future<List<HttpCookieEntity>> _cookiesFuture;

  String? get _requestDomain => tryParseRequestHost(widget.requestUrl);

  @override
  void initState() {
    super.initState();
    _repository = getIt<HttpCookieRepository>();
    _cookiesFuture = _loadCookies();
  }

  Future<List<HttpCookieEntity>> _loadCookies() async {
    final domain = _requestDomain;
    if (domain == null) {
      return const <HttpCookieEntity>[];
    }

    return _repository.getCookiesForDomain(domain);
  }

  Future<void> _openAddCookie() async {
    final didSave = await showRequestCookieEditorSheet(
      context,
      initialDomain: _requestDomain,
    );
    if (didSave == true && mounted) {
      setState(() {
        _cookiesFuture = _loadCookies();
      });
    }
  }

  Future<void> _openEditCookie(HttpCookieEntity cookie) async {
    final didSave = await showRequestCookieEditorSheet(
      context,
      cookie: cookie,
      initialDomain: _requestDomain,
    );
    if (didSave == true && mounted) {
      setState(() {
        _cookiesFuture = _loadCookies();
      });
    }
  }

  Future<void> _openCookieActions(HttpCookieEntity cookie) async {
    final action = await showModalBottomSheet<_CookieItemAction>(
      context: context,
      backgroundColor: context.appColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(AppStrings.cookiesEditAction),
              onTap: () =>
                  Navigator.of(context).pop(_CookieItemAction.edit),
            ),
            ListTile(
              title: Text(
                AppStrings.cookiesDeleteAction,
                style: TextStyle(color: context.appColors.methodDelete),
              ),
              onTap: () =>
                  Navigator.of(context).pop(_CookieItemAction.delete),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _CookieItemAction.edit:
        await _openEditCookie(cookie);
      case _CookieItemAction.delete:
        await _deleteCookie(cookie);
    }
  }

  Future<void> _deleteCookie(HttpCookieEntity cookie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cookiesDeleteTitle),
        content: const Text(AppStrings.cookiesDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.cookiesDeleteAction,
              style: TextStyle(color: context.appColors.methodDelete),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _repository.deleteCookie(cookie.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _cookiesFuture = _loadCookies();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete cookie.')),
      );
    }
  }

  Future<void> _openManageCookies() async {
    await showRequestManageCookiesSheet(context, initialDomain: _requestDomain);
    if (mounted) {
      setState(() {
        _cookiesFuture = _loadCookies();
      });
    }
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsCookiesSheet),
    child: Column(
      children: [
        _CookieSheetHeader(
          title: AppStrings.cookiesTitle,
          closeKey: AppWidgetKeys.requestsCookiesCloseButton,
          addKey: AppWidgetKeys.requestsCookiesAddButton,
          onClose: () => Navigator.of(context).pop(),
          onAdd: _openAddCookie,
        ),
        Expanded(
          child: FutureBuilder<List<HttpCookieEntity>>(
            future: _cookiesFuture,
            builder: (context, snapshot) {
              final cookies = snapshot.data ?? const <HttpCookieEntity>[];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (cookies.isEmpty) {
                return _CookiesEmptyState(
                  message: AppStrings.cookiesNoCookiesMessage,
                  onManageCookies: _openManageCookies,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  0,
                  AppSpacing.large,
                  AppSpacing.large,
                ),
                itemCount: cookies.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.small),
                itemBuilder: (context, index) {
                  if (index == cookies.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const ValueKey<String>(
                          AppWidgetKeys.requestsCookiesManageButton,
                        ),
                        onPressed: _openManageCookies,
                        child: const Text(AppStrings.cookiesManageLink),
                      ),
                    );
                  }

                  final cookie = cookies[index];
                  return KeyedSubtree(
                    key: ValueKey<String>(
                      AppWidgetKeys.requestsCookieListItemAt(index),
                    ),
                    child: _CookieListCard(
                      cookie: cookie,
                      onTap: () => _openEditCookie(cookie),
                      onLongPress: () => _openCookieActions(cookie),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

Future<void> showRequestManageCookiesSheet(
  BuildContext context, {
  String? initialDomain,
}) => showRequestModalSheet<void>(
  context,
  builder: (context) => _ManageCookiesSheet(initialDomain: initialDomain),
);

class _ManageCookiesSheet extends StatefulWidget {
  const _ManageCookiesSheet({this.initialDomain});

  final String? initialDomain;

  @override
  State<_ManageCookiesSheet> createState() => _ManageCookiesSheetState();
}

class _ManageCookiesSheetState extends State<_ManageCookiesSheet> {
  late final HttpCookieRepository _repository;
  late Future<List<HttpCookieEntity>> _cookiesFuture;
  String? _selectedDomain;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HttpCookieRepository>();
    _selectedDomain = widget.initialDomain;
    _cookiesFuture = _repository.getAllCookies();
  }

  Future<void> _reload() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cookiesFuture = _repository.getAllCookies();
    });
  }

  Future<void> _openAddCookie() async {
    final didSave = await showRequestCookieEditorSheet(
      context,
      initialDomain: _selectedDomain,
    );
    if (didSave == true) {
      await _reload();
    }
  }

  Future<void> _openEditCookie(HttpCookieEntity cookie) async {
    final didSave = await showRequestCookieEditorSheet(
      context,
      cookie: cookie,
      initialDomain: _selectedDomain,
    );
    if (didSave == true) {
      await _reload();
    }
  }

  Future<void> _deleteCookie(HttpCookieEntity cookie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cookiesDeleteTitle),
        content: const Text(AppStrings.cookiesDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.cookiesDeleteAction,
              style: TextStyle(color: context.appColors.methodDelete),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _repository.deleteCookie(cookie.id);
    await _reload();
  }

  Future<void> _openCookieActions(HttpCookieEntity cookie) async {
    final action = await showModalBottomSheet<_CookieItemAction>(
      context: context,
      backgroundColor: context.appColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(AppStrings.cookiesEditAction),
              onTap: () =>
                  Navigator.of(context).pop(_CookieItemAction.edit),
            ),
            ListTile(
              title: Text(
                AppStrings.cookiesDeleteAction,
                style: TextStyle(color: context.appColors.methodDelete),
              ),
              onTap: () =>
                  Navigator.of(context).pop(_CookieItemAction.delete),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _CookieItemAction.edit:
        await _openEditCookie(cookie);
      case _CookieItemAction.delete:
        await _deleteCookie(cookie);
    }
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsCookiesManageSheet),
    child: FutureBuilder<List<HttpCookieEntity>>(
      future: _cookiesFuture,
      builder: (context, snapshot) {
        final allCookies = snapshot.data ?? const <HttpCookieEntity>[];
        final allDomains = allCookies
            .map((cookie) => cookie.domain)
            .toSet()
            .toList(growable: false)
          ..sort();
        final visibleCookies = _selectedDomain == null
            ? allCookies
            : allCookies
                  .where((cookie) => cookie.domain == _selectedDomain)
                  .toList(growable: false);

        return Column(
          children: [
            _CookieSheetHeader(
              title: AppStrings.cookiesManageTitle,
              closeKey: AppWidgetKeys.requestsCookiesCloseButton,
              addKey: AppWidgetKeys.requestsCookiesAddButton,
              onClose: () => Navigator.of(context).pop(),
              onAdd: _openAddCookie,
              trailing: PopupMenuButton<String?>(
                key: const ValueKey<String>(
                  AppWidgetKeys.requestsCookiesFilterButton,
                ),
                tooltip: AppStrings.cookiesAllDomains,
                onSelected: (value) {
                  setState(() {
                    _selectedDomain = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String?>(
                    value: null,
                    child: Text(AppStrings.cookiesAllDomains),
                  ),
                  for (final domain in allDomains)
                    PopupMenuItem<String?>(
                      value: domain,
                      child: Text(domain),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                    vertical: AppSpacing.medium,
                  ),
                  child: Text(
                    _selectedDomain ?? AppStrings.cookiesAllDomains,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : visibleCookies.isEmpty
                  ? const _CookiesEmptyState(
                      message: AppStrings.cookiesEmptyManageMessage,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.large,
                        0,
                        AppSpacing.large,
                        AppSpacing.large,
                      ),
                      children: _buildGroupedCookieSections(visibleCookies),
                    ),
            ),
          ],
        );
      },
    ),
  );

  List<Widget> _buildGroupedCookieSections(List<HttpCookieEntity> cookies) {
    final groupedCookies = <String, List<HttpCookieEntity>>{};
    for (final cookie in cookies) {
      groupedCookies.putIfAbsent(cookie.domain, () => <HttpCookieEntity>[]).add(cookie);
    }

    final domains = groupedCookies.keys.toList(growable: false)..sort();
    final widgets = <Widget>[];

    for (final domain in domains) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Text(
            domain.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ),
      );

      final domainCookies = groupedCookies[domain]!
        ..sort((left, right) => left.name.compareTo(right.name));
      for (final cookie in domainCookies) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: _CookieListCard(
              cookie: cookie,
              onTap: () => _openEditCookie(cookie),
              onLongPress: () => _openCookieActions(cookie),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

Future<bool?> showRequestCookieEditorSheet(
  BuildContext context, {
  HttpCookieEntity? cookie,
  String? initialDomain,
}) => showRequestModalSheet<bool>(
  context,
  builder: (context) => _CookieEditorSheet(
    cookie: cookie,
    initialDomain: initialDomain,
  ),
);

class _CookieEditorSheet extends StatefulWidget {
  const _CookieEditorSheet({this.cookie, this.initialDomain});

  final HttpCookieEntity? cookie;
  final String? initialDomain;

  @override
  State<_CookieEditorSheet> createState() => _CookieEditorSheetState();
}

class _CookieEditorSheetState extends State<_CookieEditorSheet> {
  late final HttpCookieRepository _repository;
  late final TextEditingController _nameController;
  late final TextEditingController _domainController;
  late final TextEditingController _valueController;
  late final TextEditingController _pathController;
  late final TextEditingController _expiresController;
  late final TextEditingController _sameSiteController;

  late bool _secure;
  late bool _httpOnly;
  bool _isSaving = false;

  bool get _isEditing => widget.cookie != null;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HttpCookieRepository>();
    final cookie = widget.cookie;
    _nameController = TextEditingController(text: cookie?.name ?? '');
    _domainController = TextEditingController(
      text: cookie?.domain ?? (widget.initialDomain ?? ''),
    );
    _valueController = TextEditingController(text: cookie?.value ?? '');
    _pathController = TextEditingController(text: cookie?.path ?? '/');
    _expiresController = TextEditingController(
      text: cookie?.expiresAt?.toUtc().toIso8601String() ?? '',
    );
    _sameSiteController = TextEditingController(text: cookie?.sameSite ?? '');
    _secure = cookie?.secure ?? false;
    _httpOnly = cookie?.httpOnly ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    _valueController.dispose();
    _pathController.dispose();
    _expiresController.dispose();
    _sameSiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final normalizedName = _nameController.text.trim();
    final normalizedDomain = normalizeCookieDomainInput(_domainController.text);
    final normalizedPath = normalizeCookiePath(_pathController.text);
    final normalizedSameSite = normalizeCookieSameSite(_sameSiteController.text);

    if (normalizedName.isEmpty) {
      _showError('Name is required.');
      return;
    }

    if (normalizedDomain == null) {
      _showError('Domain must be a valid host without scheme or path.');
      return;
    }

    DateTime? expiresAt;
    final expiresInput = _expiresController.text.trim();
    if (expiresInput.isNotEmpty) {
      expiresAt = DateTime.tryParse(expiresInput)?.toUtc();
      if (expiresAt == null) {
        _showError('Expires must be a valid ISO-8601 datetime.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now().toUtc();
      final cookie = HttpCookieEntity(
        id: widget.cookie?.id ?? '',
        name: normalizedName,
        value: _valueController.text,
        domain: normalizedDomain,
        path: normalizedPath,
        expiresAt: expiresAt,
        secure: _secure,
        httpOnly: _httpOnly,
        sameSite: normalizedSameSite,
        createdAt: widget.cookie?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _repository.updateCookie(cookie);
      } else {
        await _repository.saveCookie(cookie);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      _showError('Could not save cookie.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => RequestModalSheetCard(
    key: const ValueKey<String>(AppWidgetKeys.requestsCookieEditorSheet),
    child: Column(
      children: [
        _CookieSheetHeader(
          title: _isEditing
              ? AppStrings.cookiesEditTitle
              : AppStrings.cookiesAddTitle,
          closeKey: AppWidgetKeys.requestsCookiesCloseButton,
          onClose: () => Navigator.of(context).pop(false),
          trailing: IconButton(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: AppSpacing.medium,
                    height: AppSpacing.medium,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.check_mark),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              0,
              AppSpacing.large,
              AppSpacing.large,
            ),
            children: [
              _CookieTextField(
                controller: _nameController,
                fieldKey: AppWidgetKeys.requestsCookieField('name'),
                label: AppStrings.cookiesName,
              ),
              const SizedBox(height: AppSpacing.small),
              _CookieTextField(
                controller: _domainController,
                fieldKey: AppWidgetKeys.requestsCookieField('domain'),
                label: AppStrings.cookiesDomain,
              ),
              const SizedBox(height: AppSpacing.small),
              _CookieTextField(
                controller: _expiresController,
                fieldKey: AppWidgetKeys.requestsCookieField('expires'),
                label: AppStrings.cookiesExpires,
                hintText: '2026-06-13T12:00:00Z',
              ),
              const SizedBox(height: AppSpacing.small),
              _CookieTextField(
                controller: _valueController,
                fieldKey: AppWidgetKeys.requestsCookieField('value'),
                label: AppStrings.cookiesValue,
              ),
              const SizedBox(height: AppSpacing.small),
              _CookieTextField(
                controller: _pathController,
                fieldKey: AppWidgetKeys.requestsCookieField('path'),
                label: AppStrings.cookiesPath,
              ),
              const SizedBox(height: AppSpacing.small),
              _CookieTextField(
                controller: _sameSiteController,
                fieldKey: AppWidgetKeys.requestsCookieField('same_site'),
                label: AppStrings.cookiesSameSite,
                hintText: 'Strict, Lax, None',
              ),
              const SizedBox(height: AppSpacing.small),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _secure,
                title: const Text(AppStrings.cookiesSecure),
                onChanged: (value) => setState(() => _secure = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _httpOnly,
                title: const Text(AppStrings.cookiesHttpOnly),
                onChanged: (value) => setState(() => _httpOnly = value),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CookieSheetHeader extends StatelessWidget {
  const _CookieSheetHeader({
    required this.title,
    required this.closeKey,
    required this.onClose,
    this.addKey,
    this.onAdd,
    this.trailing,
  });

  final String closeKey;
  final String? addKey;
  final VoidCallback onClose;
  final VoidCallback? onAdd;
  final Widget? trailing;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.medium,
      AppSpacing.small,
      AppSpacing.medium,
      AppSpacing.medium,
    ),
    child: Row(
      children: [
        IconButton(
          key: ValueKey<String>(closeKey),
          onPressed: onClose,
          icon: const Icon(CupertinoIcons.xmark),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        trailing ??
            IconButton(
              key: addKey == null ? null : ValueKey<String>(addKey!),
              onPressed: onAdd,
              icon: const Icon(CupertinoIcons.add),
            ),
      ],
    ),
  );
}

class _CookieListCard extends StatelessWidget {
  const _CookieListCard({
    required this.cookie,
    required this.onTap,
    required this.onLongPress,
  });

  final HttpCookieEntity cookie;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      cookie.domain,
      cookie.path,
      cookie.expiresAt == null
          ? AppStrings.cookiesSession
          : cookie.expiresAt!.toUtc().toIso8601String(),
      if (cookie.secure) AppStrings.cookiesSecure,
      if (cookie.httpOnly) AppStrings.cookiesHttpOnly,
    ].join(' • ');

    return Material(
      color: context.appColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cookie.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxSmall),
              Text(
                _previewValue(cookie.value),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxSmall),
              Text(
                meta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '(empty)';
    }

    if (trimmed.length <= 48) {
      return trimmed;
    }

    return '${trimmed.substring(0, 45)}...';
  }
}

class _CookiesEmptyState extends StatelessWidget {
  const _CookiesEmptyState({required this.message, this.onManageCookies});

  final String message;
  final VoidCallback? onManageCookies;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.cookiesNoCookiesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          if (onManageCookies != null) ...[
            const SizedBox(height: AppSpacing.medium),
            TextButton(
              key: const ValueKey<String>(
                AppWidgetKeys.requestsCookiesManageButton,
              ),
              onPressed: onManageCookies,
              child: const Text(AppStrings.cookiesManageLink),
            ),
          ],
        ],
      ),
    ),
  );
}

class _CookieTextField extends StatelessWidget {
  const _CookieTextField({
    required this.controller,
    required this.fieldKey,
    required this.label,
    this.hintText,
  });

  final TextEditingController controller;
  final String fieldKey;
  final String label;
  final String? hintText;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey<String>(fieldKey),
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: context.appColors.surface,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        borderSide: BorderSide(color: context.appColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        borderSide: BorderSide(color: context.appColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxLarge)),
        borderSide: BorderSide(color: context.appColors.primary),
      ),
    ),
  );
}

enum _CookieItemAction { edit, delete }
