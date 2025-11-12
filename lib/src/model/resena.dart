// lib/src/model/resena.dart

/// Modelo de datos para representar una única Reseña (RF12).
/// Corresponde al 'ResenaResponseDTO.java' del backend.
/// --- ¡ACTUALIZADO (Sprint 3)! ---
class Resena {
  final int id;
  final int valoracion; // 1-5
  final String? textoResena; // Es opcional
  final DateTime fechaCreacion;
  final int elementoId;
  final String usernameAutor;
  final String? autorFotoPerfilUrl; // <-- ¡NUEVO CAMPO!

  Resena({
    required this.id,
    required this.valoracion,
    this.textoResena,
    required this.fechaCreacion,
    required this.elementoId,
    required this.usernameAutor,
    this.autorFotoPerfilUrl, // <-- ¡NUEVO CAMPO!
  });

  /// "Constructor de fábrica" (Factory Constructor)
  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'],
      valoracion: json['valoracion'],
      textoResena: json['textoResena'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      elementoId: json['elementoId'],
      usernameAutor: json['usernameAutor'],
      autorFotoPerfilUrl: json['autorFotoPerfilUrl'] as String?, // <-- ¡NUEVO MAPEO!
    );
  }
}