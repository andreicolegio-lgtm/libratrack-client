// lib/src/model/elemento.dart

/// Modelo de datos para representar un Elemento del catálogo.
///
/// Corresponde al 'ElementoResponseDTO.java' del backend.
/// --- ¡ACTUALIZADO (Sprint 4 - Fase 2)! ---
class Elemento {
  final int id;
  final String titulo;
  final String descripcion;
  final String? urlImagen; // <-- ¡NOMBRE CORREGIDO! (era imagenPortadaUrl)
  final String estadoContenido; // "OFICIAL" o "COMUNITARIO"
  final String tipo; // "Serie", "Libro", etc.
  final List<String> generos; 
  final String? creadorUsername; 
  
  // --- Campos de Progreso Total (Refactorizados) ---
  final String? episodiosPorTemporada; 
  final int? totalUnidades;        
  final int? totalCapitulosLibro;  
  final int? totalPaginasLibro;    

  Elemento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.urlImagen, // <-- ¡NOMBRE CORREGIDO!
    required this.estadoContenido,
    required this.tipo,
    required this.generos,
    this.creadorUsername,
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
      urlImagen: json['urlImagen'] as String?, // <-- ¡NOMBRE CORREGIDO!
      estadoContenido: json['estadoContenido'],
      tipo: json['tipoNombre'], // (Este ya estaba bien)
      
      generos: List<String>.from(json['generos']), 
      
      creadorUsername: json['creadorUsername'],
      
      // Mapeo de Progreso
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
    );
  }
}