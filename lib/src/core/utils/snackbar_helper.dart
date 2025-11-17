import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SnackBarHelper {
  static void showTopSnackBar(
    ScaffoldMessengerState msgContext,
    String message, {
    required bool isError,
    bool isNeutral = false,
  }) {
    msgContext.hideCurrentSnackBar();

    final l10n = AppLocalizations.of(msgContext.context);
    final String closeLabel = l10n?.snackbarCloseButton ?? 'CERRAR';

    final SnackBar snackBar = SnackBar(
      content: Text(
        message,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isError
          ? Colors.red[700]
          : isNeutral
              ? Colors.grey[800]
              : Colors.green[600],
      behavior: SnackBarBehavior.fixed,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: closeLabel,
        textColor: Colors.white,
        onPressed: () {
          msgContext.hideCurrentSnackBar();
        },
      ),
    );

    msgContext.showSnackBar(snackBar);
  }
}
