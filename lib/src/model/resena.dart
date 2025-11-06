// lib/src/model/resena.dart

/// Modelo de datos para representar una única Reseña (RF12).
///
/// Corresponde al 'ResenaResponseDTO.java' del backend.
class Resena {
  final int id;
  final int valoracion; // 1-5
  final String? textoResena; // Es opcional
  final DateTime fechaCreacion;
  final int elementoId;
  final String usernameAutor;

  Resena({
    required this.id,
    required this.valoracion,
    this.textoResena,
    required this.fechaCreacion,
    required this.elementoId,
    required this.usernameAutor,
  });

  /// "Constructor de fábrica" (Factory Constructor) para crear una instancia
  /// a partir del JSON (Map) decodificado de la API.
  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'],
      valoracion: json['valoracion'],
      textoResena: json['textoResena'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      elementoId: json['elementoId'],
      usernameAutor: json['usernameAutor'],
    );
  }
}