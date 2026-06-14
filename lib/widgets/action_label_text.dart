import 'package:flutter/material.dart';

/// 技名表示用テキスト。黒縁取り+グラデーション塗りのインパクトのある見た目にする。
class ActionLabelText extends StatelessWidget {
  final String label;
  final List<Color> colors;

  static const _fontSize = 28.0;

  const ActionLabelText({super.key, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.bold,
    );

    return Stack(
      children: [
        Text(
          label,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = Colors.black,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(label, style: textStyle.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
