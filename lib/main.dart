import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'accessors/ble_mock_accessor.dart';
import 'ble_debug_page.dart';
import 'ble_manager.dart';
import 'interfaces/ble_service.dart';
import 'screens/enemy_intro_screen.dart';
import 'screens/game_wrapper.dart';
import 'screens/result_screen.dart';
import 'screens/title_screen.dart';
import 'widgets/pure_shader_retro.dart';

const bool _kUseMockBleOverride = bool.fromEnvironment('USE_MOCK_BLE');
const bool _kShowBleDebugPage = bool.fromEnvironment('SHOW_BLE_DEBUG');

Future<bool> _detectPhysicalDevice() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    return info.isPhysicalDevice;
  }
  if (Platform.isIOS) {
    final info = await deviceInfo.iosInfo;
    return info.isPhysicalDevice;
  }
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 横向き固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final isPhysicalDevice = await _detectPhysicalDevice();
  // BLE: --dart-define=USE_MOCK_BLE=true ならモック強制、未指定なら実機判定
  final useMockBle = _kUseMockBleOverride || !isPhysicalDevice;

  // --dart-define=SHOW_BLE_DEBUG=true のときBLEデバッグ画面を直接表示
  final Widget home = _kShowBleDebugPage
      ? BleDebugPage(bleService: useMockBle ? BleMockAccessor() : BleManager())
      : MyApp(isPhysicalDevice: isPhysicalDevice, useMockBle: useMockBle);

  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: home));
}

enum AppScreen { title, enemyIntro, game, result }

enum BattleStage { yugarock, asyncron }

enum GameResult { yugarockLose, asyncronLose, allClear }

class MyApp extends StatefulWidget {
  final bool isPhysicalDevice;
  final bool useMockBle;

  const MyApp({
    super.key,
    required this.isPhysicalDevice,
    required this.useMockBle,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppScreen _currentScreen = AppScreen.title;
  BattleStage _currentStage = BattleStage.yugarock;
  GameResult _currentResult = GameResult.allClear;

  late final BleService _bleService = widget.useMockBle
      ? BleMockAccessor()
      : BleManager();

  @override
  void initState() {
    super.initState();
    FlameAudio.updatePrefix('assets/');
    _playBgm('bgm/title.mp3');
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  /// BGMを切り替える（現在のBGMを停止して新しいBGMをループ再生）
  void _playBgm(String filename) {
    FlameAudio.bgm.stop();
    FlameAudio.bgm.play(filename);
  }

  void _startEnemyIntro() {
    _playBgm('bgm/yugarock-title.mp3');
    setState(() {
      _currentScreen = AppScreen.enemyIntro;
    });
  }

  void _startBattle() {
    _playBgm(switch (_currentStage) {
      BattleStage.yugarock => 'bgm/yugarock-battle.mp3',
      BattleStage.asyncron => 'bgm/asyncron-battle.mp3',
    });
    setState(() {
      _currentScreen = AppScreen.game;
    });
  }

  void _onWin() {
    switch (_currentStage) {
      case BattleStage.yugarock:
        _playBgm('bgm/asyncron-title.mp3');
        setState(() {
          _currentStage = BattleStage.asyncron;
          _currentScreen = AppScreen.enemyIntro;
        });
      case BattleStage.asyncron:
        _playBgm('bgm/victory.mp3');
        setState(() {
          _currentStage = BattleStage.yugarock;
          _currentResult = GameResult.allClear;
          _currentScreen = AppScreen.result;
        });
    }
  }

  void _onLose() {
    final result = switch (_currentStage) {
      BattleStage.yugarock => GameResult.yugarockLose,
      BattleStage.asyncron => GameResult.asyncronLose,
    };
    _playBgm(switch (result) {
      GameResult.yugarockLose => 'bgm/defeat.mp3',
      GameResult.asyncronLose || GameResult.allClear => 'bgm/victory.mp3',
    });
    setState(() {
      _currentResult = result;
      _currentStage = BattleStage.yugarock;
      _currentScreen = AppScreen.result;
    });
  }

  void _returnToTitle() {
    _playBgm('bgm/title.mp3');
    setState(() {
      _currentStage = BattleStage.yugarock;
      _currentScreen = AppScreen.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PureShaderRetro(
        child: switch (_currentScreen) {
          AppScreen.title => TitleScreen(
            onStart: _startEnemyIntro,
            bleService: _bleService,
          ),
          AppScreen.enemyIntro => EnemyIntroScreen(
            stage: _currentStage,
            onComplete: _startBattle,
          ),
          AppScreen.game => GameWrapper(
            onWin: _onWin,
            onLose: _onLose,
            onExitToTitle: _returnToTitle,
            bleService: _bleService,
            defeatMessage: switch (_currentStage) {
              BattleStage.yugarock => 'ヒーロー、ここで倒れる...！',
              BattleStage.asyncron => '戦いは怪獣の勝利に終わった...！',
            },
            // 振り子動作はアシンクロン戦のみの難易度調整。ユガロック戦は肩・肘を固定する。
            enablePendulum: _currentStage == BattleStage.asyncron,
          ),
          AppScreen.result => ResultScreen(
            result: _currentResult,
            onTitle: _returnToTitle,
          ),
        },
      ),
    );
  }
}
