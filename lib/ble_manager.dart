import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'interfaces/ble_service.dart';
import 'models/accel_data.dart';
import 'models/ble_device_role.dart';

class BleManager implements BleService {
  BleManager();

  // --- 定数 ---
  static const String _targetDeviceName = "spaholder-drill-smasher";
  static const String _serviceUuid = "11111111-2222-3333-4444-555555555555";
  static const String _charUuid = "11111111-2222-3333-4444-666666666666";

  // --- 管理用変数 ---
  final Map<String, BluetoothDevice> _devices = {};
  @override
  List<String> get connectedDevices => List.unmodifiable(_devices.keys);
  final Map<String, BluetoothCharacteristic> _characteristics = {};
  final Map<String, BleDeviceRole> _deviceRoles = {};
  StreamSubscription? _scanSub;

  // --- 定数: 振動モーター制御 (送信) ---
  static const String _svcVibratorUuid = "22222222-3333-4444-5555-666666666666";
  static const String _chrVibratorUuid = "22222222-3333-4444-5555-777777777777";
  static const int _vibratorMaxStrength = 255; // 振動強度の最大値
  final List<BluetoothCharacteristic> _vibratorCharacteristics = [];

  // --- StreamControllers ---
  final _accelDataController = StreamController<AccelData>.broadcast();
  @override
  Stream<AccelData> get accelDataStream => _accelDataController.stream;

  final _connectedDevicesController =
      StreamController<List<String>>.broadcast();
  @override
  Stream<List<String>> get connectedDevicesStream =>
      _connectedDevicesController.stream;

  final _connectedRolesController =
      StreamController<Set<BleDeviceRole>>.broadcast();
  @override
  Stream<Set<BleDeviceRole>> get connectedRolesStream =>
      _connectedRolesController.stream;
  @override
  Set<BleDeviceRole> get connectedRoles => _deviceRoles.values.toSet();

  // --- 内部メソッド: Bluetoothアダプターがオンになるまで待機 (iOS: CBManagerStateUnknown 対策) ---
  Future<void> _ensureAdapterOn() async {
    final adapterState = await FlutterBluePlus.adapterState
        .firstWhere(
          (s) =>
              s == BluetoothAdapterState.on || s == BluetoothAdapterState.off,
        )
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => FlutterBluePlus.adapterStateNow,
        );

