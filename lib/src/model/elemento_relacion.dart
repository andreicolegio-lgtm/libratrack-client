class ElementoRelacion {
  final int id;
  final String titulo;
  final String? urlImagen;

  ElementoRelacion({
    required this.id,
    required this.titulo,
    this.urlImagen,
  });

  factory ElementoRelacion.fromJson(Map<String, dynamic> json) {
    return ElementoRelacion(
      id: json['id'],
      titulo: json['titulo'],
      urlImagen: json['urlImagen'],
    );
  }
}
