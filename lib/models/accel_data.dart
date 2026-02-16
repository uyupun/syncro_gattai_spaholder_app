class AccelData {
  final String deviceId;
  final double value;

  AccelData({required this.deviceId, required this.value});

  @override
  String toString() => 'ID: $deviceId, Val: $value';
}
