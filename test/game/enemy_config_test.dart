import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/game/enemy_config.dart';
import 'package:syncro_gattai_spaholder_app/interfaces/json_exportable.dart';

void main() {
  group('EnemyConfig', () {
    test('デフォルト値が正しい', () {
      final config = EnemyConfig();
      expect(config.yugarockSpriteScale, 3.0);
      expect(config.asyncronSpriteScale, 2.5);
    });

    test('fromJsonで正しく読込', () {
      final config = EnemyConfig.fromJson({
        'yugarockSpriteScale': 4.0,
        'asyncronSpriteScale': 3.0,
      });
      expect(config.yugarockSpriteScale, 4.0);
      expect(config.asyncronSpriteScale, 3.0);
    });

    test('fromJsonで旧spriteScaleフィールドにフォールバック', () {
      final config = EnemyConfig.fromJson({'spriteScale': 3.5});
      expect(config.yugarockSpriteScale, 3.5);
      expect(config.asyncronSpriteScale, 3.5);
    });

    test('fromJsonで欠損フィールドはデフォルト値', () {
      final config = EnemyConfig.fromJson({});
      expect(config.yugarockSpriteScale, 3.0);
      expect(config.asyncronSpriteScale, 2.5);
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = EnemyConfig();
      final modified = original.copyWith(yugarockSpriteScale: 5.0);
      expect(modified.yugarockSpriteScale, 5.0);
      expect(modified.asyncronSpriteScale, original.asyncronSpriteScale);
    });

    test('copyWithで元のインスタンスは変更されない', () {
      final original = EnemyConfig();
      original.copyWith(yugarockSpriteScale: 99.0);
      expect(original.yugarockSpriteScale, 3.0);
    });

    test('toJson/fromJsonラウンドトリップで値が保持される', () {
      final original = EnemyConfig(
        yugarockSpriteScale: 3.5,
        asyncronSpriteScale: 2.8,
      );
      final json = original.toJson();
      final restored = EnemyConfig.fromJson(json);
      expect(restored.yugarockSpriteScale, original.yugarockSpriteScale);
      expect(restored.asyncronSpriteScale, original.asyncronSpriteScale);
    });

    test('JsonExportableを実装している', () {
      final config = EnemyConfig();
      expect(config, isA<JsonExportable>());
    });
  });
}
