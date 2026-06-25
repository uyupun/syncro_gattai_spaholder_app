import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/game/combat/player_action_detector.dart';
import 'package:syncro_gattai_spaholder_app/models/accel_data.dart';

const _ids = ['a', 'b'];

AccelData _accel(String id, {double x = 0, double y = 0, double z = 0}) {
  return AccelData(deviceId: id, x: x, y: y, z: z);
}

Map<String, AccelData> _both({double x = 0, double y = 0, double z = 0}) {
  return {
    'a': _accel('a', x: x, y: y, z: z),
    'b': _accel('b', x: x, y: y, z: z),
  };
}

void main() {
  group('PlayerActionDetector', () {
    test('接続デバイスが2台未満の場合は何も検出しない', () {
      final detector = PlayerActionDetector();
      final result = detector.detect(_both(x: 5, y: 5, z: 5), ['a']);
      expect(result.type, PlayerActionType.none);
    });

    test('両デバイスのX軸がしきい値を超えるとattackを検出する', () {
      final detector = PlayerActionDetector();
      final result = detector.detect(_both(x: 1.0), _ids);
      expect(result.type, PlayerActionType.attack);
      expect(result.chargeLevel, 0);
    });

    test('片方のデバイスのみしきい値を超えた場合は検出しない', () {
      final detector = PlayerActionDetector();
      final data = {'a': _accel('a', x: 1.0), 'b': _accel('b', x: 0.0)};
      final result = detector.detect(data, _ids);
      expect(result.type, PlayerActionType.none);
    });

    test('しきい値を超え続けている間は再検出しない(エッジトリガー)', () {
      final detector = PlayerActionDetector();
      detector.detect(_both(x: 1.0), _ids);
      final result = detector.detect(_both(x: 1.0), _ids);
      expect(result.type, PlayerActionType.none);
    });

    test('Y軸(絶対値)がしきい値を超えるとguardを検出する', () {
      final detector = PlayerActionDetector();
      final result = detector.detect(_both(y: -1.2), _ids);
      expect(result.type, PlayerActionType.guard);
    });

    test('guard中はisGuardingがtrueになる', () {
      final detector = PlayerActionDetector();
      detector.detect(_both(y: 1.2), _ids);
      expect(detector.isGuarding, true);

      detector.detect(_both(y: 0), _ids);
      expect(detector.isGuarding, false);
    });

    test('複数軸が同時に閾値を超えた場合、値 - 閾値の差分が最大の技を発動する', () {
      // X: 1.0 - 0.77 = 0.23, Y: 1.1 - 0.95 = 0.15 → Xが最大 → attack
      final detector1 = PlayerActionDetector();
      final result1 = detector1.detect(_both(x: 1.0, y: 1.1), _ids);
      expect(result1.type, PlayerActionType.attack);

      // Y: 1.5 - 0.95 = 0.55, X: 0.8 - 0.77 = 0.03 → Yが最大 → guard
      final detector2 = PlayerActionDetector();
      final result2 = detector2.detect(_both(x: 0.8, y: 1.5), _ids);
      expect(result2.type, PlayerActionType.guard);

      // Z: 2.0 - 1.65 = 0.35, X: 0.78 - 0.77 = 0.01 → Zが最大 → charge
      final detector3 = PlayerActionDetector();
      final result3 = detector3.detect(_both(x: 0.78, z: 2.0), _ids);
      expect(result3.type, PlayerActionType.charge);
    });

    test('Z軸がしきい値を超えるとchargeを検出し、チャージレベルが増加する', () {
      final detector = PlayerActionDetector();

      final result1 = detector.detect(_both(z: 2.0), _ids);
      expect(result1.type, PlayerActionType.charge);
      expect(result1.chargeLevel, 1);

      // エッジトリガーのため、一度しきい値未満に戻す
      detector.detect(_both(z: 0), _ids);
      final result2 = detector.detect(_both(z: 2.0), _ids);
      expect(result2.type, PlayerActionType.charge);
      expect(result2.chargeLevel, 2);
    });

    test('チャージレベルは最大値で増加が止まる', () {
      final detector = PlayerActionDetector();

      for (var i = 0; i < PlayerActionDetector.maxChargeLevel; i++) {
        detector.detect(_both(z: 2.0), _ids);
        detector.detect(_both(z: 0), _ids);
      }

      final result = detector.detect(_both(z: 2.0), _ids);
      expect(result.type, PlayerActionType.none);
      expect(result.chargeLevel, PlayerActionDetector.maxChargeLevel);
    });

    test('attack発動時は発動時点のチャージレベルを返し、その後0にリセットされる', () {
      final detector = PlayerActionDetector();

      detector.detect(_both(z: 2.0), _ids);
      detector.detect(_both(z: 0), _ids);
      detector.detect(_both(z: 2.0), _ids);
      detector.detect(_both(z: 0), _ids);

      final attackResult = detector.detect(_both(x: 1.0), _ids);
      expect(attackResult.type, PlayerActionType.attack);
      expect(attackResult.chargeLevel, 2);

      detector.detect(_both(x: 0), _ids);
      final chargeResult = detector.detect(_both(z: 2.0), _ids);
      expect(chargeResult.chargeLevel, 1);
    });
  });
}
