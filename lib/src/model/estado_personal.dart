import 'package:flutter/material.dart';
import '../core/l10n/app_localizations.dart';

/// Representa el estado de consumo de un elemento en el catálogo personal.
enum EstadoPersonal {
  pendiente('PENDIENTE'),
  enProgreso('EN_PROGRESO'),
  terminado('TERMINADO'),
  abandonado('ABANDONADO');

  final String apiValue;
  const EstadoPersonal(this.apiValue);

  /// Convierte un string del backend al Enum correspondiente.
  static EstadoPersonal fromString(String value) {
    return EstadoPersonal.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => EstadoPersonal.pendiente,
    );
  }

  /// Obtiene el nombre localizado para mostrar en la UI.
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (this) {
      case EstadoPersonal.pendiente:
        return l10n.catalogPending;
      case EstadoPersonal.enProgreso:
        return l10n.catalogInProgress;
      case EstadoPersonal.terminado:
        return l10n.catalogFinished;
      case EstadoPersonal.abandonado:
        return l10n.catalogDropped;
    }
  }

  /// Color asociado al estado para chips y textos.
  Color get color {
    switch (this) {
      case EstadoPersonal.pendiente:
        return Colors.grey;
      case EstadoPersonal.enProgreso:
        return Colors.blue;
      case EstadoPersonal.terminado:
        return Colors.green;
      case EstadoPersonal.abandonado:
        return Colors.red;
    }
  }
}
