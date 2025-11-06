// lib/src/model/propuesta.dart

/// Modelo de datos para representar una Propuesta en la cola de moderación (RF14).
///
/// Corresponde 1:1 con 'PropuestaResponseDTO.java'.
class Propuesta {
  final int id;
  final String tituloSugerido;
  final String? descripcionSugerida; // CORREGIDO: Es nulable (como dijiste)
  final String tipoSugerido;
  final String generosSugeridos;
  final String estadoPropuesta; // "PENDIENTE", "APROBADO", "RECHAZADO"
  final String? comentariosRevision; // NUEVO: El campo que causaba el crash
  final DateTime fechaPropuesta; // CORREGIDO: El nombre del campo
  final String proponenteUsername;
  final String? revisorUsername; // Es nulable

  Propuesta({
    required this.id,
    required this.tituloSugerido,
    this.descripcionSugerida,
    required this.tipoSugerido,
    required this.generosSugeridos,
    required this.estadoPropuesta,
    this.comentariosRevision, // NUEVO
    required this.fechaPropuesta, // CORREGIDO
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
      comentariosRevision: json['comentariosRevision'], // NUEVO
      fechaPropuesta: DateTime.parse(json['fechaPropuesta']), // CORREGIDO
      proponenteUsername: json['proponenteUsername'],
      revisorUsername: json['revisorUsername'],
    );
  }
}