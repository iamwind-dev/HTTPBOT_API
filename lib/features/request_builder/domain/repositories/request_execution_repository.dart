import '../entities/auth_applied_request.dart';
import '../entities/request_execution_result.dart';

abstract interface class RequestExecutionRepository {
  /// Sends the prepared request through the configured transport and returns raw execution metadata.
  Future<RequestExecutionResult> executeRequest(AuthAppliedRequest request);
}
