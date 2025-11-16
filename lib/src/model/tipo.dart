class Tipo {
  final int id;
  final String nombre;

  Tipo({
    required this.id,
    required this.nombre,
  });

  factory Tipo.fromJson(Map<String, dynamic> json) {
    return Tipo(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}
