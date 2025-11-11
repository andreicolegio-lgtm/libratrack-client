// lib/src/model/elemento.dart

/// Modelo de datos para representar un Elemento del catálogo.
///
/// Corresponde al 'ElementoResponseDTO.java' del backend.
/// --- ¡ACTUALIZADO (Sprint 2 / V2)! ---
class Elemento {
  final int id;
  final String titulo;
  final String descripcion;
  final String? imagenPortadaUrl; 
  final String estadoContenido; // "OFICIAL" o "COMUNITARIO"
  final String tipo; // "Serie", "Libro", etc.
  final List<String> generos; 
  final String? creadorUsername; 
  
  // --- ¡CAMPOS DE PROGRESO TOTAL REFACTORIZADOS! ---
  final String? episodiosPorTemporada; // Para Series (ej. "10,8,12")
  final int? totalUnidades;        // Para Anime / Manga
  final int? totalCapitulosLibro;  // Para Libros
  final int? totalPaginasLibro;    // Para Libros

  Elemento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.imagenPortadaUrl,
    required this.estadoContenido,
    required this.tipo,
    required this.generos,
    this.creadorUsername,
    // --- ¡NUEVOS CAMPOS! ---
    this.episodiosPorTemporada,
    this.totalUnidades,
    this.totalCapitulosLibro,
    this.totalPaginasLibro,
  });

  /// Constructor 'factory' para crear una instancia de [Elemento]
  /// a partir de un mapa JSON devuelto por la API.
  factory Elemento.fromJson(Map<String, dynamic> json) {
    return Elemento(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imagenPortadaUrl: json['urlImagen'], // <-- Nombre corregido
      estadoContenido: json['estadoContenido'],
      tipo: json['tipoNombre'], // <-- Nombre corregido
      
      generos: List<String>.from(json['generos']), 
      
      creadorUsername: json['creadorUsername'],
      
      // --- ¡NUEVO MAPEO DE PROGRESO! ---
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
    );
  }
}