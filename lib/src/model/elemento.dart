// lib/src/model/elemento.dart

/// Modelo de datos para representar un Elemento del catálogo.
///
/// Corresponde al 'ElementoResponseDTO.java' del backend.
/// Usamos esta clase para tener seguridad de tipos (type-safety)
/// y evitar errores al manejar el JSON de la API.
class Elemento {
  final int id;
  final String titulo;
  final String descripcion;
  final String? imagenPortadaUrl; // Puede ser nulo
  final String estadoContenido; // "OFICIAL" o "COMUNITARIO"
  final String tipo; // "Serie", "Libro", etc.
  final List<String> generos; // "Fantasía", "Ciencia Ficción", etc.
  final String? creadorUsername; // "Administrador" o el nombre del proponente
  
  // Nota: 'fechaLanzamiento' se omite por ahora 
  // para simplificar, pero se puede añadir fácilmente.

  Elemento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.imagenPortadaUrl,
    required this.estadoContenido,
    required this.tipo,
    required this.generos,
    this.creadorUsername,
  });

  /// Constructor 'factory' para crear una instancia de [Elemento]
  /// a partir de un mapa JSON devuelto por la API.
  factory Elemento.fromJson(Map<String, dynamic> json) {
    return Elemento(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imagenPortadaUrl: json['imagenPortadaUrl'],
      estadoContenido: json['estadoContenido'],
      tipo: json['tipo'],
      
      // Convierte la lista/set de géneros del JSON a una List<String> de Dart
      generos: List<String>.from(json['generos']), 
      
      creadorUsername: json['creadorUsername'],
    );
  }
}