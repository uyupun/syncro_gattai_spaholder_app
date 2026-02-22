import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../interfaces/ble_service.dart';
import '../resources/game_audio.dart';
import '../resources/game_image.dart';
import 'arm_layout_config.dart';
import 'components/arm_part.dart';
import 'components/enemy.dart';
import 'game_config.dart';

class RobotArmGame extends Forge2DGame {
  final VoidCallback? onGameClear;
  final BleService bleService;

  RobotArmGame({this.onGameClear, required this.bleService})
      : super(gravity: GameConfig.instance.gravity, zoom: GameConfig.instance.zoom);

  late ArmPart shoulder;
  late ArmPart upperArm;
  late ArmPart foreArm;

  RevoluteJoint? shoulderJoint;
  RevoluteJoint? elbowJoint;

  bool _isStraightening = false;
  double _straighteningTimer = 0;

  // ランダム動作用
  bool isRandomMode = false;
  final Random _random = Random();
  double _randomChangeTimer = 0;

  // ヒットチェック用
  final List<Enemy> enemies = [];
  bool _isCleared = false;
  bool _physicsStoppedOnHit = false;
  final ValueNotifier<bool> showSuccessMessage = ValueNotifier<bool>(false);

  // 背景画像
  Sprite? _backgroundSprite;

  @override
  Color backgroundColor() => const Color(0xFFFFFFFF);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    // --- 背景画像を読み込み ---
    try {
      _backgroundSprite = await Sprite.load(GameImage.gameBackground.path);
    } catch (e) {
      debugPrint(
        'Failed to load background image: game_background.jpg, error: $e',
      );
    }

    // --- 敵を配置 ---
    await _spawnEnemies();

    // --- パーツ生成 ---
    final layout = ArmLayoutConfig.instance;

    upperArm = ArmPart(
        position: layout.upperArmPosition,
        size: layout.upperArmSize,
        isStatic: false,
        color: Colors.blueAccent,
        imagePath: GameImage.upperArm.path);
    await world.add(upperArm);

    foreArm = ArmPart(
        position: layout.foreArmPosition,
        size: layout.foreArmSize,
        isStatic: false,
        color: Colors.lightBlueAccent,
        imagePath: GameImage.drill.path,
        isDrill: true);
    await world.add(foreArm);

    shoulder = ArmPart(
        position: layout.shoulderPosition,
        size: layout.shoulderSize,
        isStatic: true,
        color: Colors.grey,
        imagePath: GameImage.upperBody.path);
    await world.add(shoulder);

    // --- ジョイント生成 ---
    final shoulderJointDef = RevoluteJointDef()
      ..bodyA = shoulder.body
      ..bodyB = upperArm.body
      ..collideConnected = false
      ..localAnchorA.setFrom(layout.shoulderAnchorA)
      ..localAnchorB.setFrom(layout.shoulderAnchorB)
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = GameConfig.instance.shoulderTorque;
    shoulderJoint = RevoluteJoint(shoulderJointDef);
    world.createJoint(shoulderJoint!);

    final elbowJointDef = RevoluteJointDef()
      ..bodyA = upperArm.body
      ..bodyB = foreArm.body
      ..collideConnected = false
      ..localAnchorA.setFrom(layout.elbowAnchorA)
      ..localAnchorB.setFrom(layout.elbowAnchorB)
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = GameConfig.instance.elbowTorque;
    elbowJoint = RevoluteJoint(elbowJointDef);
    world.createJoint(elbowJoint!);

