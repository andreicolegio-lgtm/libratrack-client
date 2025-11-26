import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// Un widget de texto inteligente que solo se desplaza (scroll) si el texto
/// es más largo que el espacio disponible.
class MaybeMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double height;
  final Axis scrollAxis;

  const MaybeMarquee({
    required this.text,
    this.style = const TextStyle(),
    super.key,
    this.height = 24, // Altura suficiente para una línea de texto estándar
    this.scrollAxis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // 1. Calcular el ancho que ocuparía el texto estático
          final TextSpan span = TextSpan(text: text, style: style);
          final TextPainter tp = TextPainter(
            text: span,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );
          tp.layout();

          // 2. Comparar con el ancho disponible
          // Si el texto es más ancho que el contenedor, usamos Marquee
          if (tp.width > constraints.maxWidth) {
            return Marquee(
              text: text,
              style: style,
              scrollAxis: scrollAxis,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 20.0,
              velocity: 30.0, // Velocidad suave
              pauseAfterRound:
                  const Duration(seconds: 2), // Pausa al llegar al final
              startPadding: 2.0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
              fadingEdgeStartFraction: 0.05, // Desvanecimiento elegante
              fadingEdgeEndFraction: 0.05,
            );
          }

          // 3. Si cabe, mostramos Texto estático normal
          else {
            return Text(
              text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }
        },
      ),
    );
  }
}
