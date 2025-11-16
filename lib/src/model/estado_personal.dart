enum EstadoPersonal {
  PENDIENTE,
  EN_PROGRESO,
  TERMINADO,
  ABANDONADO;

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
        return EstadoPersonal.PENDIENTE;
    }
  }

  String get apiValue {
    return name;
  }

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
