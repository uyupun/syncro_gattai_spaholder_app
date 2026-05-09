class AccelData {
  final String deviceId;
  final double x;
  final double y;
  final double z;

  AccelData({
    required this.deviceId,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() => 'ID: $deviceId, X: $x, Y: $y, Z: $z';
}
