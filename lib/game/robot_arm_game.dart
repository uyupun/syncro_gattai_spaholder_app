import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../interfaces/ble_service.dart';
import '../models/accel_data.dart';
import '../resources/game_audio.dart';
import '../resources/game_image.dart';
import 'actions_config.dart';
import 'arm_layout_config.dart';
import 'combat/enemy_action_scheduler.dart';
import 'combat/player_action_detector.dart';
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
  final ActionsConfig _actionsConfig;

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
    ActionsConfig? actionsConfig,
    this.enablePendulum = true,
  }) : _config = config,
       _layout = layout,
       _enemyConfig = enemyConfig,
       _playerHpConfig = playerHpConfig ?? HpBarConfig(),
       _enemyHpConfig = enemyHpConfig ?? HpBarConfig(),
       _actionsConfig = actionsConfig ?? ActionsConfig(),
       playerHp = ValueNotifier((playerHpConfig ?? HpBarConfig()).maxHp),
       enemyHp = ValueNotifier((enemyHpConfig ?? HpBarConfig()).maxHp),
       _enemyActionScheduler = EnemyActionScheduler(
         intervalSecondsOptions: enablePendulum
             ? EnemyActionScheduler.fastIntervalSecondsOptions
             : EnemyActionScheduler.intervalSecondsOptions,
       ),
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

  /// シンクロガードの効果時間(秒)
  static const double _guardDuration = 2.0;

  /// シンクロガードの残り効果時間(秒)。0より大きい間はガード状態として扱う。
  double _guardTimer = 0;

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
  bool _isDefeated = false;
  final ValueNotifier<bool> showDefeatMessage = ValueNotifier(false);

  // 背景画像
  Sprite? _backgroundSprite;

  // --- ユガロック戦: 実戦闘ロジック用 ---
  final PlayerActionDetector _playerActionDetector = PlayerActionDetector();
  final EnemyActionScheduler _enemyActionScheduler;
  final Map<String, AccelData> _accelData = {};
  List<String> _connectedIds = [];
  StreamSubscription<AccelData>? _accelDataSub;
  StreamSubscription<List<String>>? _connectedDevicesSub;

  /// 直近に発動した技名(スパホルダー/ユガロック)。1秒間表示後nullに戻る。
  final ValueNotifier<String?> playerActionLabel = ValueNotifier(null);
  final ValueNotifier<String?> enemyActionLabel = ValueNotifier(null);
  int _playerLabelGeneration = 0;
  int _enemyLabelGeneration = 0;

  /// スパホルダーの現在のシンクロチャージレベル(0〜maxChargeLevel)
  final ValueNotifier<int> playerChargeLevel = ValueNotifier(0);

  /// シンクロガード中(残り効果時間 > 0)かどうか
  final ValueNotifier<bool> playerGuardActive = ValueNotifier(false);

  /// シンクロアタック発動中、ドリルが敵に当たった時点で与えるダメージ量
  double? _pendingAttackDamage;

  /// アシンクロン戦開始時のアシンクペンデュラム発動済みフラグ(初回のみ発動)
  bool _asyncPendulumTriggered = false;

  /// 画面中央に表示するメッセージ。2秒間表示後nullに戻る。
  final ValueNotifier<String?> centerMessage = ValueNotifier(null);

  @override
  Color backgroundColor() => const Color(0xFFFFFFFF);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    // --- BLE加速度データの購読(ユガロック戦の実戦闘ロジックで使用) ---
    _connectedIds = bleService.connectedDevices;
    _connectedDevicesSub = bleService.connectedDevicesStream.listen((ids) {
      _connectedIds = ids;
    });
    _accelDataSub = bleService.accelDataStream.listen((data) {
      _accelData[data.deviceId] = data;
    });

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

  @override
  void onRemove() {
    _accelDataSub?.cancel();
    _connectedDevicesSub?.cancel();
    super.onRemove();
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

  /// シンクロアタックで伸ばしたドリルが敵に当たった時点でダメージを与える
  void _checkSynchroAttackHit() {
    if (_isCleared || _pendingAttackDamage == null || enemies.isEmpty) return;

    final enemy = enemies.first;
    final tipPos = armTipPosition;
    final distance = tipPos.distanceTo(enemy.body.position);
    final hitDistance = _config.tipRadius + enemy.radius;
    if (distance < hitDistance) {
      final damage = _pendingAttackDamage!;
      _pendingAttackDamage = null;
      enemy.takeDamage(damage);
      enemyHp.value = enemy.hp;
      debugPrint(
        '[Battle] ${_actionsConfig.synchroAttack.nameJa}がヒット! '
        'damage=$damage, enemyHp=${enemy.hp}',
      );
      if (enemy.hp <= 0) {
        _triggerWin(enemy);
      }
    }
  }

  /// 敵を撃破した際の処理(物理停止・成功演出・振動・onWin呼び出し)
  void _triggerWin(Enemy enemy) {
    if (_isCleared) return;
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
  }

  /// ユガロック戦/アシンクロン戦共通の実戦闘ロジック。
  /// BLE加速度センサーの入力からスパホルダーのシンクロ技を発動し、
  /// ランダムな間隔(5〜10秒)で敵の技を発動する。
  /// アシンクロン戦では、開始直後に一度だけアシンクペンデュラムを発動する。
  void _updateBattle(double dt) {
    if (enemies.isEmpty) return;

    if (enablePendulum && !_asyncPendulumTriggered) {
      _asyncPendulumTriggered = true;
      debugPrint(
        '[Battle] アシンクロン: ${_actionsConfig.asyncPendulum.nameJa} - 発動',
      );
      _showCenterMessage('アシンクロンの技の影響を受けている...！');
    }

    if (_guardTimer > 0) {
      _guardTimer = (_guardTimer - dt).clamp(0, _guardDuration);
    }

    final isGuardingNow = _guardTimer > 0;
    final playerResult = _playerActionDetector.detect(
      _accelData,
      _connectedIds,
      isGuarding: isGuardingNow,
    );
    playerChargeLevel.value = _playerActionDetector.chargeLevel;
    switch (playerResult.type) {
      case PlayerActionType.attack:
        if (isGuardingNow) break;
        final multiplier =
            PlayerActionDetector.chargeMultipliers[playerResult.chargeLevel];
        final damage = _actionsConfig.synchroAttack.power * multiplier;
        _pendingAttackDamage = damage;
        debugPrint(
          '[Battle] スパホルダー: ${_actionsConfig.synchroAttack.nameJa} '
          '(chargeLevel=${playerResult.chargeLevel}, '
          'multiplier=$multiplier, damage=$damage) - ドリル始動',
        );
        _showPlayerActionLabel(_actionsConfig.synchroAttack.nameJa);
        startStraightening();
      case PlayerActionType.guard:
        _guardTimer = _guardDuration;
        debugPrint('[Battle] スパホルダー: ${_actionsConfig.synchroGuard.nameJa}');
        _showPlayerActionLabel(_actionsConfig.synchroGuard.nameJa);
      case PlayerActionType.charge:
        if (isGuardingNow) break;
        debugPrint(
          '[Battle] スパホルダー: ${_actionsConfig.synchroCharge.nameJa} '
          '(chargeLevel=${playerResult.chargeLevel})',
        );
        _showPlayerActionLabel(_actionsConfig.synchroCharge.nameJa);
      case PlayerActionType.none:
        break;
    }
    playerGuardActive.value = _guardTimer > 0;

    if (_enemyActionScheduler.update(dt)) {
      final enemyActions = enablePendulum
          ? _actionsConfig.asyncronActions
          : _actionsConfig.yugarockActions;
      final action = enemyActions[_random.nextInt(enemyActions.length)];
      final isGuarding = _guardTimer > 0;
      var damage = action.power.toDouble();
      if (isGuarding) {
        damage = (damage - _actionsConfig.synchroGuard.power).clamp(
          0,
          double.infinity,
        );
      }
      shoulder.takeDamage(damage);
      playerHp.value = shoulder.hp;
      if (damage > 0) {
        unawaited(
          bleService.sendVibration(50).catchError((Object e) {
            debugPrint('sendVibration error: $e');
          }),
        );
      }
      debugPrint(
        '[Battle] ${enablePendulum ? "アシンクロン" : "ユガロック"}: ${action.nameJa} '
        '(damage=$damage, guarded=$isGuarding, '
        'playerHp=${shoulder.hp})',
      );
      _showEnemyActionLabel(action.nameJa);
    }
  }

  /// スパホルダーの技名を1秒間表示する
  void _showPlayerActionLabel(String text) {
    playerActionLabel.value = text;
    final generation = ++_playerLabelGeneration;
    unawaited(
      Future.delayed(const Duration(seconds: 1), () {
        if (_playerLabelGeneration == generation) {
          playerActionLabel.value = null;
        }
      }),
    );
  }

  /// ユガロックの技名を1秒間表示する
  void _showEnemyActionLabel(String text) {
    enemyActionLabel.value = text;
    final generation = ++_enemyLabelGeneration;
    unawaited(
      Future.delayed(const Duration(seconds: 1), () {
        if (_enemyLabelGeneration == generation) {
          enemyActionLabel.value = null;
        }
      }),
    );
  }

  /// 画面中央にメッセージを2秒間表示する
  void _showCenterMessage(String text) {
    centerMessage.value = text;
    unawaited(
      Future.delayed(const Duration(seconds: 2), () {
        centerMessage.value = null;
      }),
    );
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

    _updateBattle(dt);

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

      _checkSynchroAttackHit();

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
    _pendingAttackDamage = null;
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
