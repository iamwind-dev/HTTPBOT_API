import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/core/constants/app_strings.dart';
import 'package:httpbot_api/core/keys/widget_keys.dart';
import 'package:httpbot_api/core/services/external_uri_launcher.dart';
import 'package:httpbot_api/core/services/oauth2_callback_service.dart';
import 'package:httpbot_api/core/theme/app_theme.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/oauth2_token_details_entity.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_auth_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_draft.dart';
import 'package:httpbot_api/features/request_builder/domain/entities/request_variable_store.dart';
import 'package:httpbot_api/features/request_builder/domain/usecases/exchange_oauth2_authorization_code_use_case.dart';
import 'package:httpbot_api/features/request_builder/presentation/widgets/request_editor_sheet.dart';
import 'package:httpbot_api/injection/injection.dart';

void main() {
  setUpAll(configureDependencies);

  group('request editor auth header UI sync', () {
    testWidgets(
      'should show authorization header row when bearer token auth is entered',
      (tester) async {
        final robot = RequestEditorSheetRobot(tester);

        await robot.pumpScreen();
        await robot.openEditor();
        await robot.selectAuthType(AuthType.bearerToken);
        await robot.enterAuthField('bearer_token', 'abc123');

        robot.expectHeaderValue(
          section: 'headers',
          index: 0,
          field: 'key',
          value: 'Authorization',
        );
        robot.expectHeaderValue(
          section: 'headers',
          index: 0,
          field: 'value',
          value: 'Bearer abc123',
        );
        robot.expectTextVisible('Bearer');
      },
    );

    testWidgets(
      'should show API key query parameter when API key auth targets query params',
      (tester) async {
        final robot = RequestEditorSheetRobot(tester);

        await robot.pumpScreen();
        await robot.openEditor();
        await robot.selectAuthType(AuthType.apiKey);
        await robot.selectApiKeyName('api_key');
        await robot.setApiKeySendAsHeader(false);
        await robot.enterAuthField('api_key_value', 'abc123');

        robot.expectHeaderValue(
          section: 'query',
          index: 0,
          field: 'key',
          value: 'api_key',
        );
        robot.expectHeaderValue(
          section: 'query',
          index: 0,
          field: 'value',
          value: 'abc123',
        );
        robot.expectTextVisible(
          'API Key is synced to Query Params as api_key.',
        );
      },
    );

    testWidgets(
      'should show OAuth2 manual controls and generated Authorization header',
      (tester) async {
        final robot = RequestEditorSheetRobot(tester);

        await robot.pumpScreen(
          initialDraft: const RequestDraft(
            auth: RequestAuthDraft(type: AuthType.oauth2),
          ),
        );
        await robot.openEditor();
        await robot.enterAuthField('oauth2_access_token', 'abc123');

        robot.expectTextVisible('Token');
        robot.expectTextVisible('As Header');
        robot.expectTextVisible('Header Prefix');
        robot.expectTextVisible('Validity');
        robot.expectTextVisible('No expiry');
        robot.expectTextVisible('Configure');
        robot.expectTextVisible('Manual');
        robot.expectHeaderValue(
          section: 'headers',
          index: 0,
          field: 'key',
          value: 'Authorization',
        );
        robot.expectHeaderValue(
          section: 'headers',
          index: 0,
          field: 'value',
          value: 'Bearer abc123',
        );
      },
    );

    testWidgets(
      'should complete OAuth2 authorization code flow from deep link callback',
      (tester) async {
        final callbackService = FakeOAuth2CallbackService();
        final launcher = FakeExternalUriLauncher();
        final exchangeUseCase = FakeExchangeOAuth2AuthorizationCodeUseCase();

        if (getIt.isRegistered<OAuth2CallbackService>()) {
          getIt.unregister<OAuth2CallbackService>();
        }
        if (getIt.isRegistered<ExternalUriLauncher>()) {
          getIt.unregister<ExternalUriLauncher>();
        }
        if (getIt.isRegistered<ExchangeOAuth2AuthorizationCodeUseCase>()) {
          getIt.unregister<ExchangeOAuth2AuthorizationCodeUseCase>();
        }

        getIt.registerSingleton<OAuth2CallbackService>(callbackService);
        getIt.registerSingleton<ExternalUriLauncher>(launcher);
        getIt.registerSingleton<ExchangeOAuth2AuthorizationCodeUseCase>(
          exchangeUseCase,
        );

        launcher.onLaunch = (uri) {
          final state = uri.queryParameters['state'] ?? '';
          callbackService.emit(
            Uri.parse('httpbot://oauth/callback?code=auth-code&state=$state'),
          );
        };

        final robot = RequestEditorSheetRobot(tester);

        await robot.pumpScreen(
          initialDraft: const RequestDraft(
            auth: RequestAuthDraft(
              type: AuthType.oauth2,
              oauth2: OAuth2AuthDraft(
                grantType: OAuth2GrantType.authorizationCode,
                authorizationUrl: 'https://github.com/login/oauth/authorize',
                accessTokenUrl: 'https://github.com/login/oauth/access_token',
                clientId: 'client-id',
                clientSecret: 'client-secret',
                redirectUri: defaultOAuth2MobileRedirectUri,
                clientAuthentication: OAuth2ClientAuthentication.requestBody,
              ),
            ),
          ),
        );
        await robot.openEditor();
        await robot.openOAuth2Configure();
        await robot.tapGetAccessToken();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(launcher.lastLaunchedUri?.host, 'github.com');
        expect(exchangeUseCase.lastCode, 'auth-code');
        robot.expectTextVisible(
          AppStrings.requestEditorOAuth2TokenDetailsTitle,
        );
        await robot.closeTopSheet();
        robot.expectHeaderValue(
          section: 'headers',
          index: 0,
          field: 'key',
          value: 'Authorization',
        );
        robot.expectHeaderValue(
          section: 'headers',
          index: 0,
          field: 'value',
          value: 'Bearer oauth-access-token',
        );
        await robot.openOAuth2Configure();
        robot.expectAuthFieldValue(
          'oauth2_sheet_access_token',
          'oauth-access-token',
        );
      },
    );

    testWidgets(
      'should show NTLM username, password, and domain fields',
      (tester) async {
        final robot = RequestEditorSheetRobot(tester);

        await robot.pumpScreen(
          initialDraft: const RequestDraft(
            auth: RequestAuthDraft(type: AuthType.ntlm),
          ),
        );
        await robot.openEditor();
        await robot.enterAuthField('ntlm_username', 'svc-user');
        await robot.enterAuthField('ntlm_password', 'secret');
        await robot.enterAuthField('ntlm_domain', 'CORP');

        robot.expectAuthFieldValue('ntlm_username', 'svc-user');
        robot.expectAuthFieldValue('ntlm_password', 'secret');
        robot.expectAuthFieldValue('ntlm_domain', 'CORP');
        robot.expectTextVisible(
          'NTLM authenticates the connection during send; no Authorization header is added here.',
        );
      },
    );
  });
}

