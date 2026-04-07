import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/enemy_config.dart';
import 'package:spajam2025_app/interfaces/json_exportable.dart';

void main() {
  group('EnemyConfig', () {
    test('デフォルト値が正しい', () {
      final config = EnemyConfig();
      expect(config.spriteScale, 2.5);
    });

    test('fromJsonで正しく読込', () {
      final config = EnemyConfig.fromJson({'spriteScale': 3.0});
      expect(config.spriteScale, 3.0);
    });

    test('fromJsonで欠損フィールドはデフォルト値', () {
      final config = EnemyConfig.fromJson({});
      expect(config.spriteScale, 2.5);
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = EnemyConfig();
      final modified = original.copyWith(spriteScale: 5.0);
      expect(modified.spriteScale, 5.0);
    });

    test('copyWithで元のインスタンスは変更されない', () {
      final original = EnemyConfig();
      original.copyWith(spriteScale: 99.0);
      expect(original.spriteScale, 2.5);
    });

    test('toJson/fromJsonラウンドトリップで値が保持される', () {
      final original = EnemyConfig(spriteScale: 3.5);
      final json = original.toJson();
      final restored = EnemyConfig.fromJson(json);
      expect(restored.spriteScale, original.spriteScale);
    });

    test('JsonExportableを実装している', () {
      final config = EnemyConfig();
      expect(config, isA<JsonExportable>());
    });
  });
}
