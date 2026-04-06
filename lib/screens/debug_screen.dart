import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ble_debug_page.dart';
import '../debug/debug_config_overlay.dart';
import '../game/game_config.dart';
import '../interfaces/ble_service.dart';

class DebugScreen extends StatelessWidget {
  final BleService bleService;

  const DebugScreen({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('デバッグモード専用')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('デバッグ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'BLE'),
              Tab(text: '設定'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BleDebugContent(bleService: bleService),
            DebugConfigContent(
              initialConfig: GameConfig.defaultConfig(),
              onConfigChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
