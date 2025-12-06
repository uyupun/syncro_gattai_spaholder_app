import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: GameWrapper(),
    ),
  ));
}

// ---------------------------------------------------------
// 1. UIとゲームを重ねるためのラッパーウィジェット
// ---------------------------------------------------------
class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  final RobotArmGame game = RobotArmGame();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        // スコア表示
        Positioned(
          top: 50,
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
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // --- 左：肩の操作 ---
              ControlPanel(
                label: "Shoulder (肩)",
                onLeftDown: () => game.controlShoulder(-3.0),
                onRightDown: () => game.controlShoulder(3.0),
                onRelease: () => game.stopShoulder(),
              ),

              // --- 中央：強制まっすぐボタン ---
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    icon: Icons.vertical_align_center, // アイコン変更
                    onPressed: () => game.startStraightening(),
                    onReleased: () => game.stopStraightening(),
                  ),
                ],
              ),

              // --- 右：肘の操作 ---
              ControlPanel(
                label: "Elbow (肘)",
                onLeftDown: () => game.controlElbow(-5.0),
                onRightDown: () => game.controlElbow(5.0),
                onRelease: () => game.stopElbow(),
              ),
            ],
          ),
        ),
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

// ---------------------------------------------------------
// 3. ゲームロジック
// ---------------------------------------------------------
class RobotArmGame extends Forge2DGame {
  RobotArmGame() : super(gravity: Vector2(0, 15), zoom: 20);

  // 【変更点】updateメソッドからアクセスできるようにクラス変数にする
  late ArmPart shoulder;
  late ArmPart upperArm;
  late ArmPart foreArm;

  RevoluteJoint? shoulderJoint;
  RevoluteJoint? elbowJoint;

  bool _isStraightening = false;

  // ヒットカウント
  final ValueNotifier<int> hitCount = ValueNotifier<int>(0);

  // 敵リスト
  final List<Enemy> enemies = [];

  // ヒットした敵のキュー（物理エンジンロック中は処理を遅延）
  final List<Enemy> _hitQueue = [];

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    // --- パーツ生成 ---
    // 変数宣言(final)を削除し、クラス変数への代入に変更
    shoulder = ArmPart(
        position: Vector2(0, -8),
        size: Vector2(4, 2),
        isStatic: true,
        color: Colors.grey);
    await world.add(shoulder);

    upperArm = ArmPart(
        position: Vector2(0, -2),
        size: Vector2(1.5, 8),
        isStatic: false,
        color: Colors.blueAccent);
    await world.add(upperArm);

    foreArm = ArmPart(
        position: Vector2(0, 7),
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
  }

  // アームの届く範囲の定数
  static const double armReachMin = 6.0;  // 最小到達距離
  static const double armReachMax = 13.0; // 最大到達距離（上腕7 + 前腕6）
  static final Vector2 shoulderPos = Vector2(0, -7); // 肩のジョイント位置

  final Random _random = Random();

  /// アームの届く範囲内のランダムな位置を生成
  Vector2 _getRandomPositionInArmReach() {
    // 肩を中心とした円環内にランダム配置
    final angle = _random.nextDouble() * 2 * pi;
    final distance = armReachMin + _random.nextDouble() * (armReachMax - armReachMin);
    return Vector2(
      shoulderPos.x + cos(angle) * distance,
      shoulderPos.y + sin(angle) * distance,
    );
  }

  Future<void> _spawnEnemies() async {
    // 5体の敵をアームの届く範囲内にランダム配置
    for (int i = 0; i < 5; i++) {
      final pos = _getRandomPositionInArmReach();
      final enemy = Enemy(position: pos, radius: 1.0);
      enemies.add(enemy);
      await world.add(enemy);
    }
  }

  void _onEnemyHit(Enemy enemy) {
    // キューに追加（重複防止）
    if (!_hitQueue.contains(enemy)) {
      _hitQueue.add(enemy);
    }
  }

  /// 腕の先端のワールド座標を取得
  Vector2 get armTipPosition {
    // 前腕のローカル座標で先端は (0, 3.5) の位置
    return foreArm.body.worldPoint(Vector2(0, 3.5));
  }

  /// 腕の先端と敵の当たり判定をチェック
  void _checkTipCollisions() {
    final tipPos = armTipPosition;
    for (final enemy in enemies) {
      final distance = tipPos.distanceTo(enemy.body.position);
      final hitDistance = tipRadius + enemy.radius;
      if (distance < hitDistance) {
        _onEnemyHit(enemy);
      }
    }
  }

  // 先端の当たり判定用の定数
  static const double tipRadius = 0.8; // 先端の当たり判定の半径

  // --- 【重要】強制更新ロジック ---
  @override
  void update(double dt) {
    super.update(dt);

    // ヒットキューを処理
    if (_hitQueue.isNotEmpty) {
      for (final enemy in _hitQueue) {
        hitCount.value++;
        enemy.respawn();
      }
      _hitQueue.clear();
    }

    // 腕の先端の当たり判定
    _checkTipCollisions();

    if (_isStraightening) {
      // 1. 上腕の現在の角度を取得
      final targetAngle = upperArm.body.angle;
      
      // 2. 上腕の回転速度を取得
      final targetAngularVelocity = upperArm.body.angularVelocity;

      // 3. 物理演算を無視して、前腕の状態を強制上書き(setTransform)
      //    位置(position)はそのまま、角度(angle)だけ上書きします。
      //    (位置の微妙なズレはジョイントが勝手に補正してくれます)
      foreArm.body.setTransform(foreArm.body.position, targetAngle);

      // 4. 慣性も同期させる（これがないと、整列した瞬間に回転の勢いでズレようとする）
      foreArm.body.angularVelocity = targetAngularVelocity;
    }
  }

  // --- 操作用メソッド ---

  void startStraightening() {
    _isStraightening = true;
    // モーターが邪魔しないようにOFFにする
    stopElbow();
  }

  void stopStraightening() {
    _isStraightening = false;
  }

  void controlShoulder(double speed) {
    if (shoulderJoint == null) return;
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
// 5. 敵クラス（当たり判定用）
// ---------------------------------------------------------
class Enemy extends BodyComponent {
  final Vector2 _initialPosition;
  final double _radius;

  Enemy({
    required Vector2 position,
    required double radius,
  })  : _initialPosition = position.clone(),
        _radius = radius;

  /// 当たり判定用の半径
  double get radius => _radius;

  @override
  RobotArmGame get game => findGame()! as RobotArmGame;

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
    // アームの届く範囲内のランダムな位置に移動
    final newPos = game._getRandomPositionInArmReach();
    body.setTransform(newPos, 0);
  }

  @override
  void render(Canvas canvas) {
    // 赤い丸で敵を描画
    final paint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(Offset.zero, _radius, paint);

    // 白い枠線
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;
    canvas.drawCircle(Offset.zero, _radius, border);
  }
}