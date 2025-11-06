// ignore_for_file: constant_identifier_names
// lib/src/model/estado_personal.dart

/// Representa los estados personales del catálogo (RF06).
///
/// Coincide con el Enum 'EstadoPersonal' de la API de Spring Boot
///.
enum EstadoPersonal {
  PENDIENTE,
  EN_PROGRESO,
  TERMINADO,
  ABANDONADO;

  /// Método auxiliar para convertir el String de la API a nuestro Enum
  static EstadoPersonal fromString(String apiValue) {
    switch (apiValue) {
      case 'PENDIENTE':
        return EstadoPersonal.PENDIENTE;
      case 'EN_PROGRESO':
        return EstadoPersonal.EN_PROGRESO;
      case 'TERMINADO':
        return EstadoPersonal.TERMINADO;
      case 'ABANDONADO':
        return EstadoPersonal.ABANDONADO;
      default:
        // Fallback por si acaso
        return EstadoPersonal.PENDIENTE;
    }
  }

  /// Método auxiliar para obtener el String que la API espera
  String get apiValue {
    // .name es una propiedad de Enum que devuelve el nombre como String
    // ej. EstadoPersonal.EN_PROGRESO.name => "EN_PROGRESO"
    return name;
  }
  
  /// Método auxiliar para mostrar un nombre amigable en la UI
  String get displayName {
     switch (this) {
      case EstadoPersonal.PENDIENTE:
        return 'Pendiente';
      case EstadoPersonal.EN_PROGRESO:
        return 'En Progreso';
      case EstadoPersonal.TERMINADO:
        return 'Terminado';
      case EstadoPersonal.ABANDONADO:
        return 'Abandonado';
    }
  }
}