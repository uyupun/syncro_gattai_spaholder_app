import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../resources/game_image.dart';
import '../enemy_config.dart';

class Enemy extends BodyComponent {
  final Vector2 _initialPosition;
  final double _radius;
  Sprite? _sprite;
  Sprite? _splashSprite;
  bool _isHit = false;

  Enemy({
    required Vector2 position,
    required double radius,
  })  : _initialPosition = position.clone(),
        _radius = radius;

  double get radius => _radius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _sprite = await Sprite.load(GameImage.rockmonster.path);
      _splashSprite = await Sprite.load(GameImage.rockmonsterSplash.path);
    } catch (e) {
      // 画像の読み込みに失敗した場合はスプライトをnullのままにする
      debugPrint('Failed to load image: $e');
    }
  }

  /// 敵がヒットされた時に呼び出される
  void onHit() {
    _isHit = true;
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = _radius;
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.5
      ..density = 1.0
      ..friction = 0.3
      ..isSensor = true;  // センサーとして設定（物理的な衝突を無効化、貫通する）
    final bodyDef = BodyDef()
      ..userData = this
      ..position = _initialPosition
      ..type = BodyType.static;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    // 衝突判定の可視化（半透明の赤い円）
    final hitboxPaint = Paint()
      ..color = Colors.transparent // Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, _radius, hitboxPaint);

    // 衝突判定の境界線
    final hitboxBorder = Paint()
      ..color = Colors.transparent // Colors.red.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;
    canvas.drawCircle(Offset.zero, _radius, hitboxBorder);

    // ヒット状態に応じて画像を切り替え
    final currentSprite = _isHit ? _splashSprite : _sprite;

    if (currentSprite != null) {
      // 画像を使用してレンダリング（サイズを2倍に）
      final size = _radius * EnemyConfig.instance.spriteScale;
      currentSprite.render(
        canvas,
        size: Vector2.all(size),
        anchor: Anchor.center,
      );
    } else {
      // 画像がない場合は従来の円描画
      final paint = Paint()..color = _isHit ? Colors.orange : Colors.redAccent;
      canvas.drawCircle(Offset.zero, _radius, paint);

      final border = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1;
      canvas.drawCircle(Offset.zero, _radius, border);
    }
  }
}
