import 'package:flutter/material.dart';
import '../core/l10n/app_localizations.dart';

import 'elemento_relacion.dart';

class Elemento {
  final int id;
  final String titulo;
  final String descripcion;
  final String? urlImagen;
  final String tipo;
  final String estadoContenido;
  final String creadorUsername;
  final List<String> generos;
  final String? episodiosPorTemporada;
  final int? totalUnidades;
  final int? totalCapitulosLibro;
  final int? totalPaginasLibro;
  final List<ElementoRelacion> precuelas;
  final List<ElementoRelacion> secuelas;

  Elemento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.estadoContenido,
    required this.creadorUsername,
    required this.generos,
    required this.precuelas,
    required this.secuelas,
    this.urlImagen,
    this.episodiosPorTemporada,
    this.totalUnidades,
    this.totalCapitulosLibro,
    this.totalPaginasLibro,
  });

  factory Elemento.fromJson(Map<String, dynamic> json) {
    var generosList =
        (json['generos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
            <String>[];

    var precuelasList = (json['precuelas'] as List<dynamic>?)
            ?.map((e) => ElementoRelacion.fromJson(e))
            .toList() ??
        <ElementoRelacion>[];

    var secuelasList = (json['secuelas'] as List<dynamic>?)
            ?.map((e) => ElementoRelacion.fromJson(e))
            .toList() ??
        <ElementoRelacion>[];

    return Elemento(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      urlImagen: json['urlImagen'],
      tipo: json['tipoNombre'],
      estadoContenido: json['estadoContenido'],
      creadorUsername: json['creadorUsername'],
      generos: generosList,
      episodiosPorTemporada: json['episodiosPorTemporada'],
      totalUnidades: json['totalUnidades'],
      totalCapitulosLibro: json['totalCapitulosLibro'],
      totalPaginasLibro: json['totalPaginasLibro'],
      precuelas: precuelasList,
      secuelas: secuelasList,
    );
  }

  String estadoContenidoDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return estadoContenido;
    }

    if (estadoContenido == 'OFICIAL') {
      return l10n.contentStatusOfficial;
    } else if (estadoContenido == 'COMUNITARIO') {
      return l10n.contentStatusCommunity;
    }
    return estadoContenido;
  }
}
