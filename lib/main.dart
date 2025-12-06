import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 横向き固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

// ---------------------------------------------------------
// 0. アプリ全体の画面管理
// ---------------------------------------------------------
enum AppScreen { title, countdown, game, gameClear }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppScreen _currentScreen = AppScreen.title;

  void _startCountdown() {
    setState(() {
      _currentScreen = AppScreen.countdown;
    });
  }

  void _startGame() {
    setState(() {
      _currentScreen = AppScreen.game;
    });
  }

  void _showGameClear() {
    setState(() {
      _currentScreen = AppScreen.gameClear;
    });
  }

  void _returnToTitle() {
    setState(() {
      _currentScreen = AppScreen.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_currentScreen) {
        AppScreen.title => TitleScreen(onStart: _startCountdown),
        AppScreen.countdown => CountdownScreen(onComplete: _startGame),
        AppScreen.game => GameWrapper(onGameClear: _showGameClear),
        AppScreen.gameClear => GameClearScreen(onTap: _returnToTitle),
      },
    );
  }
}

// ---------------------------------------------------------
// 0.5. タイトル画面
// ---------------------------------------------------------
class TitleScreen extends StatelessWidget {
  final VoidCallback onStart;

  const TitleScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        color: const Color(0xFF222222),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイトル
              const Text(
                'ROBOT ARM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blueAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // Tap to Start
              const Text(
                'Tap to Start',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 0.6. カウントダウン画面
// ---------------------------------------------------------
class CountdownScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const CountdownScreen({super.key, required this.onComplete});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  int _count = 3;
  bool _showGameStart = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    // 3, 2, 1 カウントダウン
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() {
        _count = i;
        _showGameStart = false;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    // 0 → ゲームスタート表示
    if (!mounted) return;
    setState(() {
      _count = 0;
      _showGameStart = true;
    });
    await Future.delayed(const Duration(seconds: 1));

    // ゲーム画面へ遷移
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF222222),
      child: Center(
        child: Text(
          _showGameStart ? 'ゲームスタート' : '$_count',
          style: TextStyle(
            color: Colors.white,
            fontSize: _showGameStart ? 48 : 120,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                blurRadius: 10,
                color: Colors.blueAccent,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 0.7. ゲームクリア画面
// ---------------------------------------------------------
class GameClearScreen extends StatelessWidget {
  final VoidCallback onTap;

  const GameClearScreen({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: const Color(0xFF222222),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GAME CLEAR!',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.green,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'Tap to Return',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. UIとゲームを重ねるためのラッパーウィジェット
// ---------------------------------------------------------
class GameWrapper extends StatefulWidget {
  final VoidCallback onGameClear;

  const GameWrapper({super.key, required this.onGameClear});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  late final RobotArmGame game;

  @override
  void initState() {
    super.initState();
    game = RobotArmGame(onGameClear: widget.onGameClear);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        // スコア表示
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<int>(
            valueListenable: game.hitCount,
            builder: (context, count, child) {
              return Text(
                'HIT: $count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black),
                  ],
                ),
              );
            },
          ),
        ),
        // --- 中央下：腕伸ばしボタンのみ表示 ---
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 強制まっすぐボタン
                const Text(
                  "Snap Straight\n(強制整列)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                ),
                const SizedBox(height: 10),
                HoldButton(
                  icon: Icons.vertical_align_center,
                  onPressed: () => game.startStraightening(),
                  onReleased: () => game.stopStraightening(),
                ),
              ],
            ),
          ),
        ),
        // --- 以下、非表示にしたボタン群 ---
        // ControlPanel (肩): game.controlShoulder(-3.0), game.controlShoulder(3.0)
        // ControlPanel (肘): game.controlElbow(-5.0), game.controlElbow(5.0)
        // ToggleButton (ランダム): game.toggleRandomMode()
      ],
    );
  }
}

// ---------------------------------------------------------
// 2. UIパーツ
// ---------------------------------------------------------
class ControlPanel extends StatelessWidget {
  final String label;
  final VoidCallback onLeftDown;
  final VoidCallback onRightDown;
  final VoidCallback onRelease;

  const ControlPanel({
    super.key,
    required this.label,
    required this.onLeftDown,
    required this.onRightDown,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)])),
        const SizedBox(height: 10),
        Row(
          children: [
            HoldButton(
                icon: Icons.rotate_left,
                onPressed: onLeftDown,
                onReleased: onRelease),
            const SizedBox(width: 10),
            HoldButton(
                icon: Icons.rotate_right,
                onPressed: onRightDown,
                onReleased: onRelease),
          ],
        ),
      ],
    );
  }
}

class HoldButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const HoldButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.onReleased,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: (_) => onReleased(),
      onTapCancel: () => onReleased(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
        child: Icon(icon, size: 32, color: Colors.redAccent.withValues(alpha: 0.8)),
      ),
    );
  }
}

class ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onToggle;

  const ToggleButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isActive
                ? Colors.greenAccent.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
        child: Icon(icon,
            size: 32,
            color: isActive
                ? Colors.white
                : Colors.redAccent.withValues(alpha: 0.8)),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. ゲームロジック
// ---------------------------------------------------------
class RobotArmGame extends Forge2DGame {
  final VoidCallback? onGameClear;

  RobotArmGame({this.onGameClear}) : super(gravity: Vector2(0, 15), zoom: 20);

  // 【変更点】updateメソッドからアクセスできるようにクラス変数にする
  late ArmPart shoulder;
  late ArmPart upperArm;
  late ArmPart foreArm;

  RevoluteJoint? shoulderJoint;
  RevoluteJoint? elbowJoint;

  bool _isStraightening = false;
  double _straighteningTimer = 0; // 整列タイマー
  static const double _straighteningDuration = 0.2; // 200ms

  // ランダム動作用
  bool isRandomMode = false;
  final Random _random = Random();
  double _randomChangeTimer = 0;
  static const double _randomChangeInterval = 0.5; // 0.5秒ごとに方向変更

  // ヒットチェック用
  final ValueNotifier<int> hitCount = ValueNotifier<int>(0);
  final List<Enemy> enemies = [];

  // アームの届く範囲
  // 上腕ジョイント間: 7, 前腕ジョイント〜先端: 6.5 → 合計13.5
  static const double armLength = 13.5;
  static final Vector2 shoulderPos = Vector2(-10, -7); // 左側に配置
  static const double tipRadius = 0.8; // 先端の当たり判定半径
  static const double enemyRadius = 3.0; // 敵の半径（画面内に収まるサイズ）

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    // --- パーツ生成 ---
    // アームを左側に配置
    shoulder = ArmPart(
        position: Vector2(-10, -8),
        size: Vector2(4, 2),
        isStatic: true,
        color: Colors.grey);
    await world.add(shoulder);

    upperArm = ArmPart(
        position: Vector2(-10, -2),
        size: Vector2(1.5, 8),
        isStatic: false,
        color: Colors.blueAccent);
    await world.add(upperArm);

    foreArm = ArmPart(
        position: Vector2(-10, 7),
        size: Vector2(1.2, 7),
        isStatic: false,
        color: Colors.lightBlueAccent);
    await world.add(foreArm);

    // --- ジョイント生成 ---
    final shoulderJointDef = RevoluteJointDef()
      ..bodyA = shoulder.body
      ..bodyB = upperArm.body
      ..collideConnected = false
      ..localAnchorA.setValues(0, 1)
      ..localAnchorB.setValues(0, -3.5)
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = 2000.0;
    shoulderJoint = RevoluteJoint(shoulderJointDef);
    world.createJoint(shoulderJoint!);

    final elbowJointDef = RevoluteJointDef()
      ..bodyA = upperArm.body
      ..bodyB = foreArm.body
      ..collideConnected = false
      ..localAnchorA.setValues(0, 3.5)
      ..localAnchorB.setValues(0, -3.0)
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = 5000.0;
    elbowJoint = RevoluteJoint(elbowJointDef);
    world.createJoint(elbowJoint!);

    // --- 敵を配置 ---
    await _spawnEnemies();

