import 'package:flutter/material.dart';
import '../core/l10n/app_localizations.dart';
import 'elemento_relacion.dart';

/// Representa un contenido audiovisual o literario en la aplicación.
/// Coincide con el `ElementoResponseDTO` del backend.
class Elemento {
  final int id;
  final String titulo;
  final String descripcion;
  final String? urlImagen;
  final String? fechaLanzamiento; // Formato YYYY-MM-DD
  final String tipo; // Nombre del tipo (ej. Anime, Libro)
  final String estadoContenido; // OFICIAL o COMUNITARIO
  final String? estadoPublicacion; // EN_EMISION, FINALIZADO...
  final String creadorUsername;
  final List<String> generos;

  // Detalles específicos
  final String? episodiosPorTemporada;
  final int? totalUnidades;
  final int? totalCapitulosLibro;
  final int? totalPaginasLibro;
  final String? duracion;

  // Relaciones
  final List<ElementoRelacion> precuelas;
  final List<ElementoRelacion> secuelas;

  // Nuevas propiedades
  final String? genero; // Género primario
  final bool esOficial; // Indica si el contenido es oficial
  final String? autorNombre; // Nombre del autor
  final String? autorEmail; // Email del autor

  const Elemento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.estadoContenido,
    required this.creadorUsername,
    required this.generos,
    required this.precuelas,
    required this.secuelas,
    required this.esOficial,
    this.urlImagen,
    this.fechaLanzamiento,
    this.estadoPublicacion,
    this.episodiosPorTemporada,
    this.totalUnidades,
    this.totalCapitulosLibro,
    this.totalPaginasLibro,
    this.duracion,
    this.genero,
    this.autorNombre,
    this.autorEmail,
  });

  factory Elemento.fromJson(Map<String, dynamic> json) {
    return Elemento(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      // Si es null, ponemos cadena vacía
      descripcion: json['descripcion'] as String? ?? '',
      urlImagen: json['urlImagen'] as String?,
      fechaLanzamiento: json['fechaLanzamiento'] as String?,
      tipo: json['tipoNombre'] as String? ?? 'Desconocido', // Fallback seguro
      estadoContenido: json['estadoContenido'] as String? ?? 'COMUNITARIO',
      estadoPublicacion: json['estadoPublicacion'] as String?,
      creadorUsername: json['creadorUsername'] as String? ?? 'Anónimo',
      generos: (json['generos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
      duracion: json['duracion'] as String?,
      precuelas: (json['precuelas'] as List<dynamic>?)
              ?.map((e) => ElementoRelacion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      secuelas: (json['secuelas'] as List<dynamic>?)
              ?.map((e) => ElementoRelacion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      genero: json['genero'] as String?,
      esOficial: json['esOficial'] as bool? ?? false,
      autorNombre: json['autorNombre'] as String?,
      autorEmail: json['autorEmail'] as String?,
    );
  }

  /// Devuelve el nombre localizado del estado del contenido.
  /// Útil para mostrar "OFICIAL" o "COMUNITARIO" traducido en la UI.
  String estadoContenidoDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (estadoContenido == 'OFICIAL') {
      return l10n.contentStatusOfficial;
    } else if (estadoContenido == 'COMUNITARIO') {
      return l10n.contentStatusCommunity;
    }
    return estadoContenido;
  }
}
