import '../models/accel_data.dart';

abstract interface class BleService {
  Future<void> scanAndConnect();
  Future<void> disconnectAll();
  Stream<AccelData> get accelDataStream;
  Stream<List<String>> get connectedDevicesStream;
  List<String> get connectedDevices;
  Future<void> sendVibration(int strength);
  void dispose();
}
