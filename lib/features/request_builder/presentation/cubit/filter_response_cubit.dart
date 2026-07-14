import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/helpers/filter_response_mode.dart';
import '../../domain/helpers/response_filter_engine.dart';
import '../../domain/helpers/response_filter_pretty_printer.dart';
import 'filter_response_state.dart';

class FilterResponseCubit extends Cubit<FilterResponseState> {
  FilterResponseCubit({
    required String body,
    String? contentType,
    ResponseFilterEngine engine = const ResponseFilterEngine(),
    this.debounce = const Duration(milliseconds: 280),
  }) : _body = body,
       _contentType = contentType,
       _engine = engine,
       super(
         _initialState(
           body: body,
           contentType: contentType,
           engine: engine,
         ),
       );

  final String _body;
  final String? _contentType;
  final ResponseFilterEngine _engine;
  final Duration debounce;

  Timer? _debounceTimer;

  static FilterResponseState _initialState({
    required String body,
    required String? contentType,
    required ResponseFilterEngine engine,
  }) {
    final mode = defaultFilterMode(body: body, contentType: contentType);
    final result = engine.filter(
      body: body,
      mode: mode,
      query: '',
      contentType: contentType,
    );
    return FilterResponseState(
      mode: mode,
      query: '',
      displayText: result.hasError
          ? result.displayText
          : prettyPrintJsonString(body),
      errorMessage: result.hasError ? result.errorMessage : null,
    );
  }

  /// Updates the query, debouncing before the filter runs.
  void queryChanged(String query) {
    emit(state.copyWith(query: query));
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _applyFilter);
  }

  /// Applies a saved filter immediately, setting both mode and query.
  void applySavedFilter({
    required FilterResponseMode mode,
    required String query,
  }) {
    _debounceTimer?.cancel();
    emit(state.copyWith(mode: mode, query: query, clearError: true));
    _applyFilter();
  }

  /// Switches mode, clears any prior error, and re-runs a non-empty query.
  void modeChanged(FilterResponseMode mode) {
    if (mode == state.mode) {
      return;
    }
    _debounceTimer?.cancel();
    emit(state.copyWith(mode: mode, clearError: true));
    _applyFilter();
  }

  void _applyFilter() {
    final result = _engine.filter(
      body: _body,
      mode: state.mode,
      query: state.query,
      contentType: _contentType,
    );
    emit(
      state.copyWith(
        displayText: result.displayText,
        errorMessage: result.hasError ? result.errorMessage : null,
        clearError: !result.hasError,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
