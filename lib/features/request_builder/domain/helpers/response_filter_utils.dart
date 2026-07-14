import '../entities/response_filter.dart';

String buildResponseFilterName({
  required String proposedName,
  required String query,
}) {
  final normalizedName = proposedName.trim();
  if (normalizedName.isNotEmpty) {
    return normalizedName;
  }

  final compactQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (compactQuery.isNotEmpty && compactQuery.length <= 32) {
    return compactQuery;
  }

  return 'Response Filter';
}

ResponseFilterType defaultResponseFilterTypeForContentType(String contentType) {
  final normalized = contentType.trim().toLowerCase();
  if (normalized.contains('xml') || normalized.contains('html')) {
    return ResponseFilterType.xPath;
  }

  return ResponseFilterType.jq;
}
