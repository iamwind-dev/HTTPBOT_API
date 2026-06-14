import 'package:equatable/equatable.dart';

class HttpCookieEntity extends Equatable {
  const HttpCookieEntity({
    required this.id,
    required this.name,
    required this.value,
    required this.domain,
    this.path = '/',
    this.expiresAt,
    this.secure = false,
    this.httpOnly = false,
    this.sameSite,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String value;
  final String domain;
  final String path;
  final DateTime? expiresAt;
  final bool secure;
  final bool httpOnly;
  final String? sameSite;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now().toUtc());

  HttpCookieEntity copyWith({
    String? id,
    String? name,
    String? value,
    String? domain,
    String? path,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    bool? secure,
    bool? httpOnly,
    String? sameSite,
    bool clearSameSite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HttpCookieEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    value: value ?? this.value,
    domain: domain ?? this.domain,
    path: path ?? this.path,
    expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    secure: secure ?? this.secure,
    httpOnly: httpOnly ?? this.httpOnly,
    sameSite: clearSameSite ? null : (sameSite ?? this.sameSite),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    value,
    domain,
    path,
    expiresAt,
    secure,
    httpOnly,
    sameSite,
    createdAt,
    updatedAt,
  ];
}
