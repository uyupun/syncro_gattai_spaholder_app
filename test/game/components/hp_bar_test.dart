import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/components/hp_bar.dart';
import 'package:spajam2025_app/interfaces/hp_readable.dart';

class _MockHpReadable implements HpReadable {
  @override
  double hp;
  @override
  final double maxHp;
  _MockHpReadable({required this.hp, required this.maxHp});
}

void main() {
  group('HpBar', () {
    test('HpReadableを参照して生成できる', () {
      final hpSource = _MockHpReadable(hp: 100, maxHp: 100);
      final hpBar = HpBar(hpReadable: hpSource, barWidth: 100, barHeight: 10);
      expect(hpBar, isNotNull);
      expect(hpBar.hpReadable, same(hpSource));
    });

    test('HP比率を正しく計算する', () {
      final hpSource = _MockHpReadable(hp: 50, maxHp: 100);
      final hpBar = HpBar(hpReadable: hpSource, barWidth: 100, barHeight: 10);
      expect(hpBar.hpRatio, 0.5);
    });

    test('HP0のとき比率が0になる', () {
      final hpSource = _MockHpReadable(hp: 0, maxHp: 100);
      final hpBar = HpBar(hpReadable: hpSource, barWidth: 100, barHeight: 10);
      expect(hpBar.hpRatio, 0.0);
    });
  });
}
