import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Utilidad para mostrar notificaciones flotantes (Top SnackBars/Toasts) personalizadas.
/// Se muestran en la parte superior para no tapar la navegación inferior.
class SnackBarHelper {
  static void showTopSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
    bool isNeutral = false,
  }) {
    // Obtener el Overlay del contexto actual.
    // Es vital que el contexto venga de un Scaffold o Navigator hijo de MaterialApp.
    final OverlayState overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;

    // Definición de colores según tipo
    final Color bgColor = isError
        ? Colors.red.shade700
        : isNeutral
            ? Colors.grey.shade800
            : Colors.green.shade700;

    final IconData icon = isError
        ? Icons.error_outline
        : isNeutral
            ? Icons.info_outline
            : Icons.check_circle_outline;

    // Widget del Toast
    final Widget toast = SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: AppLocalizations.of(context).snackbarCloseButton,
              ),
            ],
          ),
        ),
      ),
    );

    // Crear la entrada del Overlay con animación
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0), // Animación de deslizamiento
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
              child: toast,
            ),
          ),
        );
      },
    );

    // Insertar en pantalla
    overlayState.insert(overlayEntry);

    // Auto-cerrar después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
