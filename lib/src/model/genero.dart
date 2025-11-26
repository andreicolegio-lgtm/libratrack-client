/// Representa una categoría temática (Acción, Aventura, etc.).
class Genero {
  final int id;
  final String nombre;

  const Genero({
    required this.id,
    required this.nombre,
  });

  factory Genero.fromJson(Map<String, dynamic> json) {
    return Genero(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Genero && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Genero(id: $id, nombre: $nombre)';
}