class RequestEditorSheetRobot {
  RequestEditorSheetRobot(this.tester);

  final WidgetTester tester;

  /// Pumps a minimal host screen that can open the request editor sheet.
  Future<void> pumpScreen({
    RequestDraft initialDraft = const RequestDraft(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showRequestEditorSheet(
                    context,
                    title: 'Request',
                    initialDraft: initialDraft,
                    variableStore: const RequestVariableStore(),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the request editor sheet from the host screen.
  Future<void> openEditor() async {
    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>(AppWidgetKeys.requestsEditorSheet)),
      findsOneWidget,
    );
  }

  /// Selects the auth mode from the auth dropdown.
  Future<void> selectAuthType(AuthType type) async {
    final dropdownFinder = find.byKey(
      const ValueKey<String>(AppWidgetKeys.requestsEditorAuthTypeField),
    );
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final optionFinder = find.text(type.label).last;
    await tester.ensureVisible(optionFinder);
    await tester.tap(optionFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Enters one auth credential field by semantic field key.
  Future<void> enterAuthField(String fieldName, String value) async {
    final fieldFinder = find.byKey(
      ValueKey<String>(AppWidgetKeys.requestsEditorAuthField(fieldName)),
    );
    await tester.ensureVisible(fieldFinder);
    await tester.enterText(fieldFinder, value);
    await tester.pumpAndSettle();
  }

  /// Opens the OAuth2 configuration sheet from the auth section.
  Future<void> openOAuth2Configure() async {
    final buttonFinder = find.byKey(
      const ValueKey<String>(AppWidgetKeys.requestsEditorOAuth2ConfigureButton),
    );
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  /// Taps the OAuth2 access-token action button inside the config sheet.
  Future<void> tapGetAccessToken() async {
    final buttonFinder = find.byKey(
      const ValueKey<String>(
        AppWidgetKeys.requestsEditorOAuth2GetAccessTokenButton,
      ),
    );
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
  }

  /// Closes the currently visible top sheet through its Done action.
  Future<void> closeTopSheet() async {
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();
  }

  /// Selects one API key name option from the auth name dropdown.
  Future<void> selectApiKeyName(String name) async {
    final fieldFinder = find.byKey(
      ValueKey<String>(AppWidgetKeys.requestsEditorAuthField('api_key_name')),
    );
    await tester.ensureVisible(fieldFinder);
    await tester.tap(fieldFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  /// Toggles the API key location switch to the requested header/query mode.
  Future<void> setApiKeySendAsHeader(bool sendAsHeader) async {
    final switchFinder = find.byKey(
      const ValueKey<String>(
        'requests_editor_auth_api_key_send_as_header_switch',
      ),
    );
    await tester.ensureVisible(switchFinder);
    final toggle = tester.widget<Switch>(switchFinder);

    if (toggle.value != sendAsHeader) {
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    }
  }

  /// Verifies one generated header field value in the headers section.
  void expectHeaderValue({
    required String section,
    required int index,
    required String field,
    required String value,
  }) {
    final fieldKey = switch (field) {
      'key' => AppWidgetKeys.requestsEditorKeyValueKeyField(section, index),
      'value' => AppWidgetKeys.requestsEditorKeyValueValueField(section, index),
      _ => throw ArgumentError.value(field, 'field', 'Unsupported field'),
    };
    final textField = tester.widget<TextFormField>(
      find.byKey(ValueKey<String>(fieldKey)),
    );

    expect(textField.controller?.text, value);
  }

  /// Verifies a visible text label in the current sheet.
  void expectTextVisible(String text) {
    expect(find.text(text), findsWidgets);
  }

  /// Verifies an auth text field value by semantic field key.
  void expectAuthFieldValue(String fieldName, String value) {
    final fieldFinder = find.byKey(
      ValueKey<String>(AppWidgetKeys.requestsEditorAuthField(fieldName)),
    );
    final textField = tester.widget<TextFormField>(fieldFinder.last);
    expect(textField.controller?.text, value);
  }
}

class FakeOAuth2CallbackService implements OAuth2CallbackService {
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  Uri? _pendingCallback;

  @override
  Stream<Uri> get callbackStream => _controller.stream;

  @override
  void clearPendingCallback() {
    _pendingCallback = null;
  }

  /// Emits one OAuth2 callback into the fake service.
  void emit(Uri uri) {
    _pendingCallback = uri;
    _controller.add(uri);
  }

  @override
  Future<void> initialize() async {}

  @override
  bool matchesCallback(Uri uri) =>
      uri.scheme == 'httpbot' && uri.host == 'oauth' && uri.path == '/callback';

  @override
  Uri? takePendingCallback() {
    final pendingCallback = _pendingCallback;
    _pendingCallback = null;
    return pendingCallback;
  }
}

class FakeExternalUriLauncher implements ExternalUriLauncher {
  Uri? lastLaunchedUri;
  void Function(Uri uri)? onLaunch;

  @override
  /// Records the launched URI and optionally emits a callback for the test.
  Future<bool> launchExternal(Uri uri) async {
    lastLaunchedUri = uri;
    onLaunch?.call(uri);
    return true;
  }
}

class FakeExchangeOAuth2AuthorizationCodeUseCase
    implements ExchangeOAuth2AuthorizationCodeUseCase {
  String? lastCode;

  @override
  /// Returns a fixed token so the widget test can verify OAuth2 UI synchronization.
  Future<OAuth2TokenDetailsEntity> call({
    required OAuth2AuthDraft auth,
    required String code,
  }) async {
    lastCode = code;
    return const OAuth2TokenDetailsEntity(
      success: true,
      resolvedAuthUrl: '',
      accessToken: 'oauth-access-token',
      tokenType: 'Bearer',
      scope: 'read:user,user:email',
      request: OAuth2TokenRequestDebugInfo(
        method: 'POST',
        url: 'https://github.com/login/oauth/access_token',
        headers: <String, String>{'Accept': 'application/json'},
        bodyFields: <String, String>{'grant_type': 'authorization_code'},
        encodedBody: 'grant_type=authorization_code',
      ),
      response: OAuth2TokenResponseDebugInfo(
        statusCode: 200,
        headers: <String, String>{'content-type': 'application/json'},
        jsonBody: <String, Object?>{
          'access_token': 'oauth-access-token',
          'token_type': 'Bearer',
        },
        rawBody: '{"access_token":"oauth-access-token","token_type":"Bearer"}',
      ),
    );
  }
}
