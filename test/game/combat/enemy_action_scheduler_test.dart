import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/game/combat/enemy_action_scheduler.dart';

void main() {
  group('EnemyActionScheduler', () {
    test('最短間隔(5秒)未満では発動しない', () {
      final scheduler = EnemyActionScheduler(random: Random(1));

      var triggered = false;
      for (var i = 0; i < 49; i++) {
        if (scheduler.update(0.1)) {
          triggered = true;
        }
      }

      expect(triggered, false);
    });

    test('最長間隔(10秒)以内に必ず発動する', () {
      final scheduler = EnemyActionScheduler(random: Random(1));

      var triggered = false;
      for (var i = 0; i < 100; i++) {
        if (scheduler.update(0.1)) {
          triggered = true;
          break;
        }
      }

      expect(triggered, true);
    });

    test('発動後はタイマーがリセットされ、次の発動まで再度時間がかかる', () {
      final scheduler = EnemyActionScheduler(random: Random(1));

      // 必ず発動するまで進める
      while (!scheduler.update(0.1)) {}

      // リセット直後は発動しない
      expect(scheduler.update(0.1), false);
    });
  });
}
