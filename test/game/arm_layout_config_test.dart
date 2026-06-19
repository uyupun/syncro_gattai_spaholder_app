import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/game/arm_layout_config.dart';
import 'package:syncro_gattai_spaholder_app/game/part_config.dart';
import 'package:syncro_gattai_spaholder_app/interfaces/json_exportable.dart';

void main() {
  group('ArmLayoutConfig', () {
    test('デフォルト値が正しい', () {
      final config = ArmLayoutConfig();
      expect(config.upperArm.positionX, -7);
      expect(config.upperArm.positionY, -2.54);
      expect(config.upperArm.sizeX, 4);
      expect(config.upperArm.sizeY, 8);
      expect(config.foreArm.positionX, -1.84);
      expect(config.foreArm.sizeX, 4);
      expect(config.shoulder.positionX, -12);
      expect(config.shoulder.sizeX, 8);
      expect(config.shoulderJoint.anchorAX, 5);
      expect(config.shoulderJoint.anchorAY, 0);
      expect(config.shoulderJoint.anchorBX, 0);
      expect(config.elbowJoint.anchorAX, 5.16);
      expect(config.elbowJoint.anchorBY, 0);
      expect(config.tipOffsetX, 5.81);
      expect(config.tipOffsetY, -2.10);
      expect(config.armTipLocalY, -2.10);
      expect(config.imageRenderWidth, 20.0);
      expect(config.imageRenderHeight, 14.14);
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
      expect(config.upperArm.positionX, -5.0);
      expect(config.foreArm.sizeY, 7.0);
      expect(config.shoulder.positionX, -8.0);
      expect(config.shoulderJoint.anchorAX, 4.0);
      expect(config.elbowJoint.anchorBY, -2.5);
      expect(config.tipOffsetX, 1.0);
      expect(config.armTipLocalY, 4.0);
    });

    test('fromJsonで欠損フィールドはデフォルト値', () {
      final config = ArmLayoutConfig.fromJson({});
      expect(config.upperArm.positionX, -7);
      expect(config.tipOffsetY, -2.10);
      expect(config.armTipLocalY, -2.10);
      expect(config.imageRenderWidth, 20.0);
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = ArmLayoutConfig();
      final newUpperArm = PartConfig(
        positionX: 99,
        positionY: 99,
        sizeX: 99,
        sizeY: 99,
      );
      final modified = original.copyWith(upperArm: newUpperArm);

      expect(modified.upperArm.positionX, 99);
      expect(modified.foreArm.positionX, original.foreArm.positionX);
      expect(modified.shoulder.positionX, original.shoulder.positionX);
    });

    test('toJson/fromJsonラウンドトリップで値が保持される', () {
      final original = ArmLayoutConfig();
      final json = original.toJson();
      final restored = ArmLayoutConfig.fromJson(json);

      expect(restored.upperArm.positionX, original.upperArm.positionX);
      expect(restored.foreArm.sizeY, original.foreArm.sizeY);
      expect(restored.shoulderJoint.anchorAX, original.shoulderJoint.anchorAX);
      expect(restored.elbowJoint.anchorBY, original.elbowJoint.anchorBY);
      expect(restored.tipOffsetX, original.tipOffsetX);
      expect(restored.armTipLocalY, original.armTipLocalY);
    });

    test('JsonExportableを実装している', () {
      final config = ArmLayoutConfig();
      expect(config, isA<JsonExportable>());
    });
  });
}
