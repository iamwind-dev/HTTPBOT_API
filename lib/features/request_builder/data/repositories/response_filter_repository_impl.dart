import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/response_filter_entity.dart';
import '../../domain/helpers/filter_response_mode.dart';
import '../../domain/repositories/response_filter_repository.dart';

class ResponseFilterRepositoryImpl implements ResponseFilterRepository {
  static const _storageKey = 'response_filters';

  @override
  Future<List<ResponseFilterEntity>> getFilters() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <ResponseFilterEntity>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ResponseFilterEntity>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList(growable: false);
    } on FormatException {
      return const <ResponseFilterEntity>[];
    }
  }

  @override
  Future<ResponseFilterEntity> saveFilter(ResponseFilterEntity filter) async {
    final filters = List<ResponseFilterEntity>.of(await getFilters())
      ..add(filter);
    await _persist(filters);
    return filter;
  }

  @override
  Future<ResponseFilterEntity> updateFilter(ResponseFilterEntity filter) async {
    final filters = await getFilters();
    final updated = filters
        .map((existing) => existing.id == filter.id ? filter : existing)
        .toList(growable: false);
    await _persist(updated);
    return filter;
  }

  @override
  Future<void> deleteFilter(String id) async {
    final filters = await getFilters();
    final remaining = filters
        .where((existing) => existing.id != id)
        .toList(growable: false);
    await _persist(remaining);
  }

  Future<void> _persist(List<ResponseFilterEntity> filters) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      filters.map(_toJson).toList(growable: false),
    );
    await preferences.setString(_storageKey, encoded);
  }

  Map<String, dynamic> _toJson(ResponseFilterEntity filter) => {
    'id': filter.id,
    'name': filter.name,
    'query': filter.query,
    'mode': filter.mode.name,
    'createdAt': filter.createdAt.toIso8601String(),
    'updatedAt': filter.updatedAt.toIso8601String(),
  };

  ResponseFilterEntity _fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String?;
    final mode = FilterResponseMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => FilterResponseMode.jq,
    );
    final now = DateTime.now();
    return ResponseFilterEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      query: json['query'] as String? ?? '',
      mode: mode,
      createdAt: _parseDate(json['createdAt']) ?? now,
      updatedAt: _parseDate(json['updatedAt']) ?? now,
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
