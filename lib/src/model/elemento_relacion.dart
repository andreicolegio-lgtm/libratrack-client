/// Representación simplificada de un Elemento.
/// Usado para listas de secuelas, precuelas o búsquedas rápidas.
class ElementoRelacion {
  final int id;
  final String titulo;
  final String? urlImagen;

  const ElementoRelacion({
    required this.id,
    required this.titulo,
    this.urlImagen,
  });

  factory ElementoRelacion.fromJson(Map<String, dynamic> json) {
    return ElementoRelacion(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      urlImagen: json['urlImagen'] as String?,
    );
  }
}
