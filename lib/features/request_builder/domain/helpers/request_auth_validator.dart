import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import 'digest_authorization_header_builder.dart';
import 'jwt_token_builder.dart';

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
RequestValidationResult validateAuthBeforeSend(
  RequestAuthDraft auth, {
  RequestBodyDraft? body,
}) {
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
    case AuthType.oauth1:
      if (auth.oauth1.consumerKey.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Consumer Key is required for OAuth 1.0a.',
        );
      }

      if (auth.oauth1.usesRsaSignature) {
        return const RequestValidationResult.invalid(
          'RSA signature methods are not implemented yet.',
        );
      }

      if (auth.oauth1.consumerSecret.isEmpty) {
        return const RequestValidationResult.invalid(
          'Consumer Secret is required for OAuth 1.0a.',
        );
      }

      return const RequestValidationResult.valid();
    case AuthType.jwt:
      final jwtBuildResult = const JwtTokenBuilder().build(auth.jwt);
      if (!jwtBuildResult.isValid) {
        return RequestValidationResult.invalid(
          jwtBuildResult.errorMessage ?? 'Could not build JWT.',
        );
      }

      return const RequestValidationResult.valid();
    case AuthType.digest:
      if (auth.digest.username.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Username is required for Digest.',
        );
      }

      if (auth.digest.password.isEmpty) {
        return const RequestValidationResult.invalid(
          'Password is required for Digest.',
        );
      }

      // Realm/nonce may stay empty: the send pipeline negotiates them through
      // the 401 challenge retry. A manual challenge must build cleanly though.
      if (auth.digest.hasManualChallenge) {
        final digestBuildResult = const DigestAuthorizationHeaderBuilder()
            .build(method: 'GET', url: '/', digest: auth.digest);
        if (!digestBuildResult.isValid) {
          return RequestValidationResult.invalid(
            digestBuildResult.errorMessage ??
                'Could not build Digest Authorization header.',
          );
        }
      }

      return const RequestValidationResult.valid();
    case AuthType.hawk:
      if (auth.hawk.identifier.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Auth ID is required for Hawk.',
        );
      }

      if (auth.hawk.key.isEmpty) {
        return const RequestValidationResult.invalid(
          'Auth Key is required for Hawk.',
        );
      }

      return const RequestValidationResult.valid();
    case AuthType.awsSignature:
      if (auth.aws.accessKey.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Access Key is required for AWS.',
        );
      }

      if (auth.aws.secretKey.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Secret Key is required for AWS.',
        );
      }

      if (auth.aws.region.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Region is required for AWS.',
        );
      }

      if (auth.aws.service.trim().isEmpty) {
        return const RequestValidationResult.invalid(
          'Service is required for AWS.',
        );
      }

      // The signed payload hash cannot match the multipart bytes built at
      // send time, so block instead of signing with a wrong hash.
      if (body?.type == RequestBodyType.formData) {
        return const RequestValidationResult.invalid(
          'AWS signing multipart body is not supported yet.',
        );
      }

      return const RequestValidationResult.valid();
    case AuthType.none:
    case AuthType.basic:
    case AuthType.apiKey:
    case AuthType.bearerToken:
    case AuthType.oauth2:
      return const RequestValidationResult.valid();
  }
}
