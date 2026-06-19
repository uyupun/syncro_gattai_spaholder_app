import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../debug/debug_config_overlay.dart';
import '../game/actions_config.dart';
import '../game/arm_layout_config.dart';
import '../game/enemy_config.dart';
import '../game/game_config.dart';
import '../game/hp_bar_config.dart';
import '../game/robot_arm_game.dart';
import '../interfaces/ble_service.dart';
import '../widgets/action_label_text.dart';
import '../widgets/outlined_text.dart';
import '../widgets/charge_level_indicator.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/hold_button.dart';
import '../widgets/hp_bar_widget.dart';

class GameWrapper extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onLose;
  final VoidCallback onExitToTitle;
  final BleService bleService;
  final String defeatMessage;
  final bool enablePendulum;
  final String backgroundImagePath;

  const GameWrapper({
    super.key,
    required this.onWin,
    required this.onLose,
    required this.onExitToTitle,
    required this.bleService,
    required this.defeatMessage,
    required this.enablePendulum,
    required this.backgroundImagePath,
  });

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  BleService get _bleService => widget.bleService;
  bool _showDebugOverlay = false;
  bool _showExitDialog = false;

  // 全Config state
  GameConfig _config = GameConfig();
  ArmLayoutConfig _layout = ArmLayoutConfig();
  EnemyConfig _enemyConfig = EnemyConfig();
  HpBarConfig _playerHpConfig = HpBarConfig();
  HpBarConfig _enemyHpConfig = HpBarConfig();
  ActionsConfig _actionsConfig = ActionsConfig();

  // ゲーム再生成用キー
  int _gameKey = 0;
  late RobotArmGame _game;

  @override
  void initState() {
    super.initState();
    _game = _createGame();
    _loadHpConfigs();
    _loadActionsConfig();
  }

  Future<void> _loadHpConfigs() async {
    final hpConfigs = await HpBarConfig.loadFromAsset();
    setState(() {
      _playerHpConfig = hpConfigs.player;
      _enemyHpConfig = hpConfigs.enemy;
    });
    _recreateGame();
  }

  Future<void> _loadActionsConfig() async {
    final actionsConfig = await ActionsConfig.loadFromAsset();
    setState(() {
      _actionsConfig = actionsConfig;
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
      actionsConfig: _actionsConfig,
      enablePendulum: widget.enablePendulum,
      backgroundImagePath: widget.backgroundImagePath,
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

  void _openExitDialog() {
    _game.pauseEngine();
    setState(() => _showExitDialog = true);
  }

  void _continueGame() {
    setState(() => _showExitDialog = false);
    _game.resumeEngine();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = constraints.biggest;
        return Stack(
          children: [
            GameWidget(key: ValueKey(_gameKey), game: _game),
            Positioned(
              left: screenSize.width * _playerHpConfig.barPositionX,
              top: screenSize.height * _playerHpConfig.barPositionY,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _game.playerHp,
                    builder: (context, hp, _) => HpBarWidget(
                      hp: hp,
                      maxHp: _playerHpConfig.maxHp,
                      width: screenSize.width * _playerHpConfig.barSizeX,
                      barHeight: screenSize.height * _playerHpConfig.barSizeY,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _game.playerChargeLevel,
                        builder: (context, chargeLevel, _) =>
                            ChargeLevelIndicator(chargeLevel: chargeLevel),
                      ),
                      const SizedBox(width: 10),
                      ValueListenableBuilder<bool>(
                        valueListenable: _game.playerGuardActive,
                        builder: (context, guardActive, _) {
                          if (!guardActive) return const SizedBox.shrink();
                          return SvgPicture.asset(
                            'assets/images/shield.svg',
                            width: 14,
                            height: 16,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: screenSize.width * 0.28,
              top: screenSize.height * 0.18,
              child: ValueListenableBuilder<String?>(
                valueListenable: _game.playerActionLabel,
                builder: (context, label, _) {
                  if (label == null) return const SizedBox.shrink();
                  return ActionLabelText(
                    label: label,
                    colors: const [Color(0xFFFFFB05), Color(0xFFFCC727)],
                  );
                },
              ),
            ),
            Positioned(
              left: screenSize.width * _enemyHpConfig.barPositionX,
              top: screenSize.height * _enemyHpConfig.barPositionY,
              child: ValueListenableBuilder<double>(
                valueListenable: _game.enemyHp,
                builder: (context, hp, _) => HpBarWidget(
                  hp: hp,
                  maxHp: _enemyHpConfig.maxHp,
                  width: screenSize.width * _enemyHpConfig.barSizeX,
                  barHeight: screenSize.height * _enemyHpConfig.barSizeY,
                ),
              ),
            ),
            Positioned(
              left: screenSize.width * 0.56,
              top: screenSize.height * 0.12,
              child: ValueListenableBuilder<String?>(
                valueListenable: _game.enemyActionLabel,
                builder: (context, label, _) {
                  if (label == null) return const SizedBox.shrink();
                  return ActionLabelText(
                    label: label,
                    colors: widget.enablePendulum
                        ? const [Color(0xFFFF32F8), Color(0xFF730DB2)]
                        : const [Color(0xFF86D5FF), Color(0xFF2732FC)],
                  );
                },
              ),
            ),
            Positioned(
              left: screenSize.width * 0.56,
              top: screenSize.height * 0.12,
              child: ValueListenableBuilder<String?>(
                valueListenable: _game.asyncPendulumLabel,
                builder: (context, label, _) {
                  if (label == null) return const SizedBox.shrink();
                  return ActionLabelText(
                    label: label,
                    colors: const [Color(0xFFFF32F8), Color(0xFF730DB2)],
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _openExitDialog,
                  child: SvgPicture.asset(
                    'assets/images/exit.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _game.centerMessage,
              builder: (context, message, _) {
                if (message == null) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedText(text: message, fontSize: 28),
                    ),
                  ),
                );
              },
            ),
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
                onPlayerHpConfigChanged: (newConfig) =>
                    _playerHpConfig = newConfig,
                onEnemyHpConfigChanged: (newConfig) =>
                    _enemyHpConfig = newConfig,
                // Why: 即時反映だとゲーム状態(クリア判定等)がリセットされてしまうため、
                // [OK]ボタンで確定してからゲーム再生成する。
                onApply: _recreateGame,
                onClose: () => setState(() => _showDebugOverlay = false),
              ),
            if (_showExitDialog)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x99000000),
                  child: ExitDialog(
                    continueLabel: 'まだ戦う',
                    exitLabel: '帰還する',
                    onContinue: _continueGame,
                    onExit: widget.onExitToTitle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