    // --- 常にランダムモードを有効化 ---
    startRandomMode();
  }

  Future<void> _spawnEnemies() async {
    // 敵は1体、右側に配置（アームの最大到達距離ジャストの位置）
    // 敵の端がちょうど腕の先端位置になるように配置
    // tipPosition = shoulderPos.x + armLength
    // enemyEdge = enemyCenter - enemyRadius = tipPosition
    // よって enemyCenter = shoulderPos.x + armLength + enemyRadius
    final enemyPos = Vector2(
      shoulderPos.x + armLength + enemyRadius, // 敵の端がジャスト腕の先端
      shoulderPos.y, // 肩と同じ高さ
    );
    final enemy = Enemy(position: enemyPos, radius: enemyRadius);
    enemies.add(enemy);
    await world.add(enemy);
  }

  /// 腕の先端のワールド座標を取得
  Vector2 get armTipPosition {
    return foreArm.body.worldPoint(Vector2(0, 3.5));
  }

  /// Snap Straight押下時に1回だけヒットチェック
  void _checkHitOnce() {
    final tipPos = armTipPosition;
    for (final enemy in enemies) {
      final distance = tipPos.distanceTo(enemy.body.position);
      final hitDistance = tipRadius + enemy.radius;
      if (distance < hitDistance) {
        hitCount.value++;
        // ヒットしたらゲームクリア画面へ遷移
        onGameClear?.call();
        return;
      }
    }
  }

  // --- 【重要】強制更新ロジック ---
  @override
  void update(double dt) {
    super.update(dt);

    // ランダム動作モード
    if (isRandomMode) {
      _randomChangeTimer += dt;
      if (_randomChangeTimer >= _randomChangeInterval) {
        _randomChangeTimer = 0;
        _applyRandomMovement();
      }
    }

    if (_isStraightening) {
      // タイマーを進める
      _straighteningTimer += dt;

      // 1. 上腕の現在の角度を取得
      final targetAngle = upperArm.body.angle;

      // 2. 上腕の回転速度を取得
      final targetAngularVelocity = upperArm.body.angularVelocity;

      // 3. 物理演算を無視して、前腕の状態を強制上書き(setTransform)
      foreArm.body.setTransform(foreArm.body.position, targetAngle);

      // 4. 慣性も同期させる
      foreArm.body.angularVelocity = targetAngularVelocity;

      // 5. 300msの間、毎フレームヒットチェック
      _checkHitOnce();

      // 6. 300ms経過したら自動で解除
      if (_straighteningTimer >= _straighteningDuration) {
        stopStraightening();
      }
    }
  }

  // --- 操作用メソッド ---

  void startStraightening() {
    _isStraightening = true;
    _straighteningTimer = 0; // タイマーリセット
    // モーターが邪魔しないようにOFFにする
    stopElbow();
    stopShoulder(); // 肩も固定
  }

  void stopStraightening() {
    _isStraightening = false;
    _straighteningTimer = 0;
  }

  void controlShoulder(double speed) {
    // 整列中は肩も固定
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

  void toggleRandomMode() {
    if (isRandomMode) {
      stopRandomMode();
    } else {
      startRandomMode();
    }
  }

  void _applyRandomMovement() {
    // 肩：-4.0 〜 4.0 のランダムな速度
    final shoulderSpeed = (_random.nextDouble() * 8.0) - 4.0;
    controlShoulder(shoulderSpeed);

    // 肘：-6.0 〜 6.0 のランダムな速度（整列中は動かさない）
    if (!_isStraightening) {
      final elbowSpeed = (_random.nextDouble() * 12.0) - 6.0;
      controlElbow(elbowSpeed);
    }
  }
}

// ---------------------------------------------------------
// 4. 腕パーツ定義 (変更なし)
// ---------------------------------------------------------
class ArmPart extends BodyComponent {
  final Vector2 _pos;
  final Vector2 _size;
  final bool _isStatic;
  final Color _color;

  ArmPart({
    required Vector2 position,
    required Vector2 size,
    required bool isStatic,
    required Color color,
  })  : _pos = position,
        _size = size,
        _isStatic = isStatic,
        _color = color;

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
    final paint = Paint()..color = _color;
    final rect = Rect.fromCenter(
        center: Offset.zero, width: _size.x, height: _size.y);
    canvas.drawRect(rect, paint);
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;
    canvas.drawRect(rect, border);
    final jointPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(0, -_size.y / 2 + 0.5), 0.4, jointPaint);
    canvas.drawCircle(Offset(0, _size.y / 2 - 0.5), 0.4, jointPaint);
  }
}

// ---------------------------------------------------------
// 5. 敵クラス
// ---------------------------------------------------------
class Enemy extends BodyComponent {
  final Vector2 _initialPosition;
  final double _radius;

  Enemy({
    required Vector2 position,
    required double radius,
  })  : _initialPosition = position.clone(),
        _radius = radius;

  double get radius => _radius;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = _radius;
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.5
      ..density = 1.0
      ..friction = 0.3;
    final bodyDef = BodyDef()
      ..userData = this
      ..position = _initialPosition
      ..type = BodyType.static;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  void respawn() {
    // 同じ位置に戻す（敵は1体固定のため）
    body.setTransform(_initialPosition, 0);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(Offset.zero, _radius, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;
    canvas.drawCircle(Offset.zero, _radius, border);
  }
}