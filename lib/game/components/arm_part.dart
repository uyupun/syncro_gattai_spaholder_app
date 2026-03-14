import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class ArmPart extends BodyComponent {
  final Vector2 _pos;
  final Vector2 _size;
  final bool _isStatic;
  final Color _color;
  final String? _imagePath;
  final bool isDrill;
  final double _tipRadius;
  final Offset _tipOffset;
  Sprite? _sprite;

  ArmPart({
    required Vector2 position,
    required Vector2 size,
    required bool isStatic,
    required Color color,
    String? imagePath,
    this.isDrill = false,
    double? tipRadius,
    Offset? tipOffset,
  }) : _pos = position,
       _size = size,
       _isStatic = isStatic,
       _color = color,
       _imagePath = imagePath,
       _tipRadius = tipRadius ?? 0.0,
       _tipOffset = tipOffset ?? Offset.zero {
    assert(!isDrill || _tipRadius > 0, 'isDrill=true requires tipRadius > 0');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_imagePath != null) {
      try {
        _sprite = await Sprite.load(_imagePath);
      } catch (e) {
        // 画像の読み込みに失敗した場合はスプライトをnullのままにする
        debugPrint('Failed to load image: $_imagePath, error: $e');
      }
    }
  }

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(_size.x / 2, _size.y / 2, Vector2.zero(), 0);
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.2
      ..density = 2.0
      ..friction = 0.3
      ..filter.groupIndex = -1;
    final bodyDef = BodyDef()
      ..userData = this
      ..position = _pos
      ..type = _isStatic ? BodyType.static : BodyType.dynamic
      ..angularDamping = 0.5
      ..linearDamping = 0.1;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    // ドリル（前腕）の場合、先端の当たり判定を可視化
    if (isDrill) {
      final hitboxPaint = Paint()
        ..color = Colors
            .transparent // Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(_tipOffset, _tipRadius, hitboxPaint);

      // 当たり判定の境界線
      final hitboxBorder = Paint()
        ..color = Colors
            .transparent // Colors.blue.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.2;
      canvas.drawCircle(_tipOffset, _tipRadius, hitboxBorder);
    }

    if (_sprite != null) {
      // 画像を使用してレンダリング（アスペクト比を維持）
      final spriteSize = _sprite!.srcSize;
      final aspectRatio = spriteSize.x / spriteSize.y;

      // 指定されたサイズ内でアスペクト比を維持しながらフィット
      Vector2 renderSize;
      if (_size.x / _size.y > aspectRatio) {
        // 高さに合わせてスケール
        renderSize = Vector2(_size.y * aspectRatio, _size.y);
      } else {
        // 幅に合わせてスケール
        renderSize = Vector2(_size.x, _size.x / aspectRatio);
      }

      _sprite!.render(canvas, size: renderSize, anchor: Anchor.center);
    } else {
      // 画像がない場合は従来の矩形描画
      final paint = Paint()..color = _color;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: _size.x,
        height: _size.y,
      );
      canvas.drawRect(rect, paint);
      final border = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1;
      canvas.drawRect(rect, border);
    }

    // ジョイント位置の表示（画像使用時は透明化）
    if (_sprite == null) {
      // 画像がない場合のみジョイント位置を表示
      final jointPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
      canvas.drawCircle(Offset(0, -_size.y / 2 + 0.5), 0.4, jointPaint);
      canvas.drawCircle(Offset(0, _size.y / 2 - 0.5), 0.4, jointPaint);
    }
  }
}
