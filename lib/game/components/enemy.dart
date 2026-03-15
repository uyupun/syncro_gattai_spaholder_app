import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../interfaces/damageable.dart';
import '../../interfaces/hp_readable.dart';
import '../../resources/game_image.dart';

class Enemy extends BodyComponent implements HpReadable, Damageable {
  final Vector2 _initialPosition;
  final double _radius;
  final double _spriteScale;
  final double _maxHp;
  double _currentHp;
  Sprite? _sprite;
  Sprite? _splashSprite;
  bool _isHit = false;

  Enemy({
    required Vector2 position,
    required double radius,
    required double spriteScale,
    double maxHp = 100,
  }) : _initialPosition = position.clone(),
       _radius = radius,
       _spriteScale = spriteScale,
       _maxHp = maxHp,
       _currentHp = maxHp;

  double get radius => _radius;

  @override
  double get hp => _currentHp;

  @override
  double get maxHp => _maxHp;

  @override
  void takeDamage(double amount) {
    // Why: HpBarのhpRatioが負値になると描画が壊れるためclampで下限0を保証
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _sprite = await Sprite.load(GameImage.rockmonster.path);
      _splashSprite = await Sprite.load(GameImage.rockmonsterSplash.path);
    } catch (e) {
      debugPrint('Failed to load image: $e');
    }
  }

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
      ..isSensor = true;
    final bodyDef = BodyDef()
      ..userData = this
      ..position = _initialPosition
      ..type = BodyType.static;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final hitboxPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, _radius, hitboxPaint);

    final hitboxBorder = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;
    canvas.drawCircle(Offset.zero, _radius, hitboxBorder);

    final currentSprite = _isHit ? _splashSprite : _sprite;

    if (currentSprite != null) {
      final size = _radius * _spriteScale;
      currentSprite.render(
        canvas,
        size: Vector2.all(size),
        anchor: Anchor.center,
      );
    } else {
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
