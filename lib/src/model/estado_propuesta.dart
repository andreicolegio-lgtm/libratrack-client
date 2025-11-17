import 'package:flutter/material.dart';
import '../core/l10n/app_localizations.dart';

enum EstadoPropuesta {
  pendiente('PENDIENTE'),
  aprobado('APROBADO'),
  rechazado('RECHAZADO');

  const EstadoPropuesta(this.apiValue);
  final String apiValue;

  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return apiValue;
    }

    switch (this) {
      case EstadoPropuesta.pendiente:
        return l10n.modPanelStatusPending;
      case EstadoPropuesta.aprobado:
        return l10n.modPanelStatusApproved;
      case EstadoPropuesta.rechazado:
        return l10n.modPanelStatusRejected;
    }
  }

  static EstadoPropuesta fromString(String apiValue) {
    return EstadoPropuesta.values.firstWhere((e) => e.apiValue == apiValue,
        orElse: () => EstadoPropuesta.pendiente);
  }
}