    if (adapterState != BluetoothAdapterState.on) {
      _printLog("スキャン不可: Bluetoothがオフです");
      throw Exception("Bluetoothがオフです。設定からBluetoothをオンにしてください。");
    }
  }

  @override
  Future<void> scanAndConnect() async {
    // 既存のスキャンリスナーがあればキャンセル（重複防止）
    await _scanSub?.cancel();

    await _ensureAdapterOn();

    _printLog("スキャン開始...");

    try {
      // Android等での安定性のため、continuousUpdatesをtrueにすることを推奨
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        continuousUpdates: true, // 重複して発見通知を受け取る設定
      );
    } catch (e) {
      _printLog("スキャン開始エラー: $e");
      rethrow;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        final id = r.device.remoteId.str;
        final name = r.device.platformName;
        final advertisementData = r.advertisementData.advName;

        // 既に接続済みのデバイスは無視
        if (_devices.containsKey(id)) {
          continue;
        }

        // UUIDチェック
        bool hasTargetUuid = r.advertisementData.serviceUuids.any((guid) {
          String g = guid.toString().toLowerCase();
          return g == _serviceUuid.toLowerCase() ||
              g == _svcVibratorUuid.toLowerCase();
        });

        // 名前チェック
        bool isTargetName =
            name == _targetDeviceName ||
            name.startsWith(_targetDeviceName) ||
            advertisementData == _targetDeviceName ||
            advertisementData.startsWith(_targetDeviceName);

        // print("[BLE] 発見: $name / $advertisementData / $hasTargetUuid"); // デバッグ用ログ

        if (hasTargetUuid || isTargetName) {
          _printLog("発見: $name ($id) -> 接続のためスキャンを一時停止");

          // 【重要】接続前に必ずスキャンを止める！
          // これをしないと接続が不安定になり、次のデバイスも見つからなくなります
          await _scanSub?.cancel(); // リスナー解除
          await FlutterBluePlus.stopScan(); // ハードウェアスキャン停止

          // 接続処理（完了するまで待機）
          await _connectToDevice(r.device);

          // _printLog("1秒待機してから次のデバイスを探します...");
          // 【追加】ここです！休憩を入れます
          // await Future.delayed(const Duration(seconds: 1));

          // 接続処理が終わったら（成功しても失敗しても）、
          // 次のデバイスを探すために自分自身を呼び出してスキャンを再開
          // _printLog("次のデバイスを探すためスキャン再開...");
          if (_devices.length >= 2) return; // 最大2台まで接続
          scanAndConnect();

          debugPrint("再接続");

          // このループ処理はここで終了
          return;
        }
      }
    });
  }

  @override
  Future<void> connectDevice(BleDeviceRole role) async {
    if (_deviceRoles.containsValue(role)) return;

    // 既存のスキャンリスナーがあればキャンセル（重複防止）
    await _scanSub?.cancel();

    await _ensureAdapterOn();

    _printLog("${role.deviceName} のスキャン開始...");

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        continuousUpdates: true,
      );
    } catch (e) {
      _printLog("スキャン開始エラー: $e");
      rethrow;
    }

    final completer = Completer<void>();

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        final id = r.device.remoteId.str;
        if (_devices.containsKey(id)) continue;

        final name = r.device.platformName;
        final advertisementData = r.advertisementData.advName;

        final isTargetName =
            name == role.deviceName ||
            name.startsWith(role.deviceName) ||
            advertisementData == role.deviceName ||
            advertisementData.startsWith(role.deviceName);

        if (isTargetName) {
          _printLog("発見: $name ($id) -> 接続のためスキャンを一時停止");

          await _scanSub?.cancel();
          await FlutterBluePlus.stopScan();

          await _connectToDevice(r.device, role: role);

          if (!completer.isCompleted) completer.complete();
          return;
        }
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      await _scanSub?.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      _printLog("${role.deviceName} が見つかりませんでした");
      throw Exception("${role.deviceName} が見つかりませんでした");
    }

    if (!_deviceRoles.containsValue(role)) {
      throw Exception("${role.deviceName} への接続に失敗しました");
    }
  }

  @override
  Future<void> disconnectDevice(BleDeviceRole role) async {
    String? targetId;
    for (final entry in _deviceRoles.entries) {
      if (entry.value == role) {
        targetId = entry.key;
        break;
      }
    }

    if (targetId == null) return;

    final device = _devices[targetId];
    if (device != null) {
      _vibratorCharacteristics.removeWhere(
        (c) => c.remoteId == device.remoteId,
      );
      try {
        await device.disconnect();
      } catch (_) {}
    }

    _devices.remove(targetId);
    _characteristics.remove(targetId);
    _deviceRoles.remove(targetId);
    _updateConnectedList();
    _updateConnectedRoles();
    _printLog("${role.deviceName} を切断しました");
  }

  // --- 内部メソッド: デバイスへの接続処理 ---
  Future<void> _connectToDevice(
    BluetoothDevice device, {
    BleDeviceRole? role,
  }) async {
    String id = device.remoteId.str;
    String name = device.platformName;

    try {
      // autoConnect: false で即時接続
      await device.connect(license: License.free, autoConnect: false);

      _devices[id] = device;
      if (role != null) {
        _deviceRoles[id] = role;
        _updateConnectedRoles();
      }
      _updateConnectedList();
      _printLog("接続成功: $name");

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var c in service.characteristics) {
          final charUuid = c.uuid.toString().toLowerCase();
          if (charUuid == _charUuid.toLowerCase()) {
            _characteristics[id] = c;

            await c.setNotifyValue(true);
            c.lastValueStream.listen((value) {
              _parseAndNotify(id, value);
            });

            _printLog("通信経路確保: $name");
          }

          if (charUuid == _chrVibratorUuid.toLowerCase()) {
            _vibratorCharacteristics.add(c);
            _printLog("振動モーター(送信)経路確保: $name");
          }
        }
      }
    } catch (e) {
      _printLog("接続エラー($name): $e");
      _devices.remove(id);
      _characteristics.remove(id);
      if (_deviceRoles.remove(id) != null) {
        _updateConnectedRoles();
      }
      _updateConnectedList();

      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  // --- 内部メソッド: データ解析 (12byte: 3 floats x, y, z) ---
  void _parseAndNotify(String deviceId, List<int> rawData) {
    if (rawData.length < 12) return;

    final byteData = ByteData.sublistView(Uint8List.fromList(rawData));
    final double ax = byteData.getFloat32(0, Endian.little);
    final double ay = byteData.getFloat32(4, Endian.little);
    final double az = byteData.getFloat32(8, Endian.little);

    _accelDataController.add(
      AccelData(deviceId: deviceId, x: ax, y: ay, z: az),
    );
  }

  @override
  Future<void> sendVibration(int strength) async {
    if (_vibratorCharacteristics.isEmpty) {
      _printLog("送信不可: 振動モーター制御用の接続が見つかりません");
      return;
    }

    final clamped = strength.clamp(0, _vibratorMaxStrength);
    for (final c in _vibratorCharacteristics) {
      try {
        await c.write([clamped], withoutResponse: true);
        _printLog("振動モーター送信: 強度 $clamped");
      } catch (e) {
        _printLog("送信エラー: $e");
      }
    }
  }

  @override
  Future<void> sendVibrationToRole(BleDeviceRole role, int strength) async {
    final deviceId = _deviceRoles.entries
        .where((e) => e.value == role)
        .map((e) => e.key)
        .firstOrNull;
    if (deviceId == null) {
      _printLog("送信不可: ${role.deviceName} は接続されていません");
      return;
    }

    final device = _devices[deviceId];
    if (device == null) return;

    final characteristic = _vibratorCharacteristics
        .where((c) => c.remoteId == device.remoteId)
        .firstOrNull;
    if (characteristic == null) {
      _printLog("送信不可: ${role.deviceName} の振動モーター制御用の接続が見つかりません");
      return;
    }

    final clamped = strength.clamp(0, _vibratorMaxStrength);
    try {
      await characteristic.write([clamped], withoutResponse: true);
      _printLog("振動モーター送信(${role.deviceName}): 強度 $clamped");
    } catch (e) {
      _printLog("送信エラー(${role.deviceName}): $e");
    }
  }

  @override
  Future<void> disconnectAll() async {
    await _scanSub?.cancel();
    // スキャン停止も確実に行う
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    final devicesCopy = Map<String, BluetoothDevice>.from(_devices);

    for (var device in devicesCopy.values) {
      await device.disconnect();
    }

    _devices.clear();
    _characteristics.clear();
    _vibratorCharacteristics.clear();
    _deviceRoles.clear();
    _updateConnectedList();
    _updateConnectedRoles();
    _printLog("全切断しました");
  }

  void _updateConnectedList() {
    _connectedDevicesController.add(_devices.keys.toList());
  }

  void _updateConnectedRoles() {
    _connectedRolesController.add(_deviceRoles.values.toSet());
  }

  void _printLog(String text) {
    debugPrint("[BLE] $text");
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _accelDataController.close();
    _connectedDevicesController.close();
    _connectedRolesController.close();
  }
}
