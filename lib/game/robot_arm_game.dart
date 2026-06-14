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
import 'enemy_config.dart';
import 'game_config.dart';
import 'hp_bar_config.dart';

class RobotArmGame extends Forge2DGame {
  final VoidCallback? onWin;
  final VoidCallback? onLose;
  final BleService bleService;
  final GameConfig _config;
  final ArmLayoutConfig _layout;
  final EnemyConfig _enemyConfig;
  final HpBarConfig _playerHpConfig;
  final HpBarConfig _enemyHpConfig;

  /// true: アシンクロン戦の二重振り子モード / false: ユガロック戦の固定モード
  final bool enablePendulum;

  RobotArmGame({
    this.onWin,
    this.onLose,
    required this.bleService,
    required GameConfig config,
    required ArmLayoutConfig layout,
    required EnemyConfig enemyConfig,
    HpBarConfig? playerHpConfig,
    HpBarConfig? enemyHpConfig,
    this.enablePendulum = true,
  }) : _config = config,
       _layout = layout,
       _enemyConfig = enemyConfig,
       _playerHpConfig = playerHpConfig ?? HpBarConfig(),
       _enemyHpConfig = enemyHpConfig ?? HpBarConfig(),
       playerHp = ValueNotifier((playerHpConfig ?? HpBarConfig()).maxHp),
       enemyHp = ValueNotifier((enemyHpConfig ?? HpBarConfig()).maxHp),
       super(gravity: config.gravity, zoom: config.zoom);

  /// プレイヤー(shoulder)の現在HP。HPバーUIの表示に使用する。
  final ValueNotifier<double> playerHp;

  /// 敵の現在HP。HPバーUIの表示に使用する。
  final ValueNotifier<double> enemyHp;

  late ArmPart shoulder;
  late ArmPart upperArm;
  late ArmPart foreArm;

  RevoluteJoint? shoulderJoint;
  RevoluteJoint? elbowJoint;

  bool _isStraightening = false;
  double _straighteningTimer = 0;

  // 振り子動作用
  bool isRandomMode = false;
  final Random _random = Random();
  double _randomChangeTimer = 0;

  // 固定モード(ユガロック戦)用
  double _fixedShoulderAngle = 0;

  // ヒットチェック用
  final List<Enemy> enemies = [];
  bool _isCleared = false;
  bool _physicsStoppedOnHit = false;

