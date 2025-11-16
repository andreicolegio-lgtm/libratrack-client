enum EstadoPropuesta {
  PENDIENTE,
  APROBADO,
  RECHAZADO;

  String get apiValue {
    return name;
  }

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
