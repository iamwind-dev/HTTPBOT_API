import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/keys/widget_keys.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/presentation/widgets/variable_rows_editor.dart';
import '../../domain/entities/collection_import_type.dart';
import '../../domain/entities/imported_collection_entity.dart';

import '../cubits/collection_ui_cubits.dart';

class CollectionEditorPage extends StatefulWidget {
  const CollectionEditorPage({
    required this.initialCollection,
    this.isCreating = false,
    super.key,
  });

  final ImportedCollectionEntity initialCollection;
  final bool isCreating;

  static ImportedCollectionEntity createDraft() {
    final now = DateTime.now();
    return ImportedCollectionEntity(
      id: 'collection_${now.microsecondsSinceEpoch}',
      name: '',
      description: '',
      importType: CollectionImportType.openApiSpec,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  State<CollectionEditorPage> createState() => _CollectionEditorPageState();
}

class _CollectionEditorPageState extends State<CollectionEditorPage> {
  late final TextEditingController _nameController;
  late final CollectionEditorFormCubit _formCubit;

  List<VariableRowData> get _variableRows => _formCubit.state.variableRows;
  RequestAuthDraft get _auth => _formCubit.state.auth;
  set _auth(RequestAuthDraft value) => _formCubit.updateAuth(value);
  bool get _isCompleting => _formCubit.state.isCompleting;
  set _isCompleting(bool value) {
    if (value) _formCubit.markCompleting();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCollection.name,
    );
    final variableRows = widget.initialCollection.variables
        .map(
          (item) => VariableRowData()
            ..keyController.text = item.name
            ..valueController.text = item.value
            ..isEnabled = item.isEnabled,
        )
        .toList(growable: true);
    _formCubit = CollectionEditorFormCubit(
      auth: widget.initialCollection.auth,
      variableRows: variableRows,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formCubit.close();
    super.dispose();
  }

  bool get _hasChanges {
    if (_nameController.text.trim() != widget.initialCollection.name.trim()) {
      return true;
    }

    if (_auth != widget.initialCollection.auth) {
      return true;
    }

    final initialVariables = widget.initialCollection.variables;
    final cleanedVariables = _buildVariables();
    if (initialVariables.length != cleanedVariables.length) {
      return true;
    }

    for (var index = 0; index < initialVariables.length; index++) {
      final initial = initialVariables[index];
      final current = cleanedVariables[index];
      if (initial.name != current.name ||
          initial.value != current.value ||
          initial.isEnabled != current.isEnabled) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionEditorFormCubit, CollectionEditorFormState>(
      bloc: _formCubit,
      builder: (context, state) {
        final colors = context.appColors;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, __) async {
            if (didPop || _isCompleting) {
              return;
            }
            await _close();
          },
          child: Scaffold(
            backgroundColor: colors.background,
            body: SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  32 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                children: [
                  Row(
                    children: [
                      _HeaderCircleButton(
                        buttonKey: const ValueKey<String>(
                          AppWidgetKeys.collectionsNewCollectionCloseButton,
                        ),
                        icon: Icons.close_rounded,
                        onTap: _close,
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
                        buttonKey: const ValueKey<String>(
                          AppWidgetKeys.collectionsNewCollectionSaveButton,
                        ),
                        icon: Icons.check_rounded,
                        filled: true,
                        onTap: _save,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _EditorCard(
                    child: TextField(
                      key: const ValueKey<String>(
                        AppWidgetKeys.collectionsNewCollectionNameField,
                      ),
                      controller: _nameController,
                      autofocus: widget.isCreating,
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
                    child: VariableRowsEditor(
                      rows: _variableRows,
                      onAddRow: _formCubit.addVariableRow,
                      onRemoveRow: _formCubit.removeVariableRow,
                      onChanged: _formCubit.variableChanged,
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
                    child: DropdownButtonFormField<AuthType>(
                      key: const ValueKey<String>(
                        AppWidgetKeys.collectionsNewCollectionAuthTypeField,
                      ),
                      initialValue: _auth.type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Auth',
                      ),
                      items: AuthType.values
                          .map(
                            (type) => DropdownMenuItem<AuthType>(
                              value: type,
                              child: Text(_authLabel(type)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (type) {
                        if (type == null) {
                          return;
                        }
                        _auth = _auth.copyWith(type: type);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildAuthConfiguration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthConfiguration() {
    return switch (_auth.type) {
      AuthType.none => const _AuthInfoCard(
        message: 'No authentication will be applied to this collection.',
      ),
      AuthType.basic => Column(
        children: [
          _AuthTextField(
            label: 'Username',
            initialValue: _auth.basic.username,
            onChanged: (value) => _auth = _auth.copyWith(
              basic: BasicAuthDraft(
                username: value,
                password: _auth.basic.password,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Password',
            initialValue: _auth.basic.password,
            obscureText: true,
            onChanged: (value) => _auth = _auth.copyWith(
              basic: BasicAuthDraft(
                username: _auth.basic.username,
                password: value,
              ),
            ),
          ),
        ],
      ),
      AuthType.apiKey => Column(
        children: [
          _AuthTextField(
            label: 'Key',
            initialValue: _auth.apiKey.name,
            onChanged: (value) => _auth = _auth.copyWith(
              apiKey: ApiKeyAuthDraft(
                name: value,
                value: _auth.apiKey.value,
                location: _auth.apiKey.location,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Value',
            initialValue: _auth.apiKey.value,
            onChanged: (value) => _auth = _auth.copyWith(
              apiKey: ApiKeyAuthDraft(
                name: _auth.apiKey.name,
                value: value,
                location: _auth.apiKey.location,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AuthDropdownField<ApiKeyLocation>(
            label: 'Send as',
            value: _auth.apiKey.location,
            items: ApiKeyLocation.values,
            itemLabel: (item) => item.label,
            onChanged: (value) {
              _auth = _auth.copyWith(
                apiKey: ApiKeyAuthDraft(
                  name: _auth.apiKey.name,
                  value: _auth.apiKey.value,
                  location: value,
                ),
              );
            },
          ),
        ],
      ),
      AuthType.bearerToken => Column(
        children: [
          _AuthTextField(
            label: 'Token',
            initialValue: _auth.bearerToken.token,
            onChanged: (value) => _auth = _auth.copyWith(
              bearerToken: BearerTokenAuthDraft(
                token: value,
                prefix: _auth.bearerToken.prefix,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Prefix',
            initialValue: _auth.bearerToken.prefix,
            onChanged: (value) => _auth = _auth.copyWith(
              bearerToken: BearerTokenAuthDraft(
                token: _auth.bearerToken.token,
                prefix: value,
              ),
            ),
          ),
        ],
      ),
      AuthType.digest => Column(
        children: [
          _AuthTextField(
            label: 'Username',
            initialValue: _auth.digest.username,
            onChanged: (value) => _updateDigest(username: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Password',
            initialValue: _auth.digest.password,
            obscureText: true,
            onChanged: (value) => _updateDigest(password: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Realm',
            initialValue: _auth.digest.realm,
            onChanged: (value) => _updateDigest(realm: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Nonce',
            initialValue: _auth.digest.nonce,
            onChanged: (value) => _updateDigest(nonce: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Algorithm',
            initialValue: _auth.digest.algorithm,
            onChanged: (value) => _updateDigest(algorithm: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'QOP',
            initialValue: _auth.digest.qop,
            onChanged: (value) => _updateDigest(qop: value),
          ),
        ],
      ),
      AuthType.hawk => Column(
        children: [
          _AuthTextField(
            label: 'Auth ID',
            initialValue: _auth.hawk.identifier,
            onChanged: (value) => _updateHawk(identifier: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Auth Key',
            initialValue: _auth.hawk.key,
            obscureText: true,
            onChanged: (value) => _updateHawk(key: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Algorithm',
            initialValue: _auth.hawk.algorithm,
            onChanged: (value) => _updateHawk(algorithm: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Nonce',
            initialValue: _auth.hawk.nonce,
            onChanged: (value) => _updateHawk(nonce: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Timestamp',
            initialValue: _auth.hawk.timestamp,
            onChanged: (value) => _updateHawk(timestamp: value),
          ),
          const SizedBox(height: 10),
          _AuthSwitchField(
            label: 'Include payload hash',
            value: _auth.hawk.includePayloadHash,
            onChanged: (value) {
              _updateHawk(includePayloadHash: value);
            },
          ),
        ],
      ),
      AuthType.jwt => Column(
        children: [
          _AuthTextField(
            label: 'Token',
            initialValue: _auth.jwt.token,
            onChanged: (value) => _updateJwt(token: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Header',
            initialValue: _auth.jwt.header,
            onChanged: (value) => _updateJwt(header: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Payload',
            initialValue: _auth.jwt.payload,
            onChanged: (value) => _updateJwt(payload: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Secret',
            initialValue: _auth.jwt.secret,
            obscureText: true,
            onChanged: (value) => _updateJwt(secret: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Algorithm',
            initialValue: _auth.jwt.algorithm,
            onChanged: (value) => _updateJwt(algorithm: value),
          ),
          const SizedBox(height: 10),
          _AuthSwitchField(
            label: 'Send as header',
            value: _auth.jwt.sendAsHeader,
            onChanged: (value) {
              _updateJwt(sendAsHeader: value);
            },
          ),
        ],
      ),
      AuthType.ntlm => Column(
        children: [
          _AuthTextField(
            label: 'Username',
            initialValue: _auth.ntlm.username,
            onChanged: (value) => _updateNtlm(username: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Password',
            initialValue: _auth.ntlm.password,
            obscureText: true,
            onChanged: (value) => _updateNtlm(password: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Domain',
            initialValue: _auth.ntlm.domain,
            onChanged: (value) => _updateNtlm(domain: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Workstation',
            initialValue: _auth.ntlm.workstation,
            onChanged: (value) => _updateNtlm(workstation: value),
          ),
        ],
      ),
      AuthType.awsSignature => Column(
        children: [
          _AuthTextField(
            label: 'Access Key',
            initialValue: _auth.aws.accessKey,
            onChanged: (value) => _updateAws(accessKey: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Secret Key',
            initialValue: _auth.aws.secretKey,
            obscureText: true,
            onChanged: (value) => _updateAws(secretKey: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Region',
            initialValue: _auth.aws.region,
            onChanged: (value) => _updateAws(region: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Service',
            initialValue: _auth.aws.service,
            onChanged: (value) => _updateAws(service: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Session Token',
            initialValue: _auth.aws.sessionToken,
            onChanged: (value) => _updateAws(sessionToken: value),
          ),
        ],
      ),
      AuthType.oauth1 => Column(
        children: [
          _AuthTextField(
            label: 'Consumer Key',
            initialValue: _auth.oauth1.consumerKey,
            onChanged: (value) => _updateOAuth1(consumerKey: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Consumer Secret',
            initialValue: _auth.oauth1.consumerSecret,
            obscureText: true,
            onChanged: (value) => _updateOAuth1(consumerSecret: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Token',
            initialValue: _auth.oauth1.token,
            onChanged: (value) => _updateOAuth1(token: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Token Secret',
            initialValue: _auth.oauth1.tokenSecret,
            obscureText: true,
            onChanged: (value) => _updateOAuth1(tokenSecret: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Signature Method',
            initialValue: _auth.oauth1.signatureMethod,
            onChanged: (value) => _updateOAuth1(signatureMethod: value),
          ),
          const SizedBox(height: 10),
          _AuthSwitchField(
            label: 'Send as header',
            value: _auth.oauth1.asHeader,
            onChanged: (value) {
              _updateOAuth1(asHeader: value);
            },
          ),
        ],
      ),
      AuthType.oauth2 => Column(
        children: [
          _AuthDropdownField<OAuth2GrantType>(
            label: 'Grant Type',
            value: _auth.oauth2.grantType,
            items: OAuth2GrantType.values,
            itemLabel: (item) => item.label,
            onChanged: (value) {
              _updateOAuth2(grantType: value);
            },
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Access Token',
            initialValue: _auth.oauth2.accessToken,
            onChanged: (value) => _updateOAuth2(accessToken: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Authorization URL',
            initialValue: _auth.oauth2.authorizationUrl,
            onChanged: (value) => _updateOAuth2(authorizationUrl: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Access Token URL',
            initialValue: _auth.oauth2.accessTokenUrl,
            onChanged: (value) => _updateOAuth2(accessTokenUrl: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Client ID',
            initialValue: _auth.oauth2.clientId,
            onChanged: (value) => _updateOAuth2(clientId: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Client Secret',
            initialValue: _auth.oauth2.clientSecret,
            obscureText: true,
            onChanged: (value) => _updateOAuth2(clientSecret: value),
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            label: 'Scope',
            initialValue: _auth.oauth2.scope,
            onChanged: (value) => _updateOAuth2(scope: value),
          ),
          const SizedBox(height: 10),
          _AuthSwitchField(
            label: 'Add token to header',
            value: _auth.oauth2.addTokenToHeader,
            onChanged: (value) {
              _updateOAuth2(addTokenToHeader: value);
            },
          ),
        ],
      ),
    };
  }

  void _updateDigest({
    String? username,
    String? password,
    String? realm,
    String? nonce,
    String? algorithm,
    String? qop,
  }) {
    _auth = _auth.copyWith(
      digest: _auth.digest.copyWith(
        username: username,
        password: password,
        realm: realm,
        nonce: nonce,
        algorithm: algorithm,
        qop: qop,
      ),
    );
  }

  void _updateHawk({
    String? identifier,
    String? key,
    String? algorithm,
    String? nonce,
    String? timestamp,
    bool? includePayloadHash,
  }) {
    _auth = _auth.copyWith(
      hawk: _auth.hawk.copyWith(
        identifier: identifier,
        key: key,
        algorithm: algorithm,
        nonce: nonce,
        timestamp: timestamp,
        includePayloadHash: includePayloadHash,
      ),
    );
  }

  void _updateJwt({
    String? token,
    String? header,
    String? payload,
    String? secret,
    String? algorithm,
    bool? sendAsHeader,
  }) {
    _auth = _auth.copyWith(
      jwt: _auth.jwt.copyWith(
        token: token,
        header: header,
        payload: payload,
        secret: secret,
        algorithm: algorithm,
        sendAsHeader: sendAsHeader,
      ),
    );
  }

  void _updateNtlm({
    String? username,
    String? password,
    String? domain,
    String? workstation,
  }) {
    _auth = _auth.copyWith(
      ntlm: _auth.ntlm.copyWith(
        username: username,
        password: password,
        domain: domain,
        workstation: workstation,
      ),
    );
  }

  void _updateAws({
    String? accessKey,
    String? secretKey,
    String? region,
    String? service,
    String? sessionToken,
  }) {
    _auth = _auth.copyWith(
      aws: AwsAuthDraft(
        accessKey: accessKey ?? _auth.aws.accessKey,
        secretKey: secretKey ?? _auth.aws.secretKey,
        region: region ?? _auth.aws.region,
        service: service ?? _auth.aws.service,
        sessionToken: sessionToken ?? _auth.aws.sessionToken,
      ),
    );
  }

  void _updateOAuth1({
    String? consumerKey,
    String? consumerSecret,
    String? token,
    String? tokenSecret,
    String? signatureMethod,
    bool? asHeader,
  }) {
    _auth = _auth.copyWith(
      oauth1: _auth.oauth1.copyWith(
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
        token: token,
        tokenSecret: tokenSecret,
        signatureMethod: signatureMethod,
        asHeader: asHeader,
      ),
    );
  }

  void _updateOAuth2({
    OAuth2GrantType? grantType,
    String? accessToken,
    String? authorizationUrl,
    String? accessTokenUrl,
    String? clientId,
    String? clientSecret,
    String? scope,
    bool? addTokenToHeader,
  }) {
    _auth = _auth.copyWith(
      oauth2: _auth.oauth2.copyWith(
        grantType: grantType,
        accessToken: accessToken,
        authorizationUrl: authorizationUrl,
        accessTokenUrl: accessTokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        scope: scope,
        addTokenToHeader: addTokenToHeader,
      ),
    );
  }

  Future<void> _close() async {
    if (!_hasChanges) {
      _isCompleting = true;
      Navigator.of(context).pop();
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your collection changes have not been saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDiscard != true) {
      return;
    }

    _isCompleting = true;
    Navigator.of(context).pop();
  }

  void _save() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection name is required.')),
      );
      return;
    }

    _isCompleting = true;
    Navigator.of(context).pop(
      widget.initialCollection.copyWith(
        name: trimmedName,
        variables: _buildVariables(),
        auth: _auth,
        updatedAt: DateTime.now(),
      ),
    );
  }

  List<ImportedCollectionVariableEntity> _buildVariables() => _variableRows
      .map(
        (row) => ImportedCollectionVariableEntity(
          name: row.keyController.text.trim(),
          value: row.valueController.text.trim(),
          isEnabled: row.isEnabled,
        ),
      )
      .where((item) => item.name.isNotEmpty)
      .toList(growable: false);

  String _authLabel(AuthType type) {
    if (type == AuthType.awsSignature) {
      return 'AWS';
    }

    return type.label;
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(26),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: child,
  );
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.obscureText = false,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _EditorCard(
      child: TextFormField(
        initialValue: initialValue,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
      ),
    );
  }
}

class _AuthDropdownField<T> extends StatelessWidget {
  const _AuthDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _AuthSwitchField extends StatelessWidget {
  const _AuthSwitchField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _EditorCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AuthInfoCard extends StatelessWidget {
  const _AuthInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Text(
        message,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.buttonKey,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
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
