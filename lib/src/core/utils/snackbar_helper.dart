// lib/src/core/utils/snackbar_helper.dart
import 'package:flutter/material.dart';

/// Helper de UI para mostrar SnackBars de forma consistente (Punto 3).
/// Todos los SnackBars se mostrarán en la parte superior.
class SnackBarHelper {
  
  // CORREGIDO: Acepta ScaffoldMessengerState (msgContext) en lugar de BuildContext
  static void showTopSnackBar(
    ScaffoldMessengerState messenger, 
    String message, 
    {bool isError = false}
  ) {
    // Asegura que no se muestren SnackBars antiguos
    messenger.hideCurrentSnackBar();
    
    // Obtenemos el contexto (de forma segura) desde el messenger
    final context = messenger.context;

    // Calcula el margen superior
    final topMargin = MediaQuery.of(context).viewPadding.top + kToolbarHeight;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          top: topMargin,
          left: 16,
          right: 16,
        ),
      ),
    );
  }
}