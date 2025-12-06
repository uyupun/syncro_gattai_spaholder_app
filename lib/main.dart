import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ble_manager.dart';

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

  @override
  void initState() {
    super.initState();
    // タイトル画面のBGMを再生
    _playBgm('title.mp3');
  }

  /// BGMを切り替える（現在のBGMを停止して新しいBGMをループ再生）
  void _playBgm(String filename) {
    FlameAudio.bgm.stop();
    FlameAudio.bgm.play(filename);
  }

  void _startCountdown() {
    setState(() {
      _currentScreen = AppScreen.countdown;
    });
    // カウントダウン中はタイトルBGMを継続
  }

  void _startGame() {
    // ゲーム画面のBGMに切り替え
    _playBgm('game.mp3');
    setState(() {
      _currentScreen = AppScreen.game;
    });
  }

  void _showGameClear() {
    // クリア画面のBGMに切り替え
    _playBgm('clear.mp3');
    setState(() {
      _currentScreen = AppScreen.gameClear;
    });
  }

  void _returnToTitle() {
    // タイトル画面のBGMに切り替え
    _playBgm('title.mp3');
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
        AppScreen.game => GameWrapper(onGameClear: _returnToTitle),
        AppScreen.gameClear => GameClearScreen(onTap: _returnToTitle),
      },
    );
  }
}

// ---------------------------------------------------------
// 0.5. タイトル画面
// ---------------------------------------------------------
class TitleScreen extends StatefulWidget {
  final VoidCallback onStart;

