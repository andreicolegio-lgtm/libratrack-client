// lib/src/model/catalogo_entrada.dart

/// Modelo de datos para representar una única entrada
/// en el catálogo personal del usuario.
///
/// Corresponde al 'CatalogoPersonalResponseDTO.java' del backend.
class CatalogoEntrada {
  final int id;
  final String estadoPersonal; // "PENDIENTE", "EN_PROGRESO", "TERMINADO", etc.
  final String? progresoEspecifico; // "T2:E5", "Cap. 10", etc.
  final DateTime agregadoEn;
  final int elementoId;
  final String elementoTitulo;
  final String elementoImagenPortadaUrl; // ¡NUEVO CAMPO EN LA CLASE!
  final int usuarioId;

  CatalogoEntrada({
    required this.id,
    required this.estadoPersonal,
    this.progresoEspecifico,
    required this.agregadoEn,
    required this.elementoId,
    required this.elementoTitulo,
    required this.elementoImagenPortadaUrl, // ¡AÑADIDO AL CONSTRUCTOR!
    required this.usuarioId,
  });

  /// "Constructor de fábrica" (Factory Constructor) para crear una instancia
  /// a partir del JSON (Map) decodificado de la API.
  factory CatalogoEntrada.fromJson(Map<String, dynamic> json) {
    return CatalogoEntrada(
      id: json['id'] as int,
      // Accede al Enum 'EstadoPersonal' de la API
      estadoPersonal: json['estadoPersonal'] as String,
      progresoEspecifico: json['progresoEspecifico'] as String?,
      agregadoEn: DateTime.parse(json['agregadoEn'] as String), // Convierte el String a DateTime
      elementoId: json['elementoId'] as int,
      elementoTitulo: json['elementoTitulo'] as String,
      elementoImagenPortadaUrl: json['elementoImagenPortadaUrl'] as String, // ¡MAPEADO DEL JSON!
      usuarioId: json['usuarioId'] as int,
    );
  }
}