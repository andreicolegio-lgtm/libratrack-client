class PaginatedResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final bool isLast;
  final bool isFirst;
  final int number;

  PaginatedResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.isFirst,
    required this.number,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<dynamic> contentList = json['content'] as List<dynamic>;

    final List<T> items = contentList
        .map((itemJson) => fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return PaginatedResponse(
      content: items,
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
      isLast: json['last'] as bool,
      isFirst: json['first'] as bool,
      number: json['number'] as int,
    );
  }
}
