import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/models/accel_data.dart';

void main() {
  group('AccelData', () {
    test('プロパティが正しく設定される', () {
      final data = AccelData(deviceId: 'device-1', value: 0.5);

      expect(data.deviceId, 'device-1');
      expect(data.value, 0.5);
    });

    test('toStringが期待通りのフォーマット', () {
      final data = AccelData(deviceId: 'device-1', value: 1.23);

      expect(data.toString(), 'ID: device-1, Val: 1.23');
    });

    test('負の値を保持できる', () {
      final data = AccelData(deviceId: 'device-2', value: -0.3);

      expect(data.value, -0.3);
    });
  });
}
