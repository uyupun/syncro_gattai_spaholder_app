import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug/debug_config_overlay.dart';
import '../game/arm_layout_config.dart';
import '../game/enemy_config.dart';
import '../game/game_config.dart';
import '../game/hp_bar_config.dart';
import '../game/robot_arm_game.dart';
import '../interfaces/ble_service.dart';
import '../models/accel_data.dart';
import '../widgets/hold_button.dart';

class GameWrapper extends StatefulWidget {
  final VoidCallback onGameClear;
  final BleService bleService;

  const GameWrapper({
    super.key,
    required this.onGameClear,
    required this.bleService,
  });

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  BleService get _bleService => widget.bleService;
  final Map<String, double> _latestValues = {};
  StreamSubscription<AccelData>? _accelSub;
  bool _showDebugOverlay = false;

  // 全Config state
  GameConfig _config = GameConfig();
  ArmLayoutConfig _layout = ArmLayoutConfig();
  EnemyConfig _enemyConfig = EnemyConfig();
  HpBarConfig _enemyHpConfig = HpBarConfig();

  // ゲーム再生成用キー
  int _gameKey = 0;
  late RobotArmGame _game;

  @override
  void initState() {
    super.initState();
    _game = _createGame();

    _accelSub = _bleService.accelDataStream.listen((accelData) {
      _latestValues[accelData.deviceId] = accelData.value;
      _checkStraighteningCondition();
    });
  }

  RobotArmGame _createGame() {
    return RobotArmGame(
      onGameClear: widget.onGameClear,
      bleService: _bleService,
      config: _config,
      layout: _layout,
      enemyConfig: _enemyConfig,
      enemyHpConfig: _enemyHpConfig,
    );
  }

  // Why: Config変更時にjoint/fixtureを個別再構築するのは複雑。
  // ゲーム全体を再生成し、ValueKey変更でGameWidgetに再描画を強制する。
  void _recreateGame() {
    setState(() {
      _gameKey++;
      _game = _createGame();
    });
  }

  void _checkStraighteningCondition() {
    final values = _latestValues.values.toList();

    if (values.length >= 2) {
      final allPositiveAndAboveOne = values.every(
        (value) => value > 0 && value >= 0.3,
      );

      if (allPositiveAndAboveOne) {
        _game.startStraightening();
      }
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(key: ValueKey(_gameKey), game: _game),
        ValueListenableBuilder<bool>(
          valueListenable: _game.showSuccessMessage,
          builder: (context, showMessage, child) {
            if (!showMessage) return const SizedBox.shrink();

            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _game.proceedToGameClear(),
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
                  onPressed: () => _game.startStraightening(),
                  onReleased: () => _game.stopStraightening(),
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode)
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () =>
                  setState(() => _showDebugOverlay = !_showDebugOverlay),
            ),
          ),
        if (kDebugMode && _showDebugOverlay)
          DebugConfigOverlay(
            initialConfig: _config,
            initialLayout: _layout,
            initialEnemyConfig: _enemyConfig,
            initialEnemyHpConfig: _enemyHpConfig,
            onConfigChanged: (newConfig) {
              _config = newConfig;
              _recreateGame();
            },
            onLayoutChanged: (newLayout) {
              _layout = newLayout;
              _recreateGame();
            },
            onEnemyConfigChanged: (newEnemyConfig) {
              _enemyConfig = newEnemyConfig;
              _recreateGame();
            },
            onEnemyHpConfigChanged: (newHpConfig) {
              _enemyHpConfig = newHpConfig;
              _recreateGame();
            },
            onClose: () => setState(() => _showDebugOverlay = false),
          ),
      ],
    );
  }
}
