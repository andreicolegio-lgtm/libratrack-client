/// Representa una solicitud de contenido enviada por un usuario.
/// Coincide con `PropuestaResponseDTO`.
class Propuesta {
  final int id;
  final String tituloSugerido;
  final String? descripcionSugerida;
  final String tipoSugerido;
  final String generosSugeridos;
  final String? urlImagen;

  // Estado y Metadatos
  final String estadoPropuesta; // PENDIENTE, APROBADO, RECHAZADO
  final String? comentariosRevision;
  final DateTime fechaPropuesta;
  final String proponenteUsername;
  final String? revisorUsername;

  // Detalles Técnicos Sugeridos
  final String? episodiosPorTemporada;
  final int? totalUnidades;
  final int? totalCapitulosLibro;
  final int? totalPaginasLibro;
  final String? duracion;

  const Propuesta({
    required this.id,
    required this.tituloSugerido,
    required this.tipoSugerido,
    required this.generosSugeridos,
    required this.estadoPropuesta,
    required this.fechaPropuesta,
    required this.proponenteUsername,
    this.descripcionSugerida,
    this.urlImagen,
    this.comentariosRevision,
    this.revisorUsername,
    this.episodiosPorTemporada,
    this.totalUnidades,
    this.totalCapitulosLibro,
    this.totalPaginasLibro,
    this.duracion,
  });

  factory Propuesta.fromJson(Map<String, dynamic> json) {
    return Propuesta(
      id: json['id'] as int,
      tituloSugerido: json['tituloSugerido'] as String,
      descripcionSugerida: json['descripcionSugerida'] as String?,
      tipoSugerido: json['tipoSugerido'] as String,
      generosSugeridos: json['generosSugeridos'] as String,
      urlImagen: json['urlImagen'] as String?,
      estadoPropuesta: json['estadoPropuesta'] as String,
      comentariosRevision: json['comentariosRevision'] as String?,
      fechaPropuesta: DateTime.parse(json['fechaPropuesta'] as String),
      proponenteUsername: json['proponenteUsername'] as String,
      revisorUsername: json['revisorUsername'] as String?,

      // Detalles opcionales
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
      duracion: json['duracion'] as String?,
    );
  }
}
