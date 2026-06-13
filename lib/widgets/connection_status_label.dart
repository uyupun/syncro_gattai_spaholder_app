import 'package:flutter/material.dart';

class ConnectionStatusLabel extends StatelessWidget {
  final String text;

  const ConnectionStatusLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 16,
      color: Color(0xFF1A1A1A),
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
              ..strokeWidth = 2
              ..color = const Color(0xFFF5F5F5),
          ),
        ),
        Text(text, textAlign: TextAlign.center, style: style),
      ],
    );
  }
}