  // 敗北判定用
  static const _kEnemyDamagePerSecond = 5.0;
  bool _isDefeated = false;
  final ValueNotifier<bool> showDefeatMessage = ValueNotifier(false);

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
        'Failed to load background image: game_background.png, error: $e',
      );
    }

    // --- 敵を配置 ---
    await _spawnEnemies();

    // --- パーツ生成 ---
    final ua = _layout.upperArm;
    upperArm = ArmPart(
      position: Vector2(ua.positionX, ua.positionY),
      size: Vector2(ua.sizeX, ua.sizeY),
      isStatic: false,
      color: Colors.blueAccent,
      imagePath: GameImage.upperArm.path,
    );
    await world.add(upperArm);

    final fa = _layout.foreArm;
    foreArm = ArmPart(
      position: Vector2(fa.positionX, fa.positionY),
      size: Vector2(fa.sizeX, fa.sizeY),
      isStatic: false,
      color: Colors.lightBlueAccent,
      imagePath: GameImage.drill.path,
      isDrill: true,
      tipRadius: _config.tipRadius,
      tipOffset: Offset(_layout.tipOffsetX, _layout.tipOffsetY),
    );
    await world.add(foreArm);

    final sh = _layout.shoulder;
    shoulder = ArmPart(
      position: Vector2(sh.positionX, sh.positionY),
      size: Vector2(sh.sizeX, sh.sizeY),
      isStatic: true,
      color: Colors.grey,
      imagePath: GameImage.upperBody.path,
      maxHp: _playerHpConfig.maxHp,
    );
    await world.add(shoulder);

    // --- ジョイント生成 ---
    final sj = _layout.shoulderJoint;
    final shoulderJointDef = RevoluteJointDef()
      ..bodyA = shoulder.body
      ..bodyB = upperArm.body
      ..collideConnected = false
      ..localAnchorA.setFrom(Vector2(sj.anchorAX, sj.anchorAY))
      ..localAnchorB.setFrom(Vector2(sj.anchorBX, sj.anchorBY))
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = _config.shoulderTorque;
    shoulderJoint = RevoluteJoint(shoulderJointDef);
    world.createJoint(shoulderJoint!);

    final ej = _layout.elbowJoint;
    final elbowJointDef = RevoluteJointDef()
      ..bodyA = upperArm.body
      ..bodyB = foreArm.body
      ..collideConnected = false
      ..localAnchorA.setFrom(Vector2(ej.anchorAX, ej.anchorAY))
      ..localAnchorB.setFrom(Vector2(ej.anchorBX, ej.anchorBY))
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = _config.elbowTorque;
    elbowJoint = RevoluteJoint(elbowJointDef);
    world.createJoint(elbowJoint!);

    if (enablePendulum) {
      startRandomMode();
    } else {
      // ユガロック戦: 肩を敵の方向へ向けて固定し、肘は少し曲げた姿勢で待機させる
      _fixedShoulderAngle = _calcShoulderAngleTowardEnemy();
      upperArm.body.setTransform(upperArm.body.position, _fixedShoulderAngle);
      foreArm.body.setTransform(
        foreArm.body.position,
        _fixedShoulderAngle + _config.elbowBentAngle,
      );
    }
  }

  /// 腕を伸ばした状態(肘が伸びきった状態)の先端が敵の方向を向くような肩関節の角度を求める
  double _calcShoulderAngleTowardEnemy() {
    final sj = _layout.shoulderJoint;
    final ej = _layout.elbowJoint;
    final shoulderPivot = shoulder.body.worldPoint(
      Vector2(sj.anchorAX, sj.anchorAY),
    );

    // 上腕・前腕がともに角度0(伸びきった状態)のとき、肩関節ピボットから見た先端方向。
    // 初期配置の各パーツ位置はジョイント制約と整合していないため、
    // ローカルアンカー/オフセットのみから幾何的に算出する。
    final straightTipDir =
        Vector2(ej.anchorAX, ej.anchorAY) -
        Vector2(ej.anchorBX, ej.anchorBY) +
        Vector2(0, _layout.armTipLocalY) -
        Vector2(sj.anchorBX, sj.anchorBY);

    final enemyPos = Vector2(
      _config.shoulderPos.x + _config.armLength + _config.enemyRadius,
      0,
    );
    final enemyDir = enemyPos - shoulderPivot;

    return atan2(enemyDir.y, enemyDir.x) -
        atan2(straightTipDir.y, straightTipDir.x);
  }

  Future<void> _spawnEnemies() async {
    final enemyPos = Vector2(
      _config.shoulderPos.x + _config.armLength + _config.enemyRadius,
      0,
    );
    final enemy = Enemy(
      position: enemyPos,
      radius: _config.enemyRadius,
      spriteScale: _enemyConfig.spriteScale,
      maxHp: _enemyHpConfig.maxHp,
      spritePath: enablePendulum
          ? GameImage.asyncron.path
          : GameImage.yugarock.path,
      splashSpritePath: enablePendulum
          ? GameImage.asyncronLose.path
          : GameImage.yugarockSplash.path,
    );
    enemies.add(enemy);
    await world.add(enemy);
  }

  /// 腕の先端のワールド座標を取得
  Vector2 get armTipPosition {
    return foreArm.body.worldPoint(Vector2(0, _layout.armTipLocalY));
  }

  /// Snap Straight押下時に1回だけヒットチェック
  void _checkHitOnce() {
    if (_isCleared) return;

    final tipPos = armTipPosition;
    for (final enemy in enemies) {
      final distance = tipPos.distanceTo(enemy.body.position);
      final hitDistance = _config.tipRadius + enemy.radius;
      if (distance < hitDistance) {
        // todo: 現状は即撃破固定。将来的にダメージ量を調整する場合は
        // 味方・敵双方の攻撃設定を持つ AttackConfig を新設してConfigから渡す。
        enemy.takeDamage(_enemyHpConfig.maxHp);
        enemyHp.value = enemy.hp;
        enemy.onHit();

        _isCleared = true;
        _physicsStoppedOnHit = true;

        _stopAllPhysics();

        unawaited(
          Future.delayed(const Duration(seconds: 3), () async {
            try {
              await bleService.sendVibration(100);
            } catch (e) {
              debugPrint('sendVibration error: $e');
            }
            onWin?.call();
          }),
        );
        FlameAudio.bgm.stop();
        FlameAudio.bgm.play(GameAudio.clear.path);

        return;
      }
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

  void _handleDefeat() {
    if (_isDefeated) return;
    _isDefeated = true;
    _stopAllPhysics();
    showDefeatMessage.value = true;

    // 敗北時、スパホルダーを構成する各パーツを-45度傾けて倒れた姿勢にする
    const tiltAngle = -pi / 4;
    shoulder.body.setTransform(
      shoulder.body.position,
      shoulder.body.angle + tiltAngle,
    );
    upperArm.body.setTransform(
      upperArm.body.position,
      upperArm.body.angle + tiltAngle,
    );
    foreArm.body.setTransform(
      foreArm.body.position,
      foreArm.body.angle + tiltAngle,
    );

    unawaited(
      Future.delayed(const Duration(seconds: 3), () {
        onLose?.call();
      }),
    );
  }

  @override
  void update(double dt) {
    if (_physicsStoppedOnHit || _isDefeated) {
      return;
    }

    super.update(dt);

    shoulder.takeDamage(_kEnemyDamagePerSecond * dt);
    playerHp.value = shoulder.hp;
    if (shoulder.hp <= 0) {
      _handleDefeat();
      return;
    }

    if (isRandomMode) {
      _randomChangeTimer += dt;
      if (_randomChangeTimer >= _config.randomChangeInterval) {
        _randomChangeTimer = 0;
        _applyRandomMovement();
      }
    }

    if (!enablePendulum) {
      // ユガロック戦: 肩を固定し、攻撃中以外は肘を曲げた姿勢に固定する
      upperArm.body.setTransform(upperArm.body.position, _fixedShoulderAngle);
      upperArm.body.angularVelocity = 0;

      if (!_isStraightening) {
        foreArm.body.setTransform(
          foreArm.body.position,
          _fixedShoulderAngle + _config.elbowBentAngle,
        );
        foreArm.body.angularVelocity = 0;
      }
    }

    if (_isStraightening) {
      _straighteningTimer += dt;

      final targetAngle = upperArm.body.angle;
      final targetAngularVelocity = upperArm.body.angularVelocity;

      foreArm.body.setTransform(foreArm.body.position, targetAngle);
      foreArm.body.angularVelocity = targetAngularVelocity;

      _checkHitOnce();

      if (_straighteningTimer >= _config.straighteningDuration) {
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
    final sRange = _config.shoulderSpeedRange;
    final shoulderSpeed = (_random.nextDouble() * sRange) - sRange / 2;
    controlShoulder(shoulderSpeed);

    if (!_isStraightening) {
      final eRange = _config.elbowSpeedRange;
      final elbowSpeed = (_random.nextDouble() * eRange) - eRange / 2;
      controlElbow(elbowSpeed);
    }
  }
}
