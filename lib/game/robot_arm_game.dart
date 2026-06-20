import 'dart:async';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../interfaces/ble_service.dart';
import '../models/accel_data.dart';
import '../resources/game_image.dart';
import '../resources/game_se.dart';
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

  final String backgroundImagePath;

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
    this.backgroundImagePath = 'assets/bg/yugarock-battle.png',
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

  /// シンクロチャージ発動後の技ロック時間(秒)
  static const double _chargeLockDuration = 0.5;

  /// シンクロアタック発動後のチャージレベル別ロック時間(秒)
  static const List<double> _attackLockDurations = [
    1.0,
    1.1,
    1.2,
    1.5,
    1.75,
    2.0,
  ];

  /// シンクロチャージ発動後の技ロック残り時間(秒)
  double _chargeActiveTimer = 0;

  /// シンクロアタック発動後の技ロック残り時間(秒)
  double _attackActiveTimer = 0;

  /// シンクロガードの効果時間(秒)
  static const double _guardDuration = 2.0;

  /// シンクロガードの残り効果時間(秒)。0より大きい間はガード状態として扱う。
  double _guardTimer = 0;

  // 振り子動作用
  bool isRandomMode = false;
  final Random _random = Random();
  double _randomChangeTimer = 0;

  // ユガロック戦: arm1の基準角度
  double _fixedShoulderAngle = 0;

  // ユガロック戦: arm1の揺動タイマー
  double _yugarockOscillationTime = 0.0;

  static const double _yugarockOscMinDeg = -50.0;
  static const double _yugarockOscMaxDeg = 20.0;
  static const double _yugarockOscPeriodSec = 4.0;

  // ランジアニメーション(スパホルダー)
  double _lungeXOffset = 0.0;
  double _prevLungeXOffset = 0.0;
  double _lungeTimer = 0.0;
  double _lungeSign = 0.0;
  late double _shoulderBasePosX;
  late double _shoulderBasePosY;
  static const double _lungeDuration = 0.2;
  static const double _lungeDistance = 3.0;

  // ランジアニメーション(敵)
  double _enemyLungeXOffset = 0.0;
  double _prevEnemyLungeXOffset = 0.0;
  double _enemyLungeTimer = 0.0;
  double _enemyLungeDistance = 0.0;
  late double _enemyBasePosX;
  late double _enemyBasePosY;
  static const double _enemyLungeDuration = 0.2;

  // ボブアニメーション(スパホルダー)
  double _playerBobTime = 0.0;
  double _playerBobYOffset = 0.0;
  double _prevPlayerBobYOffset = 0.0;
  static const double _playerBobAmplitude = 0.2;
  static const double _playerBobPeriodSec = 2.0;

  // ボブアニメーション(敵)
  double _enemyBobTime = 0.0;
  double _enemyBobYOffset = 0.0;
  double _prevEnemyBobYOffset = 0.0;
  double _enemyActingTimer = 0.0;
  static const double _enemyBobAmplitude = 0.2;
  static const double _enemyBobPeriodSec = 2.5;

  // ヒットチェック用
  final List<Enemy> enemies = [];
  bool _isCleared = false;
  bool _physicsStoppedOnHit = false;

  // 敗北判定用
  bool _isDefeated = false;
  final ValueNotifier<bool> showDefeatMessage = ValueNotifier(false);

  // HP低下SE再生済みフラグ(25%以下で1回だけ鳴らす)
  bool _hpLowPlayed = false;

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
  final ValueNotifier<String?> asyncPendulumLabel = ValueNotifier(null);
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
      final filename = backgroundImagePath.split('/').last;
      final bgImages = Images(prefix: 'assets/bg/');
      _backgroundSprite = await Sprite.load(filename, images: bgImages);
    } catch (e) {
      debugPrint(
        'Failed to load background image: $backgroundImagePath, error: $e',
      );
    }

    // --- 敵を配置 ---
    await _spawnEnemies();

    // --- パーツ生成 ---
    final imageRenderSize = Vector2(
      _layout.imageRenderWidth,
      _layout.imageRenderHeight,
    );

    final ua = _layout.upperArm;
    upperArm = ArmPart(
      position: Vector2(ua.positionX, ua.positionY),
      size: Vector2(ua.sizeX, ua.sizeY),
      isStatic: false,
      color: Colors.blueAccent,
      imagePath: GameImage.upperArm.path,
      imageAnchor: ua.imageAnchorX != null && ua.imageAnchorY != null
          ? Vector2(ua.imageAnchorX!, ua.imageAnchorY!)
          : null,
      imageRenderSize: imageRenderSize,
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
      imageAnchor: fa.imageAnchorX != null && fa.imageAnchorY != null
          ? Vector2(fa.imageAnchorX!, fa.imageAnchorY!)
          : null,
      imageRenderSize: imageRenderSize,
    );
    await world.add(foreArm);

    final sh = _layout.shoulder;
    shoulder = ArmPart(
      position: Vector2(sh.positionX, sh.positionY),
      size: Vector2(sh.sizeX, sh.sizeY),
      isStatic: true,
      color: Colors.grey,
      imagePath: GameImage.upperBody.path,
      imageAnchor: sh.imageAnchorX != null && sh.imageAnchorY != null
          ? Vector2(sh.imageAnchorX!, sh.imageAnchorY!)
          : null,
      imageRenderSize: imageRenderSize,
      maxHp: _playerHpConfig.maxHp,
    );
    await world.add(shoulder);
    _shoulderBasePosX = sh.positionX;
    _shoulderBasePosY = sh.positionY;

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
      // ユガロック戦: 基準角を計算し、最大オフセット位置(+30度)から揺動開始
      _fixedShoulderAngle =
          _calcShoulderAngleTowardEnemy() +
          _config.yugarockArmAngleOffsetDeg * pi / 180;
      final startAngle = _fixedShoulderAngle + _yugarockOscMaxDeg * pi / 180;
      upperArm.body.setTransform(upperArm.body.position, startAngle);
      foreArm.body.setTransform(
        foreArm.body.position,
        startAngle + _config.elbowBentAngle,
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
        Vector2(_layout.tipOffsetX, _layout.tipOffsetY) -
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
      spriteScale: enablePendulum
          ? _enemyConfig.asyncronSpriteScale
          : _enemyConfig.yugarockSpriteScale,
      actionSpriteScale: enablePendulum
          ? null
          : _enemyConfig.asyncronSpriteScale,
      maxHp: _enemyHpConfig.maxHp,
      spritePath: enablePendulum
          ? GameImage.asyncron.path
          : GameImage.yugarock.path,
      actionSpritePaths: enablePendulum
          ? [GameImage.asyncronStream.path, GameImage.asyncronVacuum.path]
          : [GameImage.yugarockRolling.path, GameImage.yugarockFillIn.path],
    );
    enemies.add(enemy);
    await world.add(enemy);
    _enemyBasePosX = enemyPos.x;
    _enemyBasePosY = enemyPos.y;
  }

  /// 腕の先端のワールド座標を取得
  Vector2 get armTipPosition {
    return foreArm.body.worldPoint(
      Vector2(_layout.tipOffsetX, _layout.tipOffsetY),
    );
  }

  void debugAttack() {
    final enemy = enemies.first;
    final damage = 20.0;
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
      _startEnemyLunge(0.5);
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

    // 敵を45度傾けて倒れた姿勢にする(スパホルダーとは逆向き)
    enemy.body.setTransform(enemy.body.position, pi / 4);

    unawaited(
      Future.delayed(const Duration(seconds: 3), () {
        onWin?.call();
      }),
    );
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
      asyncPendulumLabel.value = _actionsConfig.asyncPendulum.nameJa;
      unawaited(
        Future.delayed(const Duration(milliseconds: 2500), () {
          asyncPendulumLabel.value = null;
        }),
      );
      _showCenterMessage(
        'アシンクロンの技の\n影響を受けている...！',
        duration: const Duration(milliseconds: 2500),
      );
      unawaited(
        bleService.sendVibration(25).catchError((Object e) {
          debugPrint('sendVibration error: $e');
        }),
      );
      _startLunge(-1.0);
    }

    if (_guardTimer > 0) {
      _guardTimer = (_guardTimer - dt).clamp(0, _guardDuration);
    }
    if (_chargeActiveTimer > 0) {
      _chargeActiveTimer = (_chargeActiveTimer - dt).clamp(
        0,
        _chargeLockDuration,
      );
    }
    if (_attackActiveTimer > 0) {
      _attackActiveTimer = (_attackActiveTimer - dt).clamp(
        0,
        _attackLockDurations.last,
      );
    }

    final isGuardingNow = _guardTimer > 0;
    final isActionLocked =
        _isStraightening || _chargeActiveTimer > 0 || _attackActiveTimer > 0;
    final playerResult = _playerActionDetector.detect(
      _accelData,
      _connectedIds,
      isGuarding: isGuardingNow,
      isActionLocked: isActionLocked,
    );
    playerChargeLevel.value = _playerActionDetector.chargeLevel;
    switch (playerResult.type) {
      case PlayerActionType.attack:
        final chargeLevel = playerResult.chargeLevel;
        final multiplier = PlayerActionDetector.chargeMultipliers[chargeLevel];
        final damage = _actionsConfig.synchroAttack.power * multiplier;
        _pendingAttackDamage = damage;
        _attackActiveTimer = _attackLockDurations[chargeLevel];
        debugPrint(
          '[Battle] スパホルダー: ${_actionsConfig.synchroAttack.nameJa} '
          '(chargeLevel=$chargeLevel, '
          'multiplier=$multiplier, damage=$damage) - ドリル始動',
        );
        GameSe.syncroAttack.play();
        _startLunge(1.0);
        _showPlayerActionLabel(
          _actionsConfig.synchroAttack.nameJa,
          duration: Duration(
            milliseconds: (_attackLockDurations[chargeLevel] * 1000).toInt(),
          ),
        );
        startStraightening();
      case PlayerActionType.guard:
        _guardTimer = _guardDuration;
        debugPrint('[Battle] スパホルダー: ${_actionsConfig.synchroGuard.nameJa}');
        GameSe.syncroGuard.play();
        _showPlayerActionLabel(
          _actionsConfig.synchroGuard.nameJa,
          duration: Duration(milliseconds: (_guardDuration * 1000).toInt()),
        );
      case PlayerActionType.charge:
        _chargeActiveTimer = _chargeLockDuration;
        debugPrint(
          '[Battle] スパホルダー: ${_actionsConfig.synchroCharge.nameJa} '
          '(chargeLevel=${playerResult.chargeLevel})',
        );
        GameSe.syncroCharge.play();
        _showPlayerActionLabel(
          _actionsConfig.synchroCharge.nameJa,
          duration: Duration(
            milliseconds: (_chargeLockDuration * 1000).toInt(),
          ),
        );
      case PlayerActionType.none:
        break;
    }
    playerGuardActive.value = _guardTimer > 0;

    if (_enemyActionScheduler.update(dt)) {
      _enemyActingTimer = 2.0;
      final enemyActions = enablePendulum
          ? _actionsConfig.asyncronActions
          : _actionsConfig.yugarockActions;
      final actionIdx = _random.nextInt(enemyActions.length);
      final action = enemyActions[actionIdx];
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
      _startLunge(-1.0);
      if (!_hpLowPlayed && playerHp.value <= _playerHpConfig.maxHp * 0.25) {
        _hpLowPlayed = true;
        GameSe.hpLow.play();
      }
      if (damage > 0) {
        unawaited(
          bleService.sendVibration((damage * 2).toInt()).catchError((Object e) {
            debugPrint('sendVibration error: $e');
          }),
        );
      }
      debugPrint(
        '[Battle] ${enablePendulum ? "アシンクロン" : "ユガロック"}: ${action.nameJa} '
        '(damage=$damage, guarded=$isGuarding, '
        'playerHp=${shoulder.hp})',
      );
      final enemySes = enablePendulum
          ? [GameSe.asyncStream, GameSe.asyncVacuum]
          : [GameSe.yugarockRoll, GameSe.yugarockFillIn];
      enemySes[actionIdx].play();
      if (enemies.isNotEmpty) {
        final e = enemies.first;
        e.showActionSprite(actionIdx);
        unawaited(
          Future.delayed(const Duration(seconds: 2), e.clearActionSprite),
        );
      }
      _showEnemyActionLabel(action.nameJa);
    }
  }

  /// スパホルダーの技名を表示する。durationを省略した場合は1秒間表示する。
  void _showPlayerActionLabel(
    String text, {
    Duration duration = const Duration(seconds: 1),
  }) {
    playerActionLabel.value = text;
    final generation = ++_playerLabelGeneration;
    unawaited(
      Future.delayed(duration, () {
        if (_playerLabelGeneration == generation) {
          playerActionLabel.value = null;
        }
      }),
    );
  }

  /// 敵の技名を2秒間表示する
  void _showEnemyActionLabel(String text) {
    enemyActionLabel.value = text;
    final generation = ++_enemyLabelGeneration;
    unawaited(
      Future.delayed(const Duration(seconds: 2), () {
        if (_enemyLabelGeneration == generation) {
          enemyActionLabel.value = null;
        }
      }),
    );
  }

  void _showCenterMessage(
    String text, {
    Duration duration = const Duration(seconds: 2),
  }) {
    centerMessage.value = text;
    unawaited(
      Future.delayed(duration, () {
        centerMessage.value = null;
      }),
    );
  }

  /// 物理演算を完全に停止
  void _startLunge(double sign) {
    _lungeSign = sign;
    _lungeTimer = _lungeDuration;
  }

  void _updateLunge(double dt) {
    if (_lungeTimer > 0) {
      _lungeTimer = (_lungeTimer - dt).clamp(0.0, _lungeDuration);
      final progress = _lungeTimer / _lungeDuration;
      _lungeXOffset = _lungeSign * _lungeDistance * sin(progress * pi);
    } else {
      _lungeXOffset = 0.0;
    }

    final isActing =
        _isStraightening || _chargeActiveTimer > 0 || _attackActiveTimer > 0;
    if (!isActing) {
      _playerBobTime += dt;
      _playerBobYOffset =
          _playerBobAmplitude *
          sin(2 * pi / _playerBobPeriodSec * _playerBobTime);
    }

    final xDelta = _lungeXOffset - _prevLungeXOffset;
    final yDelta = _playerBobYOffset - _prevPlayerBobYOffset;
    if (xDelta != 0.0 || yDelta != 0.0) {
      shoulder.body.setTransform(
        Vector2(
          _shoulderBasePosX + _lungeXOffset,
          _shoulderBasePosY + _playerBobYOffset,
        ),
        shoulder.body.angle,
      );
      final moveVec = Vector2(xDelta, yDelta);
      upperArm.body.setTransform(
        upperArm.body.position + moveVec,
        upperArm.body.angle,
      );
      foreArm.body.setTransform(
        foreArm.body.position + moveVec,
        foreArm.body.angle,
      );
    }
    _prevLungeXOffset = _lungeXOffset;
    _prevPlayerBobYOffset = _playerBobYOffset;
  }

  void _startEnemyLunge(double distance) {
    _enemyLungeDistance = distance;
    _enemyLungeTimer = _enemyLungeDuration;
  }

  void _updateEnemyLunge(double dt) {
    if (_enemyLungeTimer > 0) {
      _enemyLungeTimer = (_enemyLungeTimer - dt).clamp(
        0.0,
        _enemyLungeDuration,
      );
      final progress = _enemyLungeTimer / _enemyLungeDuration;
      _enemyLungeXOffset = _enemyLungeDistance * sin(progress * pi);
    } else {
      _enemyLungeXOffset = 0.0;
    }

    if (_enemyActingTimer > 0) {
      _enemyActingTimer = (_enemyActingTimer - dt).clamp(0.0, 2.0);
    } else {
      _enemyBobTime += dt;
      _enemyBobYOffset =
          _enemyBobAmplitude * sin(2 * pi / _enemyBobPeriodSec * _enemyBobTime);
    }

    final xDelta = _enemyLungeXOffset - _prevEnemyLungeXOffset;
    final yDelta = _enemyBobYOffset - _prevEnemyBobYOffset;
    if ((xDelta != 0.0 || yDelta != 0.0) && enemies.isNotEmpty) {
      enemies.first.body.setTransform(
        Vector2(
          _enemyBasePosX + _enemyLungeXOffset,
          _enemyBasePosY + _enemyBobYOffset,
        ),
        enemies.first.body.angle,
      );
    }
    _prevEnemyLungeXOffset = _enemyLungeXOffset;
    _prevEnemyBobYOffset = _enemyBobYOffset;
  }

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

    // 勝利と同じ3秒静止後にメッセージを表示し、さらに2秒後に遷移する
    unawaited(
      Future.delayed(const Duration(seconds: 3), () {
        showDefeatMessage.value = true;
        unawaited(
          Future.delayed(const Duration(seconds: 2), () {
            onLose?.call();
          }),
        );
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

    if (isRandomMode && _attackActiveTimer <= 0) {
      _randomChangeTimer += dt;
      if (_randomChangeTimer >= _config.randomChangeInterval) {
        _randomChangeTimer = 0;
        _applyRandomMovement();
      }
    }

    _updateLunge(dt);
    _updateEnemyLunge(dt);

    if (!enablePendulum) {
      // ユガロック戦: arm1をコサイン揺動させる。攻撃中は時間を進めず角度を固定
      if (!_isStraightening) {
        _yugarockOscillationTime += dt;
      }
      const oscCenter = (_yugarockOscMinDeg + _yugarockOscMaxDeg) / 2.0; // -5.0
      const oscAmplitude =
          (_yugarockOscMaxDeg - _yugarockOscMinDeg) / 2.0; // 40.0
      final omega = 2 * pi / _yugarockOscPeriodSec;
      final offsetDeg =
          oscCenter + oscAmplitude * cos(omega * _yugarockOscillationTime);
      final currentShoulderAngle = _fixedShoulderAngle + offsetDeg * pi / 180;

      upperArm.body.setTransform(upperArm.body.position, currentShoulderAngle);
      upperArm.body.angularVelocity = 0;

      if (!_isStraightening) {
        foreArm.body.setTransform(
          foreArm.body.position,
          currentShoulderAngle + _config.elbowBentAngle,
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
