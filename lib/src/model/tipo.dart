// lib/src/model/tipo.dart

/// Modelo de datos para representar una entidad Tipo de contenido.
/// Corresponde a la entidad 'Tipo.java' del backend.
class Tipo {
  final int id;
  final String nombre;

  Tipo({
    required this.id,
    required this.nombre,
  });

  /// Factory constructor para crear una instancia a partir del JSON.
  factory Tipo.fromJson(Map<String, dynamic> json) {
    return Tipo(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}