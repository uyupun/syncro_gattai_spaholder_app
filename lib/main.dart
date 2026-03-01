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

const bool kUseMockBle = bool.fromEnvironment('USE_MOCK_BLE');

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

enum AppScreen { title, countdown, game, gameClear }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppScreen _currentScreen = AppScreen.title;
  final BleService _bleService = kUseMockBle ? BleMockAccessor() : BleManager();

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
    // カウントダウン中はタイトルBGMを継続
  }

  void _startGame() {
    // ゲーム画面のBGMに切り替え
    _playBgm('game.mp3');
    setState(() {
      _currentScreen = AppScreen.game;
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
        AppScreen.title => TitleScreen(
          onStart: _startCountdown,
          bleService: _bleService,
        ),
        AppScreen.countdown => CountdownScreen(onComplete: _startGame),
        AppScreen.game => GameWrapper(
          onGameClear: _returnToTitle,
          bleService: _bleService,
        ),
        AppScreen.gameClear => GameClearScreen(onTap: _returnToTitle),
      },
    );
  }
}
