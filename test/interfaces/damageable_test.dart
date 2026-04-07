import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/interfaces/damageable.dart';

class _TestDamageable implements Damageable {
  double hp = 100;
  @override
  void takeDamage(double amount) {
    hp -= amount;
  }
}

void main() {
  group('Damageable', () {
    test('takeDamageでダメージを受ける', () {
      final target = _TestDamageable();
      target.takeDamage(30);
      expect(target.hp, 70);
    });

    test('複数回ダメージを受けられる', () {
      final target = _TestDamageable();
      target.takeDamage(25);
      target.takeDamage(25);
      expect(target.hp, 50);
    });
  });
}
