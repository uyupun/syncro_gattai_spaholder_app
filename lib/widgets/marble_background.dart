import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fragment Shader によるマーブル背景ウィジェット。
/// ロード完了まではダーク単色で表示し、シームレスに切り替わる。
class MarbleBackground extends StatefulWidget {
  final Widget? child;

  const MarbleBackground({super.key, this.child});

  @override
  State<MarbleBackground> createState() => _MarbleBackgroundState();
}

class _MarbleBackgroundState extends State<MarbleBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  double _elapsed = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadShader();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    setState(() {
      _elapsed = elapsed.inMicroseconds / 1e6;
    });
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'assets/shaders/marble_background.frag',
    );
    if (!mounted) return;
    setState(() {
      _shader = program.fragmentShader();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) {
      return Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: const Color(0xFF0A0212))),
          if (widget.child != null) Positioned.fill(child: widget.child!),
        ],
      );
    }

    return CustomPaint(
      painter: _MarblePainter(shader, _elapsed),
      child: widget.child,
    );
  }
}

class _MarblePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  const _MarblePainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    // ⭕️ GLSLの定義順（uSize.x, uSize.y, uTime）に合わせてインデックスを修正
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_MarblePainter old) => old.time != time;
}