    // --- 常にランダムモードを有効化 ---
    startRandomMode();
  }

  Future<void> _spawnEnemies() async {
    final enemyPos = Vector2(
      GameConfig.instance.shoulderPos.x + GameConfig.instance.armLength + GameConfig.instance.enemyRadius,
      0,
    );
    final enemy = Enemy(position: enemyPos, radius: GameConfig.instance.enemyRadius);
    enemies.add(enemy);
    await world.add(enemy);
  }

  /// 腕の先端のワールド座標を取得
  Vector2 get armTipPosition {
    return foreArm.body.worldPoint(Vector2(0, ArmLayoutConfig.instance.armTipLocalY));
  }

  /// Snap Straight押下時に1回だけヒットチェック
  void _checkHitOnce() {
    if (_isCleared) return;

    final tipPos = armTipPosition;
    for (final enemy in enemies) {
      final distance = tipPos.distanceTo(enemy.body.position);
      final hitDistance = GameConfig.instance.tipRadius + enemy.radius;
      if (distance < hitDistance) {
        enemy.onHit();

        _isCleared = true;
        _physicsStoppedOnHit = true;

        _stopAllPhysics();

        unawaited(Future.delayed(const Duration(seconds: 3), () async {
          showSuccessMessage.value = true;
          try {
            await bleService.sendBool(true);
          } catch (e) {
            debugPrint('sendBool error: $e');
          }
        }));
        FlameAudio.bgm.stop();
        FlameAudio.bgm.play(GameAudio.clear.path);

        return;
      }
    }
  }

  /// タップでゲームクリア画面に遷移
  void proceedToGameClear() {
    if (_isCleared) {
      onGameClear?.call();
    }
  }

  /// 物理演算を完全に停止
  void _stopAllPhysics() {
    stopRandomMode();
    stopStraightening();
    stopShoulder();
    stopElbow();

    shoulder.body.linearVelocity = Vector2.zero();
    shoulder.body.angularVelocity = 0.0;
    upperArm.body.linearVelocity = Vector2.zero();
    upperArm.body.angularVelocity = 0.0;
    foreArm.body.linearVelocity = Vector2.zero();
    foreArm.body.angularVelocity = 0.0;

    upperArm.body.setType(BodyType.static);
    foreArm.body.setType(BodyType.static);
  }

  @override
  void render(Canvas canvas) {
    if (_backgroundSprite != null) {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
      canvas.saveLayer(null, paint);

      final screenSize = size;
      final spriteSize = _backgroundSprite!.srcSize;
      final aspectRatio = spriteSize.x / spriteSize.y;

      final renderWidth = screenSize.x;
      final renderHeight = renderWidth / aspectRatio;
      final renderSize = Vector2(renderWidth, renderHeight);

      _backgroundSprite!.render(
        canvas,
        size: renderSize,
        anchor: Anchor.center,
        position: screenSize / 2,
      );

      canvas.restore();
    }

    super.render(canvas);
  }

  @override
  void update(double dt) {
    if (_physicsStoppedOnHit) {
      return;
    }

    super.update(dt);

    if (isRandomMode) {
      _randomChangeTimer += dt;
      if (_randomChangeTimer >= GameConfig.instance.randomChangeInterval) {
        _randomChangeTimer = 0;
        _applyRandomMovement();
      }
    }

    if (_isStraightening) {
      _straighteningTimer += dt;

      final targetAngle = upperArm.body.angle;
      final targetAngularVelocity = upperArm.body.angularVelocity;

      foreArm.body.setTransform(foreArm.body.position, targetAngle);
      foreArm.body.angularVelocity = targetAngularVelocity;

      _checkHitOnce();

      if (_straighteningTimer >= GameConfig.instance.straighteningDuration) {
        stopStraightening();
      }
    }
  }

  // --- 操作用メソッド ---

  void startStraightening() {
    if (_physicsStoppedOnHit) return;

    _isStraightening = true;
    _straighteningTimer = 0;
    stopElbow();
    stopShoulder();
  }

  void stopStraightening() {
    _isStraightening = false;
    _straighteningTimer = 0;
  }

  void controlShoulder(double speed) {
    if (_isStraightening || shoulderJoint == null) return;
    shoulderJoint!.enableMotor(true);
    shoulderJoint!.motorSpeed = speed;
  }

  void stopShoulder() {
    if (shoulderJoint == null) return;
    shoulderJoint!.enableMotor(false);
  }

  void controlElbow(double speed) {
    if (_isStraightening || elbowJoint == null) return;
    elbowJoint!.enableMotor(true);
    elbowJoint!.motorSpeed = speed;
  }

  void stopElbow() {
    if (elbowJoint == null) return;
    elbowJoint!.enableMotor(false);
  }

  // --- ランダム動作モード ---

  void startRandomMode() {
    isRandomMode = true;
    _randomChangeTimer = 0;
  }

  void stopRandomMode() {
    isRandomMode = false;
    stopShoulder();
    stopElbow();
  }

  void _applyRandomMovement() {
    final sRange = GameConfig.instance.shoulderSpeedRange;
    final shoulderSpeed = (_random.nextDouble() * sRange) - sRange / 2;
    controlShoulder(shoulderSpeed);

    if (!_isStraightening) {
      final eRange = GameConfig.instance.elbowSpeedRange;
      final elbowSpeed = (_random.nextDouble() * eRange) - eRange / 2;
      controlElbow(elbowSpeed);
    }
  }
}
