import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/response_filter.dart';
import '../../domain/repositories/response_filters_repository.dart';
import '../models/response_filter_model.dart';

class ResponseFiltersRepositoryImpl implements ResponseFiltersRepository {
  static const _storageKey = 'request_builder_saved_response_filters';

  List<ResponseFilter>? _cache;

  @override
  Future<List<ResponseFilter>> getSavedFilters() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <ResponseFilter>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ResponseFilter>[];
      }

      final restored = decoded
          .whereType<Map>()
          .map(
            (item) =>
                ResponseFilterModel.fromJson(Map<String, dynamic>.from(item))
                    .toEntity(),
          )
          .toList(growable: false);
      _cache = restored;
      return restored;
    } catch (_) {
      return const <ResponseFilter>[];
    }
  }

  @override
  Future<void> saveSavedFilters(List<ResponseFilter> filters) async {
    _cache = List<ResponseFilter>.unmodifiable(filters);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(
        filters
            .map(ResponseFilterModel.fromEntity)
            .map((model) => model.toJson())
            .toList(growable: false),
      ),
    );
  }
}
