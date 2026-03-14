import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/arm_layout_config.dart';

void expectFloat32(double actual, double expected) {
  expect(actual, Float32List.fromList([expected])[0]);
}

void main() {
  group('ArmLayoutConfig', () {
    test('デフォルト値が正しい', () {
      final config = ArmLayoutConfig();
      expect(config.upperArmPosition.x, -10);
      expectFloat32(config.upperArmPosition.y, -4);
      expectFloat32(config.upperArmSize.x, 4.35);
      expect(config.upperArmSize.y, 8);
      expectFloat32(config.foreArmPosition.x, -8.5);
      expectFloat32(config.foreArmSize.x, 4.85);
      expect(config.shoulderPosition.x, -12);
      expect(config.shoulderSize.x, 16);
      expect(config.shoulderAnchorA.x, 6);
      expectFloat32(config.shoulderAnchorA.y, -4.5);
      expect(config.shoulderAnchorB.x, 0);
      expectFloat32(config.elbowAnchorA.x, 1.75);
      expectFloat32(config.elbowAnchorB.y, -3.5);
      expect(config.tipOffset.x, 2.0);
      expectFloat32(config.tipOffset.y, 3.5);
      expectFloat32(config.armTipLocalY, 3.5);
    });

    test('fromJsonで全フィールド正しく読込', () {
      final json = {
        'upperArm': {
          'position': {'x': -5.0, 'y': -2.0},
          'size': {'x': 3.0, 'y': 6.0},
        },
        'foreArm': {
          'position': {'x': -4.0, 'y': 1.0},
          'size': {'x': 3.5, 'y': 7.0},
        },
        'shoulder': {
          'position': {'x': -8.0, 'y': 0.0},
          'size': {'x': 12.0, 'y': 12.0},
        },
        'joints': {
          'shoulder': {
            'anchorA': {'x': 4.0, 'y': -3.0},
            'anchorB': {'x': 1.0, 'y': -2.0},
          },
          'elbow': {
            'anchorA': {'x': 2.0, 'y': 4.0},
            'anchorB': {'x': -0.5, 'y': -2.5},
          },
        },
        'tipOffset': {'x': 1.0, 'y': 2.0},
        'armTipLocalY': 4.0,
      };

      final config = ArmLayoutConfig.fromJson(json);
      expectFloat32(config.upperArmPosition.x, -5.0);
      expectFloat32(config.foreArmSize.y, 7.0);
      expectFloat32(config.shoulderPosition.x, -8.0);
      expectFloat32(config.shoulderAnchorA.x, 4.0);
      expectFloat32(config.elbowAnchorB.y, -2.5);
      expectFloat32(config.tipOffset.x, 1.0);
      expectFloat32(config.armTipLocalY, 4.0);
    });

    test('fromJsonで欠損フィールドはデフォルト値', () {
      final config = ArmLayoutConfig.fromJson({});
      expect(config.upperArmPosition.x, -10);
      expectFloat32(config.tipOffset.y, 3.5);
      expectFloat32(config.armTipLocalY, 3.5);
    });
  });
}
