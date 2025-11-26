/// Representa una opinión de un usuario sobre un elemento.
/// Coincide con `ResenaResponseDTO`.
class Resena {
  final int id;
  final int valoracion; // 1-5
  final String? textoResena;
  final DateTime fechaCreacion;

  final int elementoId;
  final String usernameAutor;
  final String? autorFotoPerfilUrl;

  const Resena({
    required this.id,
    required this.valoracion,
    required this.fechaCreacion,
    required this.elementoId,
    required this.usernameAutor,
    this.textoResena,
    this.autorFotoPerfilUrl,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'] as int,
      valoracion: json['valoracion'] as int,
      textoResena: json['textoResena'] as String?,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      elementoId: json['elementoId'] as int,
      usernameAutor: json['usernameAutor'] as String? ?? 'Anónimo',
      autorFotoPerfilUrl: json['autorFotoPerfilUrl'] as String?,
    );
  }
}
