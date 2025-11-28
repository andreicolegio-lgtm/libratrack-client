/// Representa un ítem guardado en la biblioteca personal del usuario.
/// Combina datos del progreso personal con datos resumen del elemento.
class CatalogoEntrada {
  final int id;
  final String estadoPersonal; // PENDIENTE, EN_PROGRESO, etc.
  final DateTime agregadoEn;
  final bool esFavorito;
  final String? notas;

  // Progreso
  final int? temporadaActual;
  final int? unidadActual;
  final int? capituloActual;
  final int? paginaActual;

  // Datos del Elemento (Flattened)
  final int elementoId;
  final String elementoTitulo;
  final String elementoTipoNombre;
  final String? elementoGeneros;
  final String? elementoUrlImagen;
  final String? elementoEstadoPublicacion;
  final String? elementoEpisodiosPorTemporada;
  final String? elementoDuracion;

  // Totales del elemento para calcular barras de progreso
  final int? elementoTotalUnidades;
  final int? elementoTotalCapitulosLibro;
  final int? elementoTotalPaginasLibro;

  final int usuarioId;

  const CatalogoEntrada({
    required this.id,
    required this.estadoPersonal,
    required this.agregadoEn,
    required this.elementoId,
    required this.elementoTitulo,
    required this.elementoTipoNombre,
    required this.usuarioId,
    this.esFavorito = false,
    this.notas,
    this.temporadaActual,
    this.unidadActual,
    this.capituloActual,
    this.paginaActual,
    this.elementoGeneros,
    this.elementoUrlImagen,
    this.elementoEstadoPublicacion,
    this.elementoEpisodiosPorTemporada,
    this.elementoDuracion,
    this.elementoTotalUnidades,
    this.elementoTotalCapitulosLibro,
    this.elementoTotalPaginasLibro,
  });

  /// Crea una copia de esta instancia con los campos modificados.
  CatalogoEntrada copyWith({
    int? id,
    String? estadoPersonal,
    DateTime? agregadoEn,
    bool? esFavorito,
    String? notas,
    int? temporadaActual,
    int? unidadActual,
    int? capituloActual,
    int? paginaActual,
  }) {
    return CatalogoEntrada(
      id: id ?? this.id,
      estadoPersonal: estadoPersonal ?? this.estadoPersonal,
      agregadoEn: agregadoEn ?? this.agregadoEn,
      esFavorito: esFavorito ?? this.esFavorito,
      notas: notas ?? this.notas,
      temporadaActual: temporadaActual ?? this.temporadaActual,
      unidadActual: unidadActual ?? this.unidadActual,
      capituloActual: capituloActual ?? this.capituloActual,
      paginaActual: paginaActual ?? this.paginaActual,

      // Campos inmutables del elemento (se copian tal cual)
      elementoId: elementoId,
      elementoTitulo: elementoTitulo,
      elementoTipoNombre: elementoTipoNombre,
      elementoGeneros: elementoGeneros,
      usuarioId: usuarioId,
      elementoUrlImagen: elementoUrlImagen,
      elementoEstadoPublicacion: elementoEstadoPublicacion,
      elementoEpisodiosPorTemporada: elementoEpisodiosPorTemporada,
      elementoDuracion: elementoDuracion,
      elementoTotalUnidades: elementoTotalUnidades,
      elementoTotalCapitulosLibro: elementoTotalCapitulosLibro,
      elementoTotalPaginasLibro: elementoTotalPaginasLibro,
    );
  }

  factory CatalogoEntrada.fromJson(Map<String, dynamic> json) {
    return CatalogoEntrada(
      id: json['id'] as int,
      estadoPersonal: json['estadoPersonal'] as String,
      agregadoEn: DateTime.parse(json['agregadoEn'] as String),
      esFavorito: json['esFavorito'] as bool? ?? false,
      notas: json['notas'] as String?,
      temporadaActual: json['temporadaActual'] as int?,
      unidadActual: json['unidadActual'] as int?,
      capituloActual: json['capituloActual'] as int?,
      paginaActual: json['paginaActual'] as int?,
      elementoId: json['elementoId'] as int,
      elementoTitulo: json['elementoTitulo'] as String,
      elementoTipoNombre: json['elementoTipoNombre'] as String,
      elementoGeneros: json['elementoGeneros'] as String?,
      elementoUrlImagen: json['elementoUrlImagen'] as String?,
      elementoEstadoPublicacion: json['elementoEstadoPublicacion'] as String?,
      elementoEpisodiosPorTemporada:
          json['elementoEpisodiosPorTemporada'] as String?,
      elementoDuracion: json['elementoDuracion'] as String?,
      elementoTotalUnidades: json['elementoTotalUnidades'] as int?,
      elementoTotalCapitulosLibro: json['elementoTotalCapitulosLibro'] as int?,
      elementoTotalPaginasLibro: json['elementoTotalPaginasLibro'] as int?,
      usuarioId: json['usuarioId'] as int,
    );
  }
}
