import 'dart:async';
import 'package:flutter/material.dart';
import 'ble_manager.dart';

class BleDebugPage extends StatefulWidget {
  const BleDebugPage({super.key});

  @override
  State<BleDebugPage> createState() => _BleDebugPageState();
}

class _BleDebugPageState extends State<BleDebugPage> {
  final BleManager _bleManager = BleManager();

  // データ管理用
  List<String> _connectedIds = [];
  final Map<String, AccelData> _dataMap = {};
  final Map<String, bool> _switchMap = {}; // 送信用スイッチの状態

  StreamSubscription? _deviceSub;
  StreamSubscription? _dataSub;

  @override
  void initState() {
    super.initState();

    // 接続リストの監視
    _deviceSub = _bleManager.connectedDevicesStream.listen((ids) {
      if (!mounted) return;
      setState(() {
        _connectedIds = ids;
        // 新規接続時にスイッチ初期値をfalseに
        for (var id in ids) {
          _switchMap.putIfAbsent(id, () => false);
        }
      });
    });

    // 加速度データの監視
    _dataSub = _bleManager.accelDataStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _dataMap[data.deviceId] = data;
      });
    });
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    _dataSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Simple Debug")),
      body: Column(
        children: [
          // 1. 操作ボタンエリア
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _bleManager.scanAndConnect(),
                  child: const Text("スキャン開始"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _bleManager.disconnectAll();
                    setState(() {
                      _connectedIds.clear();
                      _dataMap.clear();
                    });
                  },
                  child: const Text("全切断"),
                ),
                ElevatedButton(
                  onPressed: () => _bleManager.sendBool(true),
                  child: const Text("ポンプON"),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. デバイスリストエリア
          Expanded(
            child: ListView.separated(
              itemCount: _connectedIds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final id = _connectedIds[index];
                final data = _dataMap[id];

                // IDの末尾5文字だけ表示して短くする
                final shortId = id.length > 5
                    ? "...${id.substring(id.length - 5)}"
                    : id;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      // ID
                      Text(
                        "ID: $shortId",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const Spacer(),

                      // 加速度値
                      Text(
                        data != null
                            ? "${data.value.toStringAsFixed(2)} G"
                            : "Wait...",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
