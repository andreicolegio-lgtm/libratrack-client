/// Representa una opinión de un usuario sobre un elemento.
/// Coincide con `ResenaResponseDTO`.
class Resena {
  final int id;
  final int valoracion; // 1-5
  final String? textoResena;
  final DateTime fechaCreacion;

  final int elementoId;
  final int usuarioId; // Added field to identify the user
  final String usernameAutor;
  final String? autorFotoPerfilUrl;

  const Resena({
    required this.id,
    required this.valoracion,
    required this.fechaCreacion,
    required this.elementoId,
    required this.usuarioId, // Added to constructor
    required this.usernameAutor,
    this.textoResena,
    this.autorFotoPerfilUrl,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'] as int? ?? 0, // Handle null values safely
      valoracion: json['valoracion'] as int? ?? 0, // Handle null values safely
      textoResena: json['textoResena'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now(), // Use DateTime.now() as fallback
      elementoId: json['elementoId'] as int? ?? 0, // Handle null values safely
      usuarioId: json['usuarioId'] as int? ?? 0, // Handle null values safely
      usernameAutor: json['usernameAutor'] as String? ?? 'Anónimo',
      autorFotoPerfilUrl: json['autorFotoPerfilUrl'] as String?,
    );
  }
}
