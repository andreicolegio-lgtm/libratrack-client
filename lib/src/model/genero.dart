class Genero {
  final int id;
  final String nombre;

  Genero({
    required this.id,
    required this.nombre,
  });

  factory Genero.fromJson(Map<String, dynamic> json) {
    return Genero(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}
