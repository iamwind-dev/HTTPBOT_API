import 'package:equatable/equatable.dart';

class RequestListItem extends Equatable {
  const RequestListItem({
    required this.method,
    required this.title,
    required this.url,
  });

  final String method;
  final String title;
  final String url;

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return true;
    }

    return title.toLowerCase().contains(normalizedQuery) ||
        url.toLowerCase().contains(normalizedQuery) ||
        method.toLowerCase().contains(normalizedQuery);
  }

  @override
  List<Object> get props => [method, title, url];
}
