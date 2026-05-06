import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/models/accel_data.dart';

void main() {
  group('AccelData', () {
    test('プロパティが正しく設定される', () {
      final data = AccelData(deviceId: 'device-1', x: 0.1, y: 0.2, z: 0.9);

      expect(data.deviceId, 'device-1');
      expect(data.x, 0.1);
      expect(data.y, 0.2);
      expect(data.z, 0.9);
    });

    test('toStringが期待通りのフォーマット', () {
      final data = AccelData(deviceId: 'device-1', x: 1.23, y: -0.5, z: 0.8);

      expect(data.toString(), 'ID: device-1, X: 1.23, Y: -0.5, Z: 0.8');
    });

    test('負の値を保持できる', () {
      final data = AccelData(deviceId: 'device-2', x: -0.3, y: -0.1, z: 0.95);

      expect(data.x, -0.3);
      expect(data.y, -0.1);
      expect(data.z, 0.95);
    });
  });
}