  const TitleScreen({super.key, required this.onStart});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  final BleManager _bleManager = BleManager();
  bool _isConnecting = false;
  List<String> _connectedDevices = BleManager().connectedDevices;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // 接続デバイス数の変化を監視
    _bleManager.connectedDevicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _connectedDevices = devices;
           _isConnecting = devices.length < 2 ? _isConnecting : false; // 2台未満なら接続中
        });
      }
    });
  }

  Future<void> _connectDevices() async {
    if (_connectedDevices.length >= 2) return; // 既に2台接続済み

    setState(() {
      _isConnecting = true;
    });

    try {
      await _bleManager.scanAndConnect();
    } catch (e) {
      print('接続エラー: $e');
      setState(() {
        _isError = true;
        _isConnecting = false;
      });
    }
  }

  bool get _canStart => _connectedDevices.length >= 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // タイトル画像
            Image.asset(
              'assets/images/title.png',
              width: 500,
              height: 230,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 画像読み込みエラー時のフォールバック
                return const Text(
                  'ROBOT ARM',
                  style: TextStyle(
                    color: Colors.black87,
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
                );
              },
            ),

            // 接続状況表示
            Text(
              '接続デバイス数: ${_connectedDevices.length}/2',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 接続ボタン
                if (!_canStart)
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connectDevices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: _isConnecting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('接続中...'),
                            ],
                          )
                        : const Text('デバイス接続'),
                  ),
                if ( _canStart)
                  ElevatedButton(
                    onPressed: () {
                      _bleManager.disconnectAll();
                      setState(() {
                        _isConnecting = false;
                        _isError = false;
                        _connectedDevices.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('デバイス解除'),
                  ),

                const SizedBox(width: 20),

                // スタートボタン
                ElevatedButton(
                  onPressed: _canStart ? widget.onStart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canStart ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('ゲームスタート'),
                ),
              ],
            ),

            if (_isError)
              Text(
                '接続エラーが発生しました。再度接続をお試しください。',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 必要に応じてBLEマネージャーのリソースを解放
    super.dispose();
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
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Text(
          _showGameStart ? 'ゲームスタート' : '$_count',
          style: TextStyle(
            color: Colors.black87,
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
        color: const Color(0xFFFFFFFF),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GAME CLEAR!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.greenAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'Tap to Return',
                style: TextStyle(
                  color: Colors.black54,
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
  final BleManager _bleManager = BleManager();
  final Map<String, double> _latestValues = {}; // デバイスIDごとの最新値を保存

  @override
  void initState() {
    super.initState();
    game = RobotArmGame(onGameClear: widget.onGameClear);
    
    // BLE データストリームを監視
    _bleManager.accelDataStream.listen((accelData) {
      _latestValues[accelData.deviceId] = accelData.value;
      _checkStraighteningCondition();
    });
  }

  void _checkStraighteningCondition() {
    // 2つのデバイスからの値を取得
    final values = _latestValues.values.toList();
    
    // 2つの値が存在し、両方とも正の値でかつ1以上の場合
    if (values.length >= 2) {
      final allPositiveAndAboveOne = values.every((value) => value > 0 && value >= 0.5);
      
      if (allPositiveAndAboveOne) {
        // 肘を伸ばすアクション（強制整列）を実行
        game.startStraightening();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        // スコア表示（非表示）
        // Positioned(
        //   top: 30,
        //   left: 0,
        //   right: 0,
        //   child: ValueListenableBuilder<int>(
        //     valueListenable: game.hitCount,
        //     builder: (context, count, child) {
        //       return Text(
        //         'HIT: $count',
        //         textAlign: TextAlign.center,
        //         style: const TextStyle(
        //           color: Colors.white,
        //           fontSize: 32,
        //           fontWeight: FontWeight.bold,
        //           shadows: [
        //             Shadow(blurRadius: 4, color: Colors.black),
        //           ],
        //         ),
        //       );
        //     },
        //   ),
        // ),
        // --- 成功メッセージオーバーレイ ---
        ValueListenableBuilder<bool>(
          valueListenable: game.showSuccessMessage,
          builder: (context, showMessage, child) {
            if (!showMessage) return const SizedBox.shrink();
            
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => game.proceedToGameClear(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '温泉が帰ってきた！',
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                blurRadius: 15,
                                color: Colors.orange,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 30,
                                color: Colors.red,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'タップして戻る',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.black,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // --- 中央下：腕伸ばしボタンのみ表示 デバッグボタン ---
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                color: Colors.black87,
                fontWeight: FontWeight.bold)),
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
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 32, color: Colors.transparent),
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
  static const double _randomChangeInterval = 0.3; // 0.3秒ごとに方向変更

  // ヒットチェック用
  final ValueNotifier<int> hitCount = ValueNotifier<int>(0);
  final List<Enemy> enemies = [];
  bool _isCleared = false; // 一度ヒットしたらtrue（重複防止）
  bool _physicsStoppedOnHit = false; // 物理演算停止フラグ
  final ValueNotifier<bool> showSuccessMessage = ValueNotifier<bool>(false); // 成功メッセージ表示フラグ

  // アームの届く範囲
  // 上腕ジョイント間: 7, 前腕ジョイント〜先端: 6.5 → 合計13.5
  static const double armLength = 15;
  static final Vector2 shoulderPos = Vector2(-10, -7); // 左側に配置
  static const double tipRadius = 0.8; // 先端の当たり判定半径
  static const double enemyRadius = 6; // 敵の半径（画像サイズに合わせて拡大、ただし画像より少し小さく）

  // 背景画像
  Sprite? _backgroundSprite;

  @override
  Color backgroundColor() => const Color(0xFFFFFFFF);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    // --- 背景画像を読み込み ---
    try {
      _backgroundSprite = await Sprite.load('game_background.jpg');
    } catch (e) {
      print('Failed to load background image: game_background.jpg, error: $e');
    }

    // --- 敵を配置 ---
    await _spawnEnemies();

    // --- パーツ生成 ---
    upperArm = ArmPart(
        position: Vector2(-10, -4),  // shoulderと重なるように調整
        size: Vector2(4.35, 8),  // 277x509のアスペクト比を保持 (8 * 277/509 ≈ 4.35)
        isStatic: false,
        color: Colors.blueAccent,
        imagePath: 'upper_arm.png');
    await world.add(upperArm);

    foreArm = ArmPart(
        position: Vector2(-8.5, 1.5),  // 上腕と重なるように位置調整
        size: Vector2(4.85, 8),  // 389x642のアスペクト比を保持 (8 * 389/642 ≈ 4.85)
        isStatic: false,
        color: Colors.lightBlueAccent,
        imagePath: 'drill.png');
    await world.add(foreArm);

    // アームを左側に配置（画像を使用）
    shoulder = ArmPart(
        position: Vector2(-12, 0),  // 上腕より上に配置
        size: Vector2(16, 16),  // アスペクト比を維持できるよう大きめに設定
        isStatic: true,
        color: Colors.grey,
        imagePath: 'upper_body.png');
    await world.add(shoulder);

    // --- ジョイント生成 ---
    final shoulderJointDef = RevoluteJointDef()
      ..bodyA = shoulder.body
      ..bodyB = upperArm.body
      ..collideConnected = false
      ..localAnchorA.setValues(6, -4.5)  // shoulderの右上
      ..localAnchorB.setValues(0, -4)  // upperArmの上端
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = 8000.0;  // トルクを4倍に増加
    shoulderJoint = RevoluteJoint(shoulderJointDef);
    world.createJoint(shoulderJoint!);

    final elbowJointDef = RevoluteJointDef()
      ..bodyA = upperArm.body
      ..bodyB = foreArm.body
      ..collideConnected = false
      ..localAnchorA.setValues(1.75, 3)  // upper armの右下付近
      ..localAnchorB.setValues(-1, -3.5)  // drillの左上付近
      ..enableLimit = false
      ..enableMotor = false
      ..maxMotorTorque = 15000.0;  // トルクを3倍に増加
    elbowJoint = RevoluteJoint(elbowJointDef);
    world.createJoint(elbowJoint!);

    // --- 常にランダムモードを有効化 ---
    startRandomMode();
  }

  Future<void> _spawnEnemies() async {
    // 敵は1体、中央右側に配置（アームの最大到達距離ジャストの位置）
    // 敵の端がちょうど腕の先端位置になるように配置
    // tipPosition = shoulderPos.x + armLength
    // enemyEdge = enemyCenter - enemyRadius = tipPosition
    // よって enemyCenter = shoulderPos.x + armLength + enemyRadius
    final enemyPos = Vector2(
      shoulderPos.x + armLength + enemyRadius, // 敵の端がジャスト腕の先端
      0, // 画面中央の高さ
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
    // 既にクリア済みなら何もしない
    if (_isCleared) return;

    final tipPos = armTipPosition;
    for (final enemy in enemies) {
      final distance = tipPos.distanceTo(enemy.body.position);
      final hitDistance = tipRadius + enemy.radius;
      if (distance < hitDistance) {
        // 敵の画像を変更
        enemy.onHit();
        
        // 一度ヒットしたら物理演算を停止し、成功メッセージを表示
        _isCleared = true;
        _physicsStoppedOnHit = true;
        hitCount.value++;

        // 物理演算を停止
        _stopAllPhysics();

        Future.delayed(Duration(seconds: 3), () {
          showSuccessMessage.value = true;
          BleManager().sendBool(true);
          
        });
        FlameAudio.bgm.stop();
        FlameAudio.play('clear.mp3');

        // タップでクリア画面に遷移するように変更（自動遷移は削除）
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
    // ランダムモードを停止
    stopRandomMode();
    
    // 整列モードも停止
    stopStraightening();
    
    // 全ての関節のモーターを停止
    stopShoulder();
    stopElbow();
    
    // 全てのボディの速度を0にして固定
    shoulder.body.linearVelocity = Vector2.zero();
    shoulder.body.angularVelocity = 0.0;
    upperArm.body.linearVelocity = Vector2.zero();
    upperArm.body.angularVelocity = 0.0;
    foreArm.body.linearVelocity = Vector2.zero();
    foreArm.body.angularVelocity = 0.0;
    
    // 全てのボディを静的に変更して完全に固定
    upperArm.body.setType(BodyType.static);
    foreArm.body.setType(BodyType.static);
  }

  @override
  void render(Canvas canvas) {
    // 背景画像を描画（薄く表示）
    if (_backgroundSprite != null) {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.5); // 透明度50%（より薄く）
      canvas.saveLayer(null, paint);
      
      // アスペクト比を維持しながら横幅いっぱいに表示
      final screenSize = size;
      final spriteSize = _backgroundSprite!.srcSize;
      final aspectRatio = spriteSize.x / spriteSize.y;
      
      // 横幅を画面幅に合わせ、高さはアスペクト比を維持
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

  // --- 【重要】強制更新ロジック ---
  @override
  void update(double dt) {
    // 物理演算が停止されている場合は更新をスキップ
    if (_physicsStoppedOnHit) {
      return;
    }

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
    // 物理演算が停止されている場合は何もしない
    if (_physicsStoppedOnHit) return;
    
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
    // 肩：-12.0 〜 12.0 のランダムな速度（3倍に拡大）
    final shoulderSpeed = (_random.nextDouble() * 24.0) - 12.0;
    controlShoulder(shoulderSpeed);

    // 肘：-18.0 〜 18.0 のランダムな速度（3倍に拡大、整列中は動かさない）
    if (!_isStraightening) {
      final elbowSpeed = (_random.nextDouble() * 36.0) - 18.0;
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
  final String? _imagePath;
  Sprite? _sprite;

  ArmPart({
    required Vector2 position,
    required Vector2 size,
    required bool isStatic,
    required Color color,
    String? imagePath,
  })  : _pos = position,
        _size = size,
        _isStatic = isStatic,
        _color = color,
        _imagePath = imagePath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_imagePath != null) {
      try {
        _sprite = await Sprite.load(_imagePath!);
      } catch (e) {
        // 画像の読み込みに失敗した場合はスプライトをnullのままにする
        print('Failed to load image: $_imagePath, error: $e');
      }
    }
  }

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
    if (_sprite != null) {
      // 画像を使用してレンダリング（アスペクト比を維持）
      final spriteSize = _sprite!.srcSize;
      final aspectRatio = spriteSize.x / spriteSize.y;
      
      // 指定されたサイズ内でアスペクト比を維持しながらフィット
      Vector2 renderSize;
      if (_size.x / _size.y > aspectRatio) {
        // 高さに合わせてスケール
        renderSize = Vector2(_size.y * aspectRatio, _size.y);
      } else {
        // 幅に合わせてスケール
        renderSize = Vector2(_size.x, _size.x / aspectRatio);
      }
      
      _sprite!.render(
        canvas,
        size: renderSize,
        anchor: Anchor.center,
      );
    } else {
      // 画像がない場合は従来の矩形描画
      final paint = Paint()..color = _color;
      final rect = Rect.fromCenter(
          center: Offset.zero, width: _size.x, height: _size.y);
      canvas.drawRect(rect, paint);
      final border = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1;
      canvas.drawRect(rect, border);
    }
    
    // ジョイント位置の表示（画像使用時は透明化）
    if (_sprite == null) {
      // 画像がない場合のみジョイント位置を表示
      final jointPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
      canvas.drawCircle(Offset(0, -_size.y / 2 + 0.5), 0.4, jointPaint);
      canvas.drawCircle(Offset(0, _size.y / 2 - 0.5), 0.4, jointPaint);
    }
  }
}

// ---------------------------------------------------------
// 5. 敵クラス
// ---------------------------------------------------------
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
      _sprite = await Sprite.load('rockmonster.png');
      _splashSprite = await Sprite.load('rockmonster_splashA.png');
    } catch (e) {
      // 画像の読み込みに失敗した場合はスプライトをnullのままにする
      print('Failed to load image: $e');
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
    // ヒット状態に応じて画像を切り替え
    final currentSprite = _isHit ? _splashSprite : _sprite;
    
    if (currentSprite != null) {
      // 画像を使用してレンダリング（サイズを2倍に）
      final size = _radius * 2.5; // 直径の2倍
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