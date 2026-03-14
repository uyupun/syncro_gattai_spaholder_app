import 'dart:async';
import 'package:flutter/material.dart';
import 'interfaces/ble_service.dart';
import 'models/accel_data.dart';

class BleDebugPage extends StatelessWidget {
  final BleService bleService;

  const BleDebugPage({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Simple Debug")),
      body: BleDebugContent(bleService: bleService),
    );
  }
}

class BleDebugContent extends StatefulWidget {
  final BleService bleService;

  const BleDebugContent({super.key, required this.bleService});

  @override
  State<BleDebugContent> createState() => _BleDebugContentState();
}

class _BleDebugContentState extends State<BleDebugContent> {
  BleService get _bleService => widget.bleService;

  List<String> _connectedIds = [];
  final Map<String, AccelData> _dataMap = {};

  StreamSubscription<List<String>>? _deviceSub;
  StreamSubscription<AccelData>? _dataSub;

  @override
  void initState() {
    super.initState();

    _deviceSub = _bleService.connectedDevicesStream.listen((ids) {
      if (!mounted) return;
      setState(() {
        _connectedIds = ids;
      });
    });

    _dataSub = _bleService.accelDataStream.listen((data) {
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _bleService.scanAndConnect(),
                child: const Text("スキャン開始"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  _bleService.disconnectAll();
                  setState(() {
                    _connectedIds.clear();
                    _dataMap.clear();
                  });
                },
                child: const Text("全切断"),
              ),
              ElevatedButton(
                onPressed: () => _bleService.sendBool(true),
                child: const Text("ポンプON"),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: _connectedIds.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final id = _connectedIds[index];
              final data = _dataMap[id];

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
                    Text(
                      "ID: $shortId",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
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
    );
  }
}
