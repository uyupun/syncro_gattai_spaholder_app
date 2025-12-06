import 'dart:ui';
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
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
        child: Icon(icon, size: 32, color: Colors.redAccent.withOpacity(0.8)),
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
  }

  // --- 【重要】強制更新ロジック ---
  @override
  void update(double dt) {
    super.update(dt);

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
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;
    canvas.drawRect(rect, border);
    final jointPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(Offset(0, -_size.y / 2 + 0.5), 0.4, jointPaint);
    canvas.drawCircle(Offset(0, _size.y / 2 - 0.5), 0.4, jointPaint);
  }
}