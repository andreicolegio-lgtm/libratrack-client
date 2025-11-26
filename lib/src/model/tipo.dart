import 'genero.dart';

/// Representa un tipo de medio (Anime, Manga, Libro, etc.).
/// Define qué géneros son válidos para este tipo.
class Tipo {
  final int id;
  final String nombre;
  final List<Genero> validGenres;

  const Tipo({
    required this.id,
    required this.nombre,
    required this.validGenres,
  });

  factory Tipo.fromJson(Map<String, dynamic> json) {
    return Tipo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      validGenres: (json['generosPermitidos'] as List<dynamic>?)
              ?.map((item) => Genero.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tipo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
