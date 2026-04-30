import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'accessors/ble_mock_accessor.dart';
import 'ble_manager.dart';
import 'interfaces/ble_service.dart';
import 'screens/countdown_screen.dart';
import 'screens/game_clear_screen.dart';
import 'screens/game_wrapper.dart';
import 'screens/title_screen.dart';

const bool _kUseMockBleOverride = bool.fromEnvironment('USE_MOCK_BLE');

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

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(isPhysicalDevice: isPhysicalDevice, useMockBle: useMockBle),
    ),
  );
}

enum AppScreen { title, countdown, game, gameClear }

enum BattleStage { yugarock, asyncron }

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

  late final BleService _bleService = widget.useMockBle
      ? BleMockAccessor()
      : BleManager();

  @override
  void initState() {
    super.initState();
    _playBgm('title.mp3');
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

  void _startCountdown() {
    setState(() {
      _currentScreen = AppScreen.countdown;
    });
  }

  void _startBattle() {
    _playBgm('game.mp3');
    setState(() {
      _currentScreen = AppScreen.game;
    });
  }

  void _onWin() {
    switch (_currentStage) {
      case BattleStage.yugarock:
        setState(() {
          _currentStage = BattleStage.asyncron;
        });
      case BattleStage.asyncron:
        setState(() {
          _currentStage = BattleStage.yugarock;
          _currentScreen = AppScreen.gameClear;
        });
    }
  }

  void _onLose() {
    setState(() {
      _currentStage = BattleStage.yugarock;
      _currentScreen = AppScreen.gameClear;
    });
  }

  void _returnToTitle() {
    _playBgm('title.mp3');
    setState(() {
      _currentStage = BattleStage.yugarock;
      _currentScreen = AppScreen.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_currentScreen) {
        AppScreen.title => TitleScreen(
          onStart: _startCountdown,
          bleService: _bleService,
        ),
        AppScreen.countdown => CountdownScreen(onComplete: _startBattle),
        AppScreen.game => GameWrapper(
          onWin: _onWin,
          onLose: _onLose,
          bleService: _bleService,
        ),
        AppScreen.gameClear => GameClearScreen(onTap: _returnToTitle),
      },
    );
  }
}
