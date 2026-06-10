import '../entities/request_auth_draft.dart';

class RequestValidationResult {
  /// Wraps a pre-send validation outcome so send pipelines can short-circuit cleanly.
  const RequestValidationResult._({required this.isValid, this.errorMessage});

  /// Creates a successful validation result with no user-facing error.
  const RequestValidationResult.valid() : this._(isValid: true);

  /// Creates a failed validation result with a stable user-facing message.
  const RequestValidationResult.invalid(String message)
    : this._(isValid: false, errorMessage: message);

  final bool isValid;
  final String? errorMessage;
}

/// Validates auth-specific prerequisites before the request send pipeline starts.
RequestValidationResult validateAuthBeforeSend(RequestAuthDraft auth) {
  switch (auth.type) {
    case AuthType.ntlm:
      if (auth.ntlm.username.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Username is required for NTLM.',
        );
      }

      if (auth.ntlm.password.isEmpty) {
        return const RequestValidationResult.invalid(
          'Password is required for NTLM.',
        );
      }

      return const RequestValidationResult.valid();
    case AuthType.none:
    case AuthType.basic:
    case AuthType.apiKey:
    case AuthType.bearerToken:
    case AuthType.digest:
    case AuthType.hawk:
    case AuthType.jwt:
    case AuthType.awsSignature:
    case AuthType.oauth1:
    case AuthType.oauth2:
      return const RequestValidationResult.valid();
  }
}
