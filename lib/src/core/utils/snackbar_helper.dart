// Archivo: lib/src/core/utils/snackbar_helper.dart
// (¡REFACTORIZADO!)

import 'package:flutter/material.dart';

class SnackBarHelper {
  /// Muestra un SnackBar en la PARTE SUPERIOR de la pantalla.
  /// Esto evita que el teclado lo oculte (Bug 5b).
  static void showTopSnackBar(
    ScaffoldMessengerState msgContext,
    String message, {
    required bool isError,
  }) {
    // Oculta cualquier SnackBar anterior
    msgContext.hideCurrentSnackBar();
    
    // Crea el nuevo SnackBar
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isError ? Colors.red[700] : Colors.green[600],
      
      // --- ¡CORREGIDO (Bug 5b)! ---
      // 'fixed' fuerza al SnackBar a no moverse cuando aparece el teclado.
      behavior: SnackBarBehavior.fixed, 
      margin: null, // Se anula el margen
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      // ---
      
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'CERRAR',
        textColor: Colors.white,
        onPressed: () {
          msgContext.hideCurrentSnackBar();
        },
      ),
    );

    msgContext.showSnackBar(snackBar);
  }
}