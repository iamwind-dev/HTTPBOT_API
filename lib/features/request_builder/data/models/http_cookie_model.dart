import '../../domain/entities/http_cookie_entity.dart';

class HttpCookieModel {
  const HttpCookieModel({
    required this.id,
    required this.name,
    required this.value,
    required this.domain,
    required this.path,
    required this.expiresAt,
    required this.secure,
    required this.httpOnly,
    required this.sameSite,
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

  factory HttpCookieModel.fromEntity(HttpCookieEntity entity) => HttpCookieModel(
    id: entity.id,
    name: entity.name,
    value: entity.value,
    domain: entity.domain,
    path: entity.path,
    expiresAt: entity.expiresAt,
    secure: entity.secure,
    httpOnly: entity.httpOnly,
    sameSite: entity.sameSite,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );

  factory HttpCookieModel.fromJson(Map<String, dynamic> json) => HttpCookieModel(
    id: (json['id'] as String? ?? '').trim(),
    name: (json['name'] as String? ?? '').trim(),
    value: json['value'] as String? ?? '',
    domain: (json['domain'] as String? ?? '').trim().toLowerCase(),
    path: _normalizePath(json['path'] as String?),
    expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toUtc(),
    secure: json['secure'] as bool? ?? false,
    httpOnly: json['httpOnly'] as bool? ?? false,
    sameSite: _normalizeSameSite(json['sameSite'] as String?),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  HttpCookieEntity toEntity() => HttpCookieEntity(
    id: id,
    name: name,
    value: value,
    domain: domain,
    path: path,
    expiresAt: expiresAt,
    secure: secure,
    httpOnly: httpOnly,
    sameSite: sameSite,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'domain': domain,
    'path': path,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'secure': secure,
    'httpOnly': httpOnly,
    'sameSite': sameSite,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static String _normalizePath(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '/';
    }

    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static String? _normalizeSameSite(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'strict' => 'Strict',
      'lax' => 'Lax',
      'none' => 'None',
      _ => null,
    };
  }
}
