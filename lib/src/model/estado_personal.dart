enum EstadoPersonal {
  pendiente,
  enProgreso,
  terminado,
  abandonado;

  static EstadoPersonal fromString(String apiValue) {
    switch (apiValue) {
      case 'PENDIENTE':
        return EstadoPersonal.pendiente;
      case 'EN_PROGRESO':
        return EstadoPersonal.enProgreso;
      case 'TERMINADO':
        return EstadoPersonal.terminado;
      case 'ABANDONADO':
        return EstadoPersonal.abandonado;
      default:
        return EstadoPersonal.pendiente;
    }
  }

  String get apiValue {
    return name;
  }

  String get displayName {
    switch (this) {
      case EstadoPersonal.pendiente:
        return 'Pendiente';
      case EstadoPersonal.enProgreso:
        return 'En Progreso';
      case EstadoPersonal.terminado:
        return 'Terminado';
      case EstadoPersonal.abandonado:
        return 'Abandonado';
    }
  }
}
