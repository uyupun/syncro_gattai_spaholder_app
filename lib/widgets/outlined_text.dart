import 'package:flutter/material.dart';

class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;

  const OutlinedText({super.key, required this.text, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      color: const Color(0xFF1A1A1A),
      fontWeight: FontWeight.bold,
    );

    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = const Color(0xFFF5F5F5),
          ),
        ),
        Text(text, textAlign: TextAlign.center, style: style),
      ],
    );
  }
}
