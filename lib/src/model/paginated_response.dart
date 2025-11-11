// lib/src/model/paginated_response.dart

/// Un modelo de datos genérico para manejar las respuestas paginadas
/// de la API de Spring Boot (que devuelve un objeto `Page<T>`).
class PaginatedResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final bool isLast; // true si es la última página
  final bool isFirst; // true si es la primera página
  final int number; // Número de la página actual (base 0)

  PaginatedResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
    required this.isFirst,
    required this.number,
  });

  /// Factory constructor para crear la respuesta paginada desde JSON.
  /// Requiere una función 'fromJson' para saber cómo convertir
  /// los objetos individuales en la lista 'content'.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // El JSON de 'content' es una List<dynamic>
    final List<dynamic> contentList = json['content'] as List<dynamic>;
    
    // Usamos la función 'fromJson' para mapear la lista
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