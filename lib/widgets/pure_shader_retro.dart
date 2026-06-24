import 'dart:async';
import 'dart:math'; // 👈 Random を使うので必須
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

class PureShaderRetro extends StatefulWidget {
  final Widget child;

  const PureShaderRetro({super.key, required this.child});

  @override
  State<PureShaderRetro> createState() => _PureShaderRetroState();
}

class _PureShaderRetroState extends State<PureShaderRetro> {
  ui.FragmentProgram? _program;
  late Ticker _ticker;
  double _elapsedTime = 0.0;

  // 💡 ノイズコントロール用の変数
  double _noiseIntensity = 0.0;
  int _noiseFrameCount = 0;
  final Random _random = Random();

  final GlobalKey _globalKey = GlobalKey();
  ui.Image? _capturedImage;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _loadShader();

    _ticker = Ticker((Duration elapsed) async {
      if (_program == null) return;

      if (!_isCapturing) {
        _isCapturing = true;
        final image = await _captureWidget();
        if (mounted) {
          setState(() {
            _elapsedTime =
                elapsed.inMicroseconds / Duration.microsecondsPerSecond;

            // 💡 【ここがポイント】ちょいちょいノイズを入れるロジック
            if (_noiseFrameCount > 0) {
              // ノイズ持続中：カウントダウン
              _noiseFrameCount--;
              if (_noiseFrameCount == 0) {
                _noiseIntensity = 0.0; // 終わったら通常画面に戻す
              }
            } else {
              // 通常時：約1.5%の確率でノイズのトリガーを引く（60fpsなら1〜2秒に1回程度）
              if (_random.nextDouble() > 0.985) {
                _noiseIntensity =
                    _random.nextDouble() * 0.7 + 0.3; // ノイズの強さをランダムに決定
                _noiseFrameCount =
                    _random.nextInt(4) + 2; // 2〜5フレームの間だけノイズを持続させる
              }
            }

            _capturedImage?.dispose();
            _capturedImage = image;
          });
        }
        _isCapturing = false;
      }
    });
  }

  // (中略 - _loadShader, _captureWidget, dispose は前回と同じ)
  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'assets/shaders/retro_filter.frag',
    );
    if (mounted) {
      setState(() {
        _program = program;
      });
      _ticker.start();
    }
  }

  Future<ui.Image?> _captureWidget() async {
    try {
      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(pixelRatio: 1.0);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _capturedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 1. 奥側：元のコンテンツ（動画やボタンなど）
        RepaintBoundary(key: _globalKey, child: widget.child),

        // 2. 手前側：シェーダーフィルター
        if (_capturedImage != null)
          Positioned.fill(
            // 💡 ここを追加！手前のフィルターを「タッチ透過」にします
            child: IgnorePointer(
              ignoring: true, // タッチイベントを完全に無視して後ろに流す
              child: CustomPaint(
                painter: RetroPainter(
                  shader: _program!.fragmentShader(),
                  time: _elapsedTime,
                  noiseIntensity: _noiseIntensity,
                  image: _capturedImage!,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RetroPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final double noiseIntensity; // 👈 変更
  final ui.Image image;

  RetroPainter({
    required this.shader,
    required this.time,
    required this.noiseIntensity, // 👈 変更
    required this.image,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, noiseIntensity); // 👈 3番目は uNoiseIntensity になる

    shader.setImageSampler(0, image);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant RetroPainter oldDelegate) {
    return true;
  }
}
