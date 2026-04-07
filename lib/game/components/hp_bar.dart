import 'dart:ui';

import 'package:flame/components.dart';

import '../../interfaces/hp_readable.dart';

class HpBar extends PositionComponent {
  final HpReadable hpReadable;
  final double barWidth;
  final double barHeight;

  // Why: render()は60FPSで呼ばれるため、Paint生成をフィールドに引き上げてGC負荷を削減
  static final Paint _bgPaint = Paint()..color = const Color(0xFF555555);
  final Paint _fgPaint = Paint();

  HpBar({
    required this.hpReadable,
    required this.barWidth,
    required this.barHeight,
    super.position,
  }) : super(size: Vector2(barWidth, barHeight));

  double get hpRatio =>
      hpReadable.maxHp > 0 ? hpReadable.hp / hpReadable.maxHp : 0;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, barHeight), _bgPaint);

    final ratio = hpRatio.clamp(0.0, 1.0);
    final color = ratio > 0.5
        ? Color.lerp(
            const Color(0xFFFFFF00),
            const Color(0xFF00FF00),
            (ratio - 0.5) * 2,
          )!
        : Color.lerp(
            const Color(0xFFFF0000),
            const Color(0xFFFFFF00),
            ratio * 2,
          )!;

    _fgPaint.color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth * ratio, barHeight), _fgPaint);
  }
}
