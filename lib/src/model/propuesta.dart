// lib/src/model/propuesta.dart

/// Modelo de datos para representar una Propuesta en la cola de moderación (RF14).
///
/// Corresponde 1:1 con 'PropuestaResponseDTO.java'.
/// --- ¡ACTUALIZADO (Sprint 2 / V2)! ---
class Propuesta {
  final int id;
  final String tituloSugerido;
  final String? descripcionSugerida; 
  final String tipoSugerido;
  final String generosSugeridos;
  final String estadoPropuesta; // "PENDIENTE", "APROBADO", "RECHAZADO"
  final String? comentariosRevision; 
  final DateTime fechaPropuesta; 
  final String proponenteUsername;
  final String? revisorUsername; 

  // --- ¡CAMPOS DE PROGRESO REFACTORIZADOS! ---
  final String? episodiosPorTemporada; // Para Series (ej. "10,8,12")
  final int? totalUnidades;        // Para Anime / Manga
  final int? totalCapitulosLibro;  // Para Libros
  final int? totalPaginasLibro;    // Para Libros

  Propuesta({
    required this.id,
    required this.tituloSugerido,
    this.descripcionSugerida,
    required this.tipoSugerido,
    required this.generosSugeridos,
    required this.estadoPropuesta,
    this.comentariosRevision,
    required this.fechaPropuesta,
    required this.proponenteUsername,
    this.revisorUsername,
    // --- ¡NUEVOS CAMPOS! ---
    this.episodiosPorTemporada,
    this.totalUnidades,
    this.totalCapitulosLibro,
    this.totalPaginasLibro,
  });

  /// "Constructor de fábrica" para crear una instancia a partir del JSON.
  factory Propuesta.fromJson(Map<String, dynamic> json) {
    return Propuesta(
      id: json['id'],
      tituloSugerido: json['tituloSugerido'],
      descripcionSugerida: json['descripcionSugerida'],
      tipoSugerido: json['tipoSugerido'],
      generosSugeridos: json['generosSugeridos'],
      estadoPropuesta: json['estadoPropuesta'],
      comentariosRevision: json['comentariosRevision'], 
      fechaPropuesta: DateTime.parse(json['fechaPropuesta']), 
      proponenteUsername: json['proponenteUsername'],
      revisorUsername: json['revisorUsername'],
      
      // --- ¡NUEVO MAPEO! ---
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
    );
  }
}