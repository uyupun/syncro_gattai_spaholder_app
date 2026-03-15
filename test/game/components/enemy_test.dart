import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/components/enemy.dart';
import 'package:spajam2025_app/interfaces/damageable.dart';
import 'package:spajam2025_app/interfaces/hp_readable.dart';

void main() {
  group('Enemy HP', () {
    test('HpReadable/Damageableを実装している', () {
      final enemy = Enemy(
        position: Vector2.zero(),
        radius: 5,
        spriteScale: 2.5,
        maxHp: 100,
      );
      expect(enemy, isA<HpReadable>());
      expect(enemy, isA<Damageable>());
    });

    test('初期HPがmaxHpと一致する', () {
      final enemy = Enemy(
        position: Vector2.zero(),
        radius: 5,
        spriteScale: 2.5,
        maxHp: 100,
      );
      expect(enemy.hp, 100);
      expect(enemy.maxHp, 100);
    });

    test('takeDamageでHPが減少する', () {
      final enemy = Enemy(
        position: Vector2.zero(),
        radius: 5,
        spriteScale: 2.5,
        maxHp: 100,
      );
      enemy.takeDamage(30);
      expect(enemy.hp, 70);
    });

    test('HPが0以下になる', () {
      final enemy = Enemy(
        position: Vector2.zero(),
        radius: 5,
        spriteScale: 2.5,
        maxHp: 50,
      );
      enemy.takeDamage(60);
      expect(enemy.hp, lessThanOrEqualTo(0));
    });
  });
}
