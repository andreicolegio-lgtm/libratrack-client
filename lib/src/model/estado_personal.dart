import 'package:flutter/material.dart';
import '../core/l10n/app_localizations.dart';

enum EstadoPersonal {
  pendiente('PENDIENTE'),
  enProgreso('EN_PROGRESO'),
  terminado('TERMINADO'),
  abandonado('ABANDONADO');

  const EstadoPersonal(this.apiValue);
  final String apiValue;

  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return apiValue;
    }

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

  static EstadoPersonal fromString(String apiValue) {
    return EstadoPersonal.values.firstWhere((e) => e.apiValue == apiValue,
        orElse: () => EstadoPersonal.pendiente);
  }
}
