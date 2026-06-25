import 'package:equatable/equatable.dart';

enum RequestTestResultStatus { passed, failed, error }

class RequestTestResult extends Equatable {
  const RequestTestResult({
    required this.testId,
    required this.label,
    required this.status,
    this.expected,
    this.actual,
    this.message,
  });

  final String testId;
  final String label;
  final RequestTestResultStatus status;
  final String? expected;
  final String? actual;
  final String? message;

  bool get isPassed => status == RequestTestResultStatus.passed;

  @override
  List<Object?> get props => [testId, label, status, expected, actual, message];
}
