import 'package:flutter/material.dart';
import '../core/l10n/app_localizations.dart';

/// Estado de una solicitud de contenido en el panel de moderación.
enum EstadoPropuesta {
  pendiente('PENDIENTE'),
  aprobado('APROBADO'),
  rechazado('RECHAZADO');

  final String apiValue;
  const EstadoPropuesta(this.apiValue);

  static EstadoPropuesta fromString(String value) {
    return EstadoPropuesta.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => EstadoPropuesta.pendiente,
    );
  }

  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (this) {
      case EstadoPropuesta.pendiente:
        return l10n.modPanelStatusPending;
      case EstadoPropuesta.aprobado:
        return l10n.modPanelStatusApproved;
      case EstadoPropuesta.rechazado:
        return l10n.modPanelStatusRejected;
    }
  }

  Color get color {
    switch (this) {
      case EstadoPropuesta.pendiente:
        return Colors.orange;
      case EstadoPropuesta.aprobado:
        return Colors.green;
      case EstadoPropuesta.rechazado:
        return Colors.red;
    }
  }
}
