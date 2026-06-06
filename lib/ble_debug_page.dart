import 'dart:async';
import 'package:flutter/material.dart';
import 'interfaces/ble_service.dart';
import 'models/accel_data.dart';

// 攻撃トリガーの閾値
const double _kThresholdX = 1.0;
const double _kThresholdY = 0.75;
const double _kThresholdZ = 2.0;

class BleDebugPage extends StatelessWidget {
  final BleService bleService;

  const BleDebugPage({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLEデバッグ")),
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

  // 接続済み2台ともが閾値を超えているか判定
  bool _bothExceed(double Function(AccelData) axis, double threshold) {
    if (_connectedIds.length < 2) return false;
    return _connectedIds.every((id) {
      final data = _dataMap[id];
      return data != null && axis(data) >= threshold;
    });
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final horizontalPadding = EdgeInsets.only(
      left: safePadding.left + 16,
      right: safePadding.right + 32,
    );

    final xAttack = _bothExceed((d) => d.x, _kThresholdX);
    final yAttack = _bothExceed((d) => d.y.abs(), _kThresholdY);
    final zAttack = _bothExceed((d) => d.z, _kThresholdZ);

    return Column(
      children: [
        Padding(
          padding: horizontalPadding.copyWith(top: 6, bottom: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _bleService.scanAndConnect(),
                child: const Text("スキャン開始"),
              ),
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
                onPressed: () => _bleService.sendVibration(100),
                child: const Text("振動ON"),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // デバイスごとの加速度値
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _connectedIds.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final id = _connectedIds[index];
            final data = _dataMap[id];
            final shortId = id.length > 5
                ? "...${id.substring(id.length - 5)}"
                : id;
            return Padding(
              padding: horizontalPadding.copyWith(top: 6, bottom: 6),
              child: Row(
                children: [
                  Text(
                    "ID: $shortId",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    data != null
                        ? "X:${data.x.toStringAsFixed(2)} Y:${data.y.toStringAsFixed(2)} Z:${data.z.toStringAsFixed(2)} G"
                        : "待機中...",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        // 攻撃条件パネル
        Padding(
          padding: horizontalPadding.copyWith(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttackConditionChip(
                label: "X攻撃",
                condition: "2台ともX≥${_kThresholdX.toStringAsFixed(0)}",
                triggered: xAttack,
              ),
              _AttackConditionChip(
                label: "Y攻撃",
                condition: "2台とも|Y|≥${_kThresholdY.toStringAsFixed(2)}",
                triggered: yAttack,
              ),
              _AttackConditionChip(
                label: "Z攻撃",
                condition: "2台ともZ≥${_kThresholdZ.toStringAsFixed(0)}",
                triggered: zAttack,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttackConditionChip extends StatelessWidget {
  final String label;
  final String condition;
  final bool triggered;

  const _AttackConditionChip({
    required this.label,
    required this.condition,
    required this.triggered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: triggered ? Colors.green : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: triggered ? Colors.green.shade700 : Colors.red.shade300,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: triggered ? Colors.white : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            condition,
            style: TextStyle(
              fontSize: 12,
              color: triggered ? Colors.white70 : Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            triggered ? "発動！" : "未達",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: triggered ? Colors.white : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
