import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'interfaces/ble_service.dart';
import 'models/accel_data.dart';

class BleManager implements BleService {
  BleManager();

  // --- 定数 ---
  static const String _targetDeviceName = "uyupun-drill";
  static const String _serviceUuid = "11111111-2222-3333-4444-555555555555";
  static const String _charUuid = "11111111-2222-3333-4444-666666666666";

  // --- 管理用変数 ---
  final Map<String, BluetoothDevice> _devices = {};
  @override
  List<String> get connectedDevices => List.unmodifiable(_devices.keys);
  final Map<String, BluetoothCharacteristic> _characteristics = {};
  StreamSubscription? _scanSub;

  // --- 定数: ポンプ制御 (送信)  ---
  static const String _svcPumpUuid = "22222222-3333-4444-5555-666666666666";
  static const String _chrPumpUuid = "22222222-3333-4444-5555-777777777777";
  final List<BluetoothCharacteristic> _pumpCharacteristics = [];

  // --- StreamControllers ---
  final _accelDataController = StreamController<AccelData>.broadcast();
  @override
  Stream<AccelData> get accelDataStream => _accelDataController.stream;

  final _connectedDevicesController =
      StreamController<List<String>>.broadcast();
  @override
  Stream<List<String>> get connectedDevicesStream =>
      _connectedDevicesController.stream;

  @override
  Future<void> scanAndConnect() async {
    // 既存のスキャンリスナーがあればキャンセル（重複防止）
    await _scanSub?.cancel();

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
              g == _svcPumpUuid.toLowerCase();
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

  // --- 内部メソッド: デバイスへの接続処理 ---
  Future<void> _connectToDevice(BluetoothDevice device) async {
    String id = device.remoteId.str;
    String name = device.platformName;

    try {
      // autoConnect: false で即時接続
      await device.connect(license: License.free, autoConnect: false);

      _devices[id] = device;
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

          if (charUuid == _chrPumpUuid.toLowerCase()) {
            // ポンプ用のCharacteristicをリストに追加
            _pumpCharacteristics.add(c);
            _printLog("ポンプ(送信)経路確保: $name");
          }
        }
      }
    } catch (e) {
      _printLog("接続エラー($name): $e");
      _devices.remove(id);
      _characteristics.remove(id);
      _updateConnectedList();

      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  // --- 内部メソッド: データ解析 (4byte float) ---
  void _parseAndNotify(String deviceId, List<int> rawData) {
    if (rawData.length < 4) return;

    final byteData = ByteData.sublistView(Uint8List.fromList(rawData));
    final double val = byteData.getFloat32(0, Endian.little);

    _accelDataController.add(AccelData(deviceId: deviceId, value: val));
  }

  @override
  Future<void> sendBool(bool value) async {
    if (_pumpCharacteristics.isEmpty) {
      _printLog("送信不可: ポンプ制御用の接続が見つかりません");
      return;
    }

    // 全てのポンプCharacteristicに送信
    for (final c in _pumpCharacteristics) {
      try {
        await c.write([value ? 1 : 0], withoutResponse: true);
        _printLog("ポンプ送信: ${value ? 'ON' : 'OFF'}");
      } catch (e) {
        _printLog("送信エラー: $e");
      }
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
    _pumpCharacteristics.clear();
    _updateConnectedList();
    _printLog("全切断しました");
  }

  void _updateConnectedList() {
    _connectedDevicesController.add(_devices.keys.toList());
  }

  void _printLog(String text) {
    debugPrint("[BLE] $text");
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _accelDataController.close();
    _connectedDevicesController.close();
  }
}
