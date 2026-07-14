import 'package:equatable/equatable.dart';

import 'request_auth_draft.dart';

class SavedCredential extends Equatable {
  const SavedCredential({
    required this.id,
    required this.name,
    required this.auth,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final RequestAuthDraft auth;
  final DateTime createdAt;
  final DateTime updatedAt;

  AuthType get type => auth.type;

  SavedCredential copyWith({
    String? id,
    String? name,
    RequestAuthDraft? auth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedCredential(
    id: id ?? this.id,
    name: name ?? this.name,
    auth: auth ?? this.auth,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object> get props => [id, name, auth, createdAt, updatedAt];
}
