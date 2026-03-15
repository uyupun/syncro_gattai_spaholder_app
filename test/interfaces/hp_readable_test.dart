import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/interfaces/hp_readable.dart';

class _TestHpReadable implements HpReadable {
  @override
  final double hp;
  @override
  final double maxHp;
  _TestHpReadable({required this.hp, required this.maxHp});
}

void main() {
  group('HpReadable', () {
    test('hp/maxHpを読み取れる', () {
      final readable = _TestHpReadable(hp: 50, maxHp: 100);
      expect(readable.hp, 50);
      expect(readable.maxHp, 100);
    });
  });
}
