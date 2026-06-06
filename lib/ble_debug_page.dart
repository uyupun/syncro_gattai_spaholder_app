import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'interfaces/ble_service.dart';
import 'models/accel_data.dart';

const double _kThresholdX = 1.0;
const double _kThresholdY = 0.75;
const double _kThresholdZ = 2.0;

// チャージレベルごとの攻撃倍率 (index = charge level)
const List<double> _kChargeMultipliers = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0];

class _ActionEntry {
  final String name;
  final int power;
  final bool isCharge;

  const _ActionEntry(this.name, this.power, {this.isCharge = false});
}

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

  // JSONから読み込むベースpower値
  int _synchroAttackBasePower = 10;
  int _synchroGuardPower = 25;

  // 現在のトリガー状態 (チップ表示用)
  bool _xAttack = false;
  bool _yAttack = false;
  bool _zAttack = false;

  // エッジ検出用: 前フレームのトリガー状態
  bool _prevXAttack = false;
  bool _prevYAttack = false;
  bool _prevZAttack = false;

  // チャージレベル (0〜5)
  int _chargeLevel = 0;

  // アクションログ (スタック表示、永続)
  final List<_ActionEntry> _actionLog = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadActionsConfig();

    _deviceSub = _bleService.connectedDevicesStream.listen((ids) {
      if (!mounted) return;
      setState(() {
        _connectedIds = ids;
      });
    });

    _dataSub = _bleService.accelDataStream.listen((data) {
      if (!mounted) return;
      final prevLogLength = _actionLog.length;
      setState(() {
        _dataMap[data.deviceId] = data;
        _detectTriggers();
      });
      if (_actionLog.length > prevLogLength) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  Future<void> _loadActionsConfig() async {
    final json = await rootBundle.loadString('assets/actions_config.json');
    final config = jsonDecode(json) as Map<String, dynamic>;
    final actions =
        (config['player'] as Map<String, dynamic>)['actions']
            as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _synchroAttackBasePower =
          (actions['synchroAttack'] as Map<String, dynamic>)['power'] as int;
      _synchroGuardPower =
          (actions['synchroGuard'] as Map<String, dynamic>)['power'] as int;
    });
  }

  void _detectTriggers() {
    final x = _bothExceed((d) => d.x, _kThresholdX);
    final y = _bothExceed((d) => d.y.abs(), _kThresholdY);
    final z = _bothExceed((d) => d.z, _kThresholdZ);

    if (x && !_prevXAttack) {
      _actionLog.add(_ActionEntry('Synchro Attack', _calcAttackPower()));
      _chargeLevel = 0;
    }
    if (y && !_prevYAttack) {
      _actionLog.add(_ActionEntry('Synchro Guard', _synchroGuardPower));
    }
    if (z && !_prevZAttack && _chargeLevel < 5) {
      _chargeLevel++;
      _actionLog.add(
        _ActionEntry('Synchro Charge', _chargeLevel, isCharge: true),
      );
    }

    _xAttack = x;
    _yAttack = y;
    _zAttack = z;
    _prevXAttack = x;
    _prevYAttack = y;
    _prevZAttack = z;
  }

  int _calcAttackPower() {
    return (_synchroAttackBasePower * _kChargeMultipliers[_chargeLevel])
        .round();
  }

  bool _bothExceed(double Function(AccelData) axis, double threshold) {
    if (_connectedIds.length < 2) return false;
    return _connectedIds.every((id) {
      final data = _dataMap[id];
      return data != null && axis(data) >= threshold;
    });
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    _dataSub?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final horizontalPadding = EdgeInsets.only(
      left: safePadding.left + 16,
      right: safePadding.right + 32,
    );

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
        // 攻撃条件チップ
        Padding(
          padding: horizontalPadding.copyWith(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttackConditionChip(
                label: "X攻撃",
                condition: "2台ともX≥${_kThresholdX.toStringAsFixed(0)}",
                triggered: _xAttack,
              ),
              _AttackConditionChip(
                label: "Y防御",
                condition: "2台とも|Y|≥${_kThresholdY.toStringAsFixed(2)}",
                triggered: _yAttack,
              ),
              _AttackConditionChip(
                label: "Zチャージ",
                condition: "2台ともZ≥${_kThresholdZ.toStringAsFixed(0)}",
                triggered: _zAttack,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // アクションログ
        Expanded(
          child: _actionLog.isEmpty
              ? const Center(
                  child: Text(
                    "アクション待機中...",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _logScrollController,
                  padding: horizontalPadding.copyWith(top: 8, bottom: 8),
                  itemCount: _actionLog.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ActionLogEntry(entry: _actionLog[index]),
                    );
                  },
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

class _ActionLogEntry extends StatelessWidget {
  final _ActionEntry entry;

  const _ActionLogEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (color, textColor) = switch (entry.name) {
      'Synchro Attack' => (Colors.red.shade100, Colors.red.shade800),
      'Synchro Guard' => (Colors.blue.shade100, Colors.blue.shade800),
      _ => (Colors.amber.shade100, Colors.amber.shade900),
    };

    final powerLabel = entry.isCharge
        ? "Lv.${entry.power}"
        : "Power: ${entry.power}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(
            entry.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            powerLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
