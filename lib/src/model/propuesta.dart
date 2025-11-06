// lib/src/model/propuesta.dart

/// Modelo de datos para representar una Propuesta en la cola de moderación (RF14).
///
/// Corresponde al 'PropuestaResponseDTO.java' del backend.
class Propuesta {
  final int id;
  final String tituloSugerido;
  final String descripcionSugerida;
  final String tipoSugerido;
  final String generosSugeridos;
  final String estadoPropuesta; // "PENDIENTE", "APROBADO", "RECHAZADO"
  final DateTime fechaCreacion;
  final String proponenteUsername; // Quién lo propuso
  final String? revisorUsername; // Quién lo revisó (si no está pendiente)

  Propuesta({
    required this.id,
    required this.tituloSugerido,
    required this.descripcionSugerida,
    required this.tipoSugerido,
    required this.generosSugeridos,
    required this.estadoPropuesta,
    required this.fechaCreacion,
    required this.proponenteUsername,
    this.revisorUsername,
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
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      proponenteUsername: json['proponenteUsername'],
      revisorUsername: json['revisorUsername'],
    );
  }
}