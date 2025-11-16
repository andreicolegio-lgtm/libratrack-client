import 'elemento_relacion.dart';

class Elemento {
  final int id;
  final String titulo;
  final String descripcion;
  final String? urlImagen;
  final String estadoContenido;
  final String tipo;
  final List<String> generos;
  final String? creadorUsername;

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
    required this.estadoContenido,
    required this.tipo,
    required this.generos,
    required this.precuelas,
    required this.secuelas,
    this.urlImagen,
    this.creadorUsername,
    this.episodiosPorTemporada,
    this.totalUnidades,
    this.totalCapitulosLibro,
    this.totalPaginasLibro,
  });

  factory Elemento.fromJson(Map<String, dynamic> json) {
    List precuelasList = json['precuelas'] as List<dynamic>? ?? <dynamic>[];
    List<ElementoRelacion> precuelas = precuelasList
        .map((item) => ElementoRelacion.fromJson(item as Map<String, dynamic>))
        .toList();

    List secuelasList = json['secuelas'] as List<dynamic>? ?? <dynamic>[];
    List<ElementoRelacion> secuelas = secuelasList
        .map((item) => ElementoRelacion.fromJson(item as Map<String, dynamic>))
        .toList();

    return Elemento(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      urlImagen: json['urlImagen'] as String?,
      estadoContenido: json['estadoContenido'],
      tipo: json['tipoNombre'],
      generos: List<String>.from(json['generos']),
      creadorUsername: json['creadorUsername'],
      episodiosPorTemporada: json['episodiosPorTemporada'] as String?,
      totalUnidades: json['totalUnidades'] as int?,
      totalCapitulosLibro: json['totalCapitulosLibro'] as int?,
      totalPaginasLibro: json['totalPaginasLibro'] as int?,
      precuelas: precuelas,
      secuelas: secuelas,
    );
  }
}
