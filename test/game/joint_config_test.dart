import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/joint_config.dart';

void main() {
  group('JointConfig', () {
    test('コンストラクタでアンカーA/Bを設定できる', () {
      final config = JointConfig(
        anchorAX: 6,
        anchorAY: -4.5,
        anchorBX: 0,
        anchorBY: -4,
      );
      expect(config.anchorAX, 6);
      expect(config.anchorAY, -4.5);
      expect(config.anchorBX, 0);
      expect(config.anchorBY, -4);
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = JointConfig(
        anchorAX: 1,
        anchorAY: 2,
        anchorBX: 3,
        anchorBY: 4,
      );
      final modified = original.copyWith(anchorBX: 99);

      expect(modified.anchorAX, 1);
      expect(modified.anchorAY, 2);
      expect(modified.anchorBX, 99);
      expect(modified.anchorBY, 4);
    });

    test('toJson/fromJsonラウンドトリップで値が保持される', () {
      final original = JointConfig(
        anchorAX: 1.75,
        anchorAY: 3,
        anchorBX: -1,
        anchorBY: -3.5,
      );
      final json = original.toJson();
      final restored = JointConfig.fromJson(json);

      expect(restored.anchorAX, original.anchorAX);
      expect(restored.anchorAY, original.anchorAY);
      expect(restored.anchorBX, original.anchorBX);
      expect(restored.anchorBY, original.anchorBY);
    });
  });
}
