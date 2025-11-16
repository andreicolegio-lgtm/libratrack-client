enum EstadoPropuesta {
  pendiente,
  aprobado,
  rechazado;

  String get apiValue {
    return name;
  }

  String get displayName {
    switch (this) {
      case EstadoPropuesta.pendiente:
        return 'Pendientes';
      case EstadoPropuesta.aprobado:
        return 'Aprobadas';
      case EstadoPropuesta.rechazado:
        return 'Rechazadas';
    }
  }
}
