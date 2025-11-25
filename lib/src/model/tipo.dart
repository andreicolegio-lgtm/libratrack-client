import 'genero.dart';

class Tipo {
  final int id;
  final String nombre;
  final List<Genero> validGenres;

  Tipo({
    required this.id,
    required this.nombre,
    required this.validGenres,
  });

  factory Tipo.fromJson(Map<String, dynamic> json) {
    return Tipo(
      id: json['id'],
      nombre: json['nombre'],
      validGenres: (json['generosPermitidos'] as List<dynamic>)
          .map((item) => Genero.fromJson(item))
          .toList(),
    );
  }
}
