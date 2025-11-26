/// Clase genérica para manejar las respuestas paginadas de Spring Boot (Page`<T>`).
/// Facilita el consumo de listas infinitas o tablas paginadas.
class PaginatedResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final bool isLast;
  final bool isFirst;
  final int number; // Número de página actual (0-indexado)

  const PaginatedResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.isFirst,
    required this.number,
  });

  /// Factory para crear una instancia desde el JSON de Spring Page.
  /// [fromJsonModel] es la función factoría del modelo T (ej. Elemento.fromJson).
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonModel,
  ) {
    final List<dynamic> contentList = json['content'] as List<dynamic>? ?? [];

    final List<T> items = contentList
        .map((itemJson) => fromJsonModel(itemJson as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      content: items,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      isLast: json['last'] as bool? ?? true,
      isFirst: json['first'] as bool? ?? true,
      number: json['number'] as int? ?? 0,
    );
  }
}
