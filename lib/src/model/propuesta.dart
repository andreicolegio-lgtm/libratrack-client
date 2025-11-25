class Propuesta {
  final int id;
  final String tituloSugerido;
  final String? descripcionSugerida;
  final String tipoSugerido;
  final String generosSugeridos;
  final String estadoPropuesta;
  final String? comentariosRevision;
  final DateTime fechaPropuesta;
  final String proponenteUsername;
  final String? revisorUsername;

  final String? episodiosPorTemporada;
  final int? totalUnidades;
  final int? totalCapitulosLibro;
  final int? totalPaginasLibro;
  final String? duracion;

  Propuesta({
    required this.id,
    required this.tituloSugerido,
    required this.tipoSugerido,
    required this.generosSugeridos,
    required this.estadoPropuesta,
    required this.fechaPropuesta,
    required this.proponenteUsername,
    this.descripcionSugerida,
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
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
      duracion: json['duracion'] as String?,
    );
  }
}
