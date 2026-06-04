import '../entities/auth_applied_request.dart';
import '../entities/request_execution_result.dart';
import '../repositories/request_execution_repository.dart';

class ExecuteRequestUseCase {
  const ExecuteRequestUseCase(this._repository);

  final RequestExecutionRepository _repository;

  /// Executes the request only when earlier resolver and auth steps produced no blocking issues.
  Future<RequestExecutionResult> call(AuthAppliedRequest request) async {
    if (request.hasBlockingIssues) {
      return RequestExecutionResult(
        request: request.request,
        errorType: RequestExecutionErrorType.blocked,
        errorMessage:
            'Request execution was blocked because validation or auth issues are still present.',
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    }

    return _repository.executeRequest(request);
  }
}
