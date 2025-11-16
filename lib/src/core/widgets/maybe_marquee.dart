import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MaybeMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double height;

  const MaybeMarquee({
    required this.text,
    required this.style,
    super.key,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        if (textPainter.width > constraints.maxWidth) {
          return SizedBox(
            height: height,
            child: Marquee(
              text: text,
              style: style,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 30.0,
              velocity: 40.0,
              pauseAfterRound: const Duration(seconds: 2),
              fadingEdgeStartFraction: 0.1,
              fadingEdgeEndFraction: 0.1,
            ),
          );
        } else {
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
