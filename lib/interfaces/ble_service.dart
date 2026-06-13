import '../models/accel_data.dart';
import '../models/ble_device_role.dart';

abstract interface class BleService {
  Future<void> scanAndConnect();
  Future<void> disconnectAll();
  Stream<AccelData> get accelDataStream;
  Stream<List<String>> get connectedDevicesStream;
  List<String> get connectedDevices;
  Future<void> sendVibration(int strength);
  void dispose();

  /// 指定したロールのデバイスをスキャンして接続する
  Future<void> connectDevice(BleDeviceRole role);

  /// 指定したロールのデバイスを切断する
  Future<void> disconnectDevice(BleDeviceRole role);

  /// 接続済みロールの集合を通知するStream
  Stream<Set<BleDeviceRole>> get connectedRolesStream;

  /// 現在接続済みのロールの集合
  Set<BleDeviceRole> get connectedRoles;
}
