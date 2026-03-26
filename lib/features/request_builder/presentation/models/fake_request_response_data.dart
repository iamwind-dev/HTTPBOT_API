import 'package:equatable/equatable.dart';

import 'request_editor_response_badge_data.dart';

class FakeRequestResponseData extends Equatable {
  const FakeRequestResponseData({
    required this.badgeData,
    required this.prettyJsonBody,
  });

  final RequestEditorResponseBadgeData badgeData;
  final String prettyJsonBody;

  /// Returns a deterministic fake response for the current send or resend attempt.
  factory FakeRequestResponseData.forAttempt(int attempt) =>
      _responses[attempt % _responses.length];

  static const List<FakeRequestResponseData> _responses =
      <FakeRequestResponseData>[
        FakeRequestResponseData(
          badgeData: RequestEditorResponseBadgeData(
            statusCode: 200,
            payloadSizeBytes: 3072,
            durationMs: 180,
          ),
          prettyJsonBody: '''
[
  {
    "userId": 1,
    "id": 1,
    "title": "delectus aut autem",
    "completed": false
  },
  {
    "userId": 1,
    "id": 2,
    "title": "quis ut nam facilis et officia qui",
    "completed": false
  },
  {
    "userId": 1,
    "id": 3,
    "title": "fugiat veniam minus",
    "completed": false
  }
]''',
        ),
        FakeRequestResponseData(
          badgeData: RequestEditorResponseBadgeData(
            statusCode: 201,
            payloadSizeBytes: 1536,
            durationMs: 96,
          ),
          prettyJsonBody: '''
{
  "message": "HTTPBot fake response",
  "requestId": "fake-002",
  "accepted": true,
  "items": [
    1,
    2,
    3
  ]
}''',
        ),
      ];

  @override
  List<Object> get props => [badgeData, prettyJsonBody];
}
