// lib/src/model/elemento.dart
// (¡MODIFICADO POR GEMINI PARA ACEPTAR RELACIONES!)

// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:libratrack_client/src/model/elemento_relacion.dart';
// ---

/// Modelo de datos para representar un Elemento del catálogo.
///
/// Corresponde al 'ElementoResponseDTO.java' del backend.
/// --- ¡ACTUALIZADO (Sprint 4 - Fase 2)! ---
/// --- ¡ACTUALIZADO (Sprint 10 / Relaciones)! ---
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

  // --- ¡NUEVOS CAMPOS DE RELACIONES! (Añadidos por Gemini) ---
  final List<ElementoRelacion> precuelas;
  final List<ElementoRelacion> secuelas;
  // --- FIN DE CAMPOS AÑADIDOS ---

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

    // --- ¡NUEVOS CAMPOS DE RELACIONES! ---
    required this.precuelas,
    required this.secuelas,
  });

  /// Constructor 'factory' para crear una instancia de [Elemento]
  /// a partir de un mapa JSON devuelto por la API.
  factory Elemento.fromJson(Map<String, dynamic> json) {
    
    // --- ¡NUEVO MAPEO DE RELACIONES! ---
    // Mapeo de Precuelas
    // 1. Obtiene la lista del JSON (o una lista vacía si es nulo)
    var precuelasList = json['precuelas'] as List<dynamic>? ?? [];
    // 2. Mapea cada item de la lista usando el factory de ElementoRelacion
    List<ElementoRelacion> precuelas = precuelasList
        .map((item) => ElementoRelacion.fromJson(item as Map<String, dynamic>))
        .toList();

    // Mapeo de Secuelas
    var secuelasList = json['secuelas'] as List<dynamic>? ?? [];
    List<ElementoRelacion> secuelas = secuelasList
        .map((item) => ElementoRelacion.fromJson(item as Map<String, dynamic>))
        .toList();
    // --- FIN DE MAPEO AÑADIDO ---

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

      // --- ¡NUEVOS CAMPOS DE RELACIONES! ---
      precuelas: precuelas,
      secuelas: secuelas,
    );
  }
}