// lib/src/model/catalogo_entrada.dart

/// Modelo de datos para representar una única entrada
/// en el catálogo personal del usuario.
///
/// Corresponde al 'CatalogoPersonalResponseDTO.java' del backend.
class CatalogoEntrada {
  final int id;
  final String estadoPersonal; 
  final String? progresoEspecifico; 
  final DateTime agregadoEn;
  final int elementoId;
  final String elementoTitulo;
  final String? elementoImagenPortadaUrl; // ¡CORREGIDO! Ahora es NULABLE (String?)
  final int usuarioId;

  CatalogoEntrada({
    required this.id,
    required this.estadoPersonal,
    this.progresoEspecifico,
    required this.agregadoEn,
    required this.elementoId,
    required this.elementoTitulo,
    this.elementoImagenPortadaUrl, // ¡CORREGIDO! Ya no es required
    required this.usuarioId,
  });

  /// "Constructor de fábrica" (Factory Constructor) para crear una instancia
  /// a partir del JSON (Map) decodificado de la API.
  factory CatalogoEntrada.fromJson(Map<String, dynamic> json) {
    return CatalogoEntrada(
      id: json['id'] as int,
      estadoPersonal: json['estadoPersonal'] as String,
      progresoEspecifico: json.containsKey('progresoEspecifico') ? json['progresoEspecifico'] as String? : null,
      agregadoEn: DateTime.parse(json['agregadoEn'] as String),
      elementoId: json['elementoId'] as int,
      elementoTitulo: json['elementoTitulo'] as String,
      // ¡CORREGIDO! Si 'elementoImagenPortadaUrl' es null en el JSON, Dart lo acepta como String?
      elementoImagenPortadaUrl: json['elementoImagenPortadaUrl'] as String?, 
      usuarioId: json['usuarioId'] as int,
    );
  }
}