import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SnackBarHelper {
  static void showTopSnackBar(
    BuildContext
        context, // Nota: Ahora pedimos BuildContext directo, es más seguro para Overlays
    String message, {
    required bool isError,
    bool isNeutral = false,
  }) {
    final OverlayState overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;

    // Diseño del Banner/SnackBar
    final Widget toast = SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red[700]
                : isNeutral
                    ? Colors.grey[800]
                    : Colors.green[600],
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => overlayEntry.remove(),
                child: Text(
                  AppLocalizations.of(context)?.snackbarCloseButton ?? 'CERRAR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Crear la entrada del Overlay
    overlayEntry = OverlayEntry(
      builder: (context) {
        // Usamos un TweenAnimationBuilder para una entrada suave desde arriba
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) => overlayEntry.remove(),
              child: toast,
            ),
          ),
        );
      },
    );

    // Insertar en pantalla
    overlayState.insert(overlayEntry);

    // Auto-cerrar después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
