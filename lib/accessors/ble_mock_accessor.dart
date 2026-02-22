import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../interfaces/ble_service.dart';
import '../models/accel_data.dart';

class BleMockAccessor implements BleService {
  final _accelDataController = StreamController<AccelData>.broadcast();
  final _connectedDevicesController =
      StreamController<List<String>>.broadcast();

  final List<String> _mockDeviceIds = ['mock-device-1', 'mock-device-2'];
  final List<String> _connected = [];
  Timer? _dataTimer;
  final _random = Random();
  double _phase = 0;

  @override
  Stream<AccelData> get accelDataStream => _accelDataController.stream;

  @override
  Stream<List<String>> get connectedDevicesStream =>
      _connectedDevicesController.stream;

  @override
  List<String> get connectedDevices => List.unmodifiable(_connected);

  @override
  Future<void> scanAndConnect() async {
    debugPrint('[BLE Mock] スキャン開始（モック）');

    // 仮想デバイス2台を500ms間隔で接続
    for (final id in _mockDeviceIds) {
      if (_connected.contains(id)) continue;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _connected.add(id);
      _connectedDevicesController.add(List.of(_connected));
      debugPrint('[BLE Mock] 接続: $id');
    }

    // タイマーで加速度データをストリーム生成
    _dataTimer?.cancel();
    _dataTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _phase = (_phase + 0.1) % (2 * pi);
      for (final (index, id) in _connected.indexed) {
        final value = sin(_phase + index * 1.5) * 0.5 +
            _random.nextDouble() * 0.1;
        _accelDataController.add(AccelData(deviceId: id, value: value));
      }
    });
  }

  @override
  Future<void> disconnectAll() async {
    _dataTimer?.cancel();
    _dataTimer = null;
    _connected.clear();
    _connectedDevicesController.add([]);
    debugPrint('[BLE Mock] 全切断（モック）');
  }

  @override
  Future<void> sendBool(bool value) async {
    debugPrint('[BLE Mock] sendBool: ${value ? "ON" : "OFF"}');
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _accelDataController.close();
    _connectedDevicesController.close();
  }
}
