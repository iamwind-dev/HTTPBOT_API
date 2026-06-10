import 'package:equatable/equatable.dart';

import 'request_auth_draft.dart';

/// A persisted auth credential the user can apply to the current request.
///
/// Only [AuthType.apiKey] is fully supported in this version; [apiKey] carries
/// the credential payload while [type] keeps room for future auth modes.
class SavedCredential extends Equatable {
  const SavedCredential({
    required this.id,
    required this.name,
    this.type = AuthType.apiKey,
    this.apiKey = const ApiKeyAuthDraft(),
  });

  final String id;
  final String name;
  final AuthType type;
  final ApiKeyAuthDraft apiKey;

  @override
  List<Object> get props => [id, name, type, apiKey];
}
