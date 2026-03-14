import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/enemy_config.dart';

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
  });
}
