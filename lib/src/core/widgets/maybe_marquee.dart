// lib/src/core/widgets/maybe_marquee.dart
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// Un widget que solo aplica el efecto Marquee si el texto es
/// demasiado largo para caber en el espacio disponible.
class MaybeMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double height; // Altura fija para el contenedor

  const MaybeMarquee({
    super.key,
    required this.text,
    required this.style,
    this.height = 22, // Altura por defecto (para titleMedium)
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder nos da el ancho del widget padre
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. Usamos un TextPainter para medir el ancho del texto
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        // 2. Comparamos el ancho del texto con el ancho del contenedor
        if (textPainter.width > constraints.maxWidth) {
          // 3. Si el texto se desborda, usamos Marquee
          return SizedBox(
            height: height, 
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 30.0,
              velocity: 40.0,
              pauseAfterRound: const Duration(seconds: 2),
              showFadingOnlyWhenScrolling: true,
              fadingEdgeStartFraction: 0.1,
              fadingEdgeEndFraction: 0.1,
            ),
          );
        } else {
          // 4. Si el texto cabe, usamos un Text normal
          return SizedBox(
            height: height,
            child: Text(
              text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
      },
    );
  }
}