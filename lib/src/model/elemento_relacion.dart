// Archivo: lib/src/model/elemento_relacion.dart
// (¡NUEVO ARCHIVO CREADO POR GEMINI!)

/// DTO "superficial" (shallow) que representa una relación (precuela/secuela).
///
/// Contiene solo los datos mínimos para mostrar un enlace navegable
/// en la pantalla de detalle.
class ElementoRelacion {
  final int id;
  final String titulo;
  final String? urlImagen; // La imagen puede ser nula

  ElementoRelacion({
    required this.id,
    required this.titulo,
    this.urlImagen,
  });

  /// Constructor factory para crear una instancia desde un mapa JSON.
  /// Es llamado por el factory de Elemento.
  factory ElementoRelacion.fromJson(Map<String, dynamic> json) {
    return ElementoRelacion(
      // El ID es int en Flutter (Long en Java)
      id: json['id'], 
      titulo: json['titulo'],
      urlImagen: json['urlImagen'],
    );
  }
}