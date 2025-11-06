// lib/src/model/genero.dart

/// Modelo de datos para representar una entidad Genero de contenido.
/// Corresponde a la entidad 'Genero.java' del backend.
class Genero {
  final int id;
  final String nombre;

  Genero({
    required this.id,
    required this.nombre,
  });

  /// Factory constructor para crear una instancia a partir del JSON.
  factory Genero.fromJson(Map<String, dynamic> json) {
    return Genero(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}