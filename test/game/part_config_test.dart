import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/part_config.dart';

void main() {
  group('PartConfig', () {
    test('コンストラクタで位置とサイズを設定できる', () {
      final config = PartConfig(
        positionX: -10,
        positionY: -4,
        sizeX: 4.35,
        sizeY: 8,
      );
      expect(config.positionX, -10);
      expect(config.positionY, -4);
      expect(config.sizeX, 4.35);
      expect(config.sizeY, 8);
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = PartConfig(
        positionX: 1,
        positionY: 2,
        sizeX: 3,
        sizeY: 4,
      );
      final modified = original.copyWith(positionX: 99);

      expect(modified.positionX, 99);
      expect(modified.positionY, 2);
      expect(modified.sizeX, 3);
      expect(modified.sizeY, 4);
    });

    test('toJson/fromJsonラウンドトリップで値が保持される', () {
      final original = PartConfig(
        positionX: -8.5,
        positionY: 1.5,
        sizeX: 4.85,
        sizeY: 8,
      );
      final json = original.toJson();
      final restored = PartConfig.fromJson(json);

      expect(restored.positionX, original.positionX);
      expect(restored.positionY, original.positionY);
      expect(restored.sizeX, original.sizeX);
      expect(restored.sizeY, original.sizeY);
    });

    test('fromJsonで必要なキーが欠損した場合エラー', () {
      expect(
        () => PartConfig.fromJson({'position': {}}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
