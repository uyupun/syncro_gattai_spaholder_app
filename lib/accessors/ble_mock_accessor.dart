import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../interfaces/ble_service.dart';
import '../models/accel_data.dart';
import '../models/ble_device_role.dart';

class BleMockAccessor implements BleService {
  final _accelDataController = StreamController<AccelData>.broadcast();
  final _connectedDevicesController =
      StreamController<List<String>>.broadcast();
  final _connectedRolesController =
      StreamController<Set<BleDeviceRole>>.broadcast();

  final List<String> _mockDeviceIds = ['mock-device-1', 'mock-device-2'];
  final List<String> _connected = [];
  final Set<BleDeviceRole> _connectedRoles = {};
  Timer? _dataTimer;
  final _random = Random();
  double _phase = 0;

  /// テスト用: 次回の[connectDevice]を失敗させる
  bool failNextConnect = false;

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
    _ensureDataTimer();
  }

  @override
  Future<void> disconnectAll() async {
    _dataTimer?.cancel();
    _dataTimer = null;
    _connected.clear();
    _connectedDevicesController.add([]);
    _connectedRoles.clear();
    _connectedRolesController.add(Set.of(_connectedRoles));
    debugPrint('[BLE Mock] 全切断（モック）');
  }

  @override
  Future<void> sendVibration(int strength) async {
    debugPrint('[BLE Mock] sendVibration: 強度 $strength');
  }

  @override
  Stream<Set<BleDeviceRole>> get connectedRolesStream =>
      _connectedRolesController.stream;

  @override
  Set<BleDeviceRole> get connectedRoles => Set.unmodifiable(_connectedRoles);

  @override
  Future<void> connectDevice(BleDeviceRole role) async {
    if (_connectedRoles.contains(role)) return;

    debugPrint('[BLE Mock] ${role.deviceName} 接続開始');
    await Future<void>.delayed(const Duration(seconds: 1));

    if (failNextConnect) {
      failNextConnect = false;
      debugPrint('[BLE Mock] ${role.deviceName} 接続失敗');
      throw Exception('${role.deviceName} への接続に失敗しました');
    }

    _connectedRoles.add(role);
    _connectedRolesController.add(Set.of(_connectedRoles));

    if (!_connected.contains(role.deviceName)) {
      _connected.add(role.deviceName);
      _connectedDevicesController.add(List.of(_connected));
    }

    _ensureDataTimer();
    debugPrint('[BLE Mock] ${role.deviceName} 接続完了');
  }

  @override
  Future<void> disconnectDevice(BleDeviceRole role) async {
    if (!_connectedRoles.contains(role)) return;

    debugPrint('[BLE Mock] ${role.deviceName} 切断開始');
    await Future<void>.delayed(const Duration(milliseconds: 800));

    _connectedRoles.remove(role);
    _connectedRolesController.add(Set.of(_connectedRoles));

    _connected.remove(role.deviceName);
    _connectedDevicesController.add(List.of(_connected));

    if (_connected.isEmpty) {
      _dataTimer?.cancel();
      _dataTimer = null;
    }
    debugPrint('[BLE Mock] ${role.deviceName} 切断完了');
  }

  void _ensureDataTimer() {
    if (_dataTimer != null) return;

    _dataTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _phase = (_phase + 0.1) % (2 * pi);
      for (final (index, id) in _connected.indexed) {
        final x = sin(_phase + index * 1.5) * 0.5 + _random.nextDouble() * 0.1;
        final y = cos(_phase + index * 1.2) * 0.3 + _random.nextDouble() * 0.1;
        final z = sin(_phase + index * 0.8) * 0.8 + _random.nextDouble() * 0.1;
        _accelDataController.add(AccelData(deviceId: id, x: x, y: y, z: z));
      }
    });
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _accelDataController.close();
    _connectedDevicesController.close();
    _connectedRolesController.close();
  }
}
