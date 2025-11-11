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

    // --- CORRECCIÓN ---
    // Calcula la altura de la pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    // Calcula la altura del AppBar + Safe Area
    final topPadding = MediaQuery.of(context).viewPadding.top + kToolbarHeight;
    // Calcula el margen inferior para "empujar" el SnackBar hacia arriba,
    // dejando espacio para él (ej. 100px) y el padding superior.
    final bottomMargin = screenHeight - topPadding - 100; 

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        // --- LÍNEA CORREGIDA ---
        // Usamos 'bottom' para empujarlo hacia arriba, en lugar de 'top'
        margin: EdgeInsets.only(
          bottom: bottomMargin, // <--- CORREGIDO
          left: 16,
          right: 16,
        ),
      ),
    );
  }
}