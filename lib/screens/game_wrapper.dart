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
import '../widgets/hold_button.dart';

class GameWrapper extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onLose;
  final BleService bleService;
  final String defeatMessage;
  final bool enablePendulum;

  const GameWrapper({
    super.key,
    required this.onWin,
    required this.onLose,
    required this.bleService,
    required this.defeatMessage,
    required this.enablePendulum,
  });

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  BleService get _bleService => widget.bleService;
  bool _showDebugOverlay = false;

  // 全Config state
  GameConfig _config = GameConfig();
  ArmLayoutConfig _layout = ArmLayoutConfig();
  EnemyConfig _enemyConfig = EnemyConfig();
  HpBarConfig _playerHpConfig = HpBarConfig();
  HpBarConfig _enemyHpConfig = HpBarConfig();

  // ゲーム再生成用キー
  int _gameKey = 0;
  late RobotArmGame _game;

  @override
  void initState() {
    super.initState();
    _game = _createGame();
    _loadHpConfigs();
  }

  Future<void> _loadHpConfigs() async {
    final hpConfigs = await HpBarConfig.loadFromAsset();
    setState(() {
      _playerHpConfig = hpConfigs.player;
      _enemyHpConfig = hpConfigs.enemy;
    });
    _recreateGame();
  }

  RobotArmGame _createGame() {
    return RobotArmGame(
      onWin: widget.onWin,
      onLose: widget.onLose,
      bleService: _bleService,
      config: _config,
      layout: _layout,
      enemyConfig: _enemyConfig,
      playerHpConfig: _playerHpConfig,
      enemyHpConfig: _enemyHpConfig,
      enablePendulum: widget.enablePendulum,
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(key: ValueKey(_gameKey), game: _game),
        ValueListenableBuilder<bool>(
          valueListenable: _game.showDefeatMessage,
          builder: (context, show, _) {
            if (!show) return const SizedBox.shrink();
            return Positioned.fill(
              child: ColoredBox(
                color: Color(0xE6434343),
                child: Center(
                  child: Text(
                    widget.defeatMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
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
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => _game.startStraightening(),
                onTapUp: (_) => _game.stopStraightening(),
                onTapCancel: () => _game.stopStraightening(),
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.transparent,
                ),
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
            initialPlayerHpConfig: _playerHpConfig,
            initialEnemyHpConfig: _enemyHpConfig,
            onConfigChanged: (newConfig) => _config = newConfig,
            onLayoutChanged: (newLayout) => _layout = newLayout,
            onEnemyConfigChanged: (newConfig) => _enemyConfig = newConfig,
            onPlayerHpConfigChanged: (newConfig) => _playerHpConfig = newConfig,
            onEnemyHpConfigChanged: (newConfig) => _enemyHpConfig = newConfig,
            // Why: 即時反映だとゲーム状態(クリア判定等)がリセットされてしまうため、
            // [OK]ボタンで確定してからゲーム再生成する。
            onApply: _recreateGame,
            onClose: () => setState(() => _showDebugOverlay = false),
          ),
      ],
    );
  }
}
