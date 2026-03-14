import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug/debug_config_overlay.dart';
import '../game/arm_layout_config.dart';
import '../game/enemy_config.dart';
import '../game/game_config.dart';
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
  late final RobotArmGame game;
  BleService get _bleService => widget.bleService;
  final Map<String, double> _latestValues = {};
  StreamSubscription<AccelData>? _accelSub;
  bool _showDebugOverlay = false;
  GameConfig _config = GameConfig();

  @override
  void initState() {
    super.initState();
    final layout = ArmLayoutConfig();
    final enemyConfig = EnemyConfig();
    game = RobotArmGame(
      onGameClear: widget.onGameClear,
      bleService: _bleService,
      config: _config,
      layout: layout,
      enemyConfig: enemyConfig,
    );

    _accelSub = _bleService.accelDataStream.listen((accelData) {
      _latestValues[accelData.deviceId] = accelData.value;
      _checkStraighteningCondition();
    });
  }

  void _checkStraighteningCondition() {
    // 2つのデバイスからの値を取得
    final values = _latestValues.values.toList();

    // 2つの値が存在し、両方とも正の値でかつ1以上の場合
    if (values.length >= 2) {
      final allPositiveAndAboveOne = values.every(
        (value) => value > 0 && value >= 0.3,
      );

      if (allPositiveAndAboveOne) {
        // 肘を伸ばすアクション（強制整列）を実行
        game.startStraightening();
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
        GameWidget(game: game),
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
            onConfigChanged: (newConfig) {
              setState(() => _config = newConfig);
            },
            onClose: () => setState(() => _showDebugOverlay = false),
          ),
      ],
    );
  }
}
