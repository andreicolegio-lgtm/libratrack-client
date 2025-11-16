class CatalogoEntrada {
  final int id;
  final String estadoPersonal;
  final DateTime agregadoEn;

  final int? temporadaActual;
  final int? unidadActual;
  final int? capituloActual;
  final int? paginaActual;

  final int elementoId;
  final String elementoTitulo;
  final String elementoTipoNombre;
  final String? elementoUrlImagen;

  final String? elementoEstadoPublicacion;
  final String? elementoEpisodiosPorTemporada;
  final int? elementoTotalUnidades;
  final int? elementoTotalCapitulosLibro;
  final int? elementoTotalPaginasLibro;

  final int usuarioId;

  CatalogoEntrada({
    required this.id,
    required this.estadoPersonal,
    required this.agregadoEn,
    required this.elementoId,
    required this.elementoTitulo,
    required this.elementoTipoNombre,
    required this.usuarioId,
    this.temporadaActual,
    this.unidadActual,
    this.capituloActual,
    this.paginaActual,
    this.elementoEstadoPublicacion,
    this.elementoEpisodiosPorTemporada,
    this.elementoTotalUnidades,
    this.elementoTotalCapitulosLibro,
    this.elementoTotalPaginasLibro,
    this.elementoUrlImagen,
  });

  factory CatalogoEntrada.fromJson(Map<String, dynamic> json) {
    return CatalogoEntrada(
      id: json['id'] as int,
      estadoPersonal: json['estadoPersonal'] as String,
      agregadoEn: DateTime.parse(json['agregadoEn'] as String),
      temporadaActual: json['temporadaActual'] as int?,
      unidadActual: json['unidadActual'] as int?,
      capituloActual: json['capituloActual'] as int?,
      paginaActual: json['paginaActual'] as int?,
      elementoId: json['elementoId'] as int,
      elementoTitulo: json['elementoTitulo'] as String,
      elementoTipoNombre: json['elementoTipoNombre'] as String,
      elementoUrlImagen: json['elementoUrlImagen'] as String?,
      elementoEstadoPublicacion: json['elementoEstadoPublicacion'] as String?,
      elementoEpisodiosPorTemporada:
          json['elementoEpisodiosPorTemporada'] as String?,
      elementoTotalUnidades: json['elementoTotalUnidades'] as int?,
      elementoTotalCapitulosLibro: json['elementoTotalCapitulosLibro'] as int?,
      elementoTotalPaginasLibro: json['elementoTotalPaginasLibro'] as int?,
      usuarioId: json['usuarioId'] as int,
    );
  }
}
