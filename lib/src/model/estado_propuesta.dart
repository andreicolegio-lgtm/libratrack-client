// ignore_for_file: constant_identifier_names
// lib/src/model/estado_propuesta.dart

/// Representa los estados de la cola de moderación (RF14, RF15).
///
/// Coincide con el Enum 'EstadoPropuesta' de la API de Spring Boot
///
enum EstadoPropuesta {
  PENDIENTE,
  APROBADO,
  RECHAZADO;

  /// Método auxiliar para obtener el String que la API espera
  String get apiValue {
    // .name es una propiedad de Enum que devuelve el nombre como String
    // ej. EstadoPropuesta.PENDIENTE.name => "PENDIENTE"
    return name;
  }
  
  /// Método auxiliar para mostrar un nombre amigable en la UI
  String get displayName {
     switch (this) {
      case EstadoPropuesta.PENDIENTE:
        return 'Pendientes';
      case EstadoPropuesta.APROBADO:
        return 'Aprobadas';
      case EstadoPropuesta.RECHAZADO:
        return 'Rechazadas';
    }
  }
}