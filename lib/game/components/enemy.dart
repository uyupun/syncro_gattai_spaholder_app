import 'package:flame/cache.dart';
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
  final double _actionSpriteScale;
  final List<double>? _actionSpriteScales;
  final double _maxHp;
  final String _spritePath;
  final List<String> _actionSpritePaths;
  double _currentHp;
  Sprite? _normalSprite;
  final List<Sprite?> _actionSprites = [];
  Sprite? _currentSprite;

  Enemy({
    required Vector2 position,
    required double radius,
    required double spriteScale,
    double? actionSpriteScale,
    List<double>? actionSpriteScales,
    double maxHp = 100,
    String? spritePath,
    List<String>? actionSpritePaths,
  }) : _initialPosition = position.clone(),
       _radius = radius,
       _spriteScale = spriteScale,
       _actionSpriteScale = actionSpriteScale ?? spriteScale,
       _actionSpriteScales = actionSpriteScales,
       _maxHp = maxHp,
       _currentHp = maxHp,
       _spritePath = spritePath ?? GameImage.yugarock.path,
       _actionSpritePaths =
           actionSpritePaths ??
           [GameImage.yugarockRolling.path, GameImage.yugarockFillIn.path];

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

  void onHit() {}

  /// 技インデックスに対応するスプライトを1秒間表示する
  void showActionSprite(int index) {
    if (index < _actionSprites.length) {
      _currentSprite = _actionSprites[index];
    }
  }

  /// 通常スプライトに戻す
  void clearActionSprite() {
    _currentSprite = _normalSprite;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final illustImages = Images(prefix: 'assets/illust/');
    try {
      _normalSprite = await Sprite.load(_spritePath, images: illustImages);
      _currentSprite = _normalSprite;
      for (final path in _actionSpritePaths) {
        _actionSprites.add(await Sprite.load(path, images: illustImages));
      }
    } catch (e) {
      debugPrint('Failed to load image: $e');
    }
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

    if (_currentSprite != null) {
      double scale;
      if (_currentSprite == _normalSprite) {
        scale = _spriteScale;
      } else {
        final actionIndex = _actionSprites.indexOf(_currentSprite);
        final scales = _actionSpriteScales;
        scale =
            (scales != null && actionIndex >= 0 && actionIndex < scales.length)
            ? scales[actionIndex]
            : _actionSpriteScale;
      }
      final maxDim = _radius * scale;
      final src = _currentSprite!.srcSize;
      final aspectRatio = src.x / src.y;
      final renderSize = aspectRatio >= 1
          ? Vector2(maxDim, maxDim / aspectRatio)
          : Vector2(maxDim * aspectRatio, maxDim);
      _currentSprite!.render(canvas, size: renderSize, anchor: Anchor.center);
    } else {
      final paint = Paint()..color = Colors.redAccent;
      canvas.drawCircle(Offset.zero, _radius, paint);

      final border = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1;
      canvas.drawCircle(Offset.zero, _radius, border);
    }
  }
}
