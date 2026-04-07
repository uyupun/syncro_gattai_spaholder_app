import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ble_debug_page.dart';
import '../interfaces/ble_service.dart';

class DebugScreen extends StatelessWidget {
  final BleService bleService;

  const DebugScreen({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('デバッグモード専用')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('デバッグ')),
      body: BleDebugContent(bleService: bleService),
    );
  }
}
