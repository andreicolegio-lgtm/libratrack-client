class Resena {
  final int id;
  final int valoracion;
  final String? textoResena;
  final DateTime fechaCreacion;
  final int elementoId;
  final String usernameAutor;
  final String? autorFotoPerfilUrl;

  Resena({
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
      id: json['id'],
      valoracion: json['valoracion'],
      textoResena: json['textoResena'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      elementoId: json['elementoId'],
      usernameAutor: json['usernameAutor'],
      autorFotoPerfilUrl: json['autorFotoPerfilUrl'] as String?,
    );
  }
}
