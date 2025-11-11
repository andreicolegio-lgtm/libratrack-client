// lib/src/model/catalogo_entrada.dart

/// Modelo de datos para representar una única entrada
/// en el catálogo personal del usuario.
///
/// Corresponde al 'CatalogoPersonalResponseDTO.java' del backend.
/// --- ¡ACTUALIZADO (Sprint 2 / V2)! ---
class CatalogoEntrada {
  final int id;
  final String estadoPersonal; 
  final DateTime agregadoEn;
  
  // --- Progreso Actual (Usuario) ---
  final int? temporadaActual; 
  final int? unidadActual;   // (Episodio / Cap Manga/Anime)
  final int? capituloActual; // (Cap Libro)
  final int? paginaActual;   // (Pág Libro)

  // --- Datos del Elemento Relacionado ---
  final int elementoId;
  final String elementoTitulo;
  final String elementoTipoNombre; 
  final String? elementoUrlImagen;

  // --- ¡PROGRESO TOTAL DEL ELEMENTO REFACTORIZADO! ---
  final String? elementoEstadoPublicacion; 
  final String? elementoEpisodiosPorTemporada; // Para Series
  final int? elementoTotalUnidades;        // Para Anime / Manga
  final int? elementoTotalCapitulosLibro;  // Para Libros
  final int? elementoTotalPaginasLibro;    // Para Libros

  final int usuarioId;

  CatalogoEntrada({
    required this.id,
    required this.estadoPersonal,
    required this.agregadoEn,
    this.temporadaActual,
    this.unidadActual,
    this.capituloActual, 
    this.paginaActual,   
    required this.elementoId,
    required this.elementoTitulo,
    required this.elementoTipoNombre,
    this.elementoEstadoPublicacion,
    this.elementoEpisodiosPorTemporada, // <-- NUEVO
    this.elementoTotalUnidades,         // <-- NUEVO
    this.elementoTotalCapitulosLibro,   // <-- NUEVO
    this.elementoTotalPaginasLibro,     // <-- NUEVO
    this.elementoUrlImagen,
    required this.usuarioId,
  });

  /// "Constructor de fábrica" para crear una instancia
  /// a partir del JSON (Map) decodificado de la API.
  factory CatalogoEntrada.fromJson(Map<String, dynamic> json) {
    return CatalogoEntrada(
      id: json['id'] as int,
      estadoPersonal: json['estadoPersonal'] as String,
      agregadoEn: DateTime.parse(json['agregadoEn'] as String),
      
      // Mapeo de Progreso Actual (Usuario)
      temporadaActual: json['temporadaActual'] as int?,
      unidadActual: json['unidadActual'] as int?,
      capituloActual: json['capituloActual'] as int?, 
      paginaActual: json['paginaActual'] as int?,     
      
      // Mapeo de Elemento
      elementoId: json['elementoId'] as int,
      elementoTitulo: json['elementoTitulo'] as String,
      elementoTipoNombre: json['elementoTipoNombre'] as String,
      elementoUrlImagen: json['elementoUrlImagen'] as String?, 
      
      // Mapeo de Progreso Total (Elemento)
      elementoEstadoPublicacion: json['elementoEstadoPublicacion'] as String?,
      elementoEpisodiosPorTemporada: json['elementoEpisodiosPorTemporada'] as String?,
      elementoTotalUnidades: json['elementoTotalUnidades'] as int?,
      elementoTotalCapitulosLibro: json['elementoTotalCapitulosLibro'] as int?,
      elementoTotalPaginasLibro: json['elementoTotalPaginasLibro'] as int?,     
      
      usuarioId: json['usuarioId'] as int,
    );
  }
}