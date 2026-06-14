import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/game/actions_config.dart';

void main() {
  group('ActionConfig', () {
    test('デフォルト値が正しい', () {
      final config = ActionConfig();
      expect(config.nameJa, '');
      expect(config.power, 0);
    });

    test('fromJsonで正しく読込', () {
      final config = ActionConfig.fromJson({'nameJa': 'シンクロアタック', 'power': 10});
      expect(config.nameJa, 'シンクロアタック');
      expect(config.power, 10);
    });

    test('fromJsonで欠損フィールドはデフォルト値', () {
      final config = ActionConfig.fromJson({});
      expect(config.nameJa, '');
      expect(config.power, 0);
    });
  });

  group('ActionsConfig', () {
    test('デフォルト値が正しい', () {
      final config = ActionsConfig();
      expect(config.synchroCharge.nameJa, 'シンクロ\nチャージ');
      expect(config.synchroCharge.power, 0);
      expect(config.synchroAttack.nameJa, 'シンクロ\nアタック');
      expect(config.synchroAttack.power, 10);
      expect(config.synchroGuard.nameJa, 'シンクロ\nガード');
      expect(config.synchroGuard.power, 25);
      expect(config.yugarockRoll.nameJa, 'ローリングアタック');
      expect(config.yugarockRoll.power, 10);
      expect(config.yugarockLandfill.nameJa, '土砂崩し');
      expect(config.yugarockLandfill.power, 20);
      expect(config.asyncStream.nameJa, 'アシンクストリーム');
      expect(config.asyncStream.power, 20);
      expect(config.asyncVacuum.nameJa, 'アシンクバキューム');
      expect(config.asyncVacuum.power, 30);
      expect(config.asyncPendulum.nameJa, 'アシンクペンデュラム');
      expect(config.asyncPendulum.power, 0);
    });

    test('yugarockActionsにrollとlandfillが含まれる', () {
      final config = ActionsConfig();
      expect(config.yugarockActions, [
        config.yugarockRoll,
        config.yugarockLandfill,
      ]);
    });

    test('asyncronActionsにasyncStreamとasyncVacuumが含まれる', () {
      final config = ActionsConfig();
      expect(config.asyncronActions, [config.asyncStream, config.asyncVacuum]);
    });

    test('fromJsonで正しく読込', () {
      final config = ActionsConfig.fromJson({
        'player': {
          'actions': {
            'synchroCharge': {'nameJa': 'チャージ', 'power': 1},
            'synchroAttack': {'nameJa': 'アタック', 'power': 2},
            'synchroGuard': {'nameJa': 'ガード', 'power': 3},
          },
        },
        'enemies': {
          'yugarock': {
            'actions': {
              'roll': {'nameJa': 'ロール', 'power': 4},
              'landfill': {'nameJa': '土砂', 'power': 5},
            },
          },
          'asyncron': {
            'actions': {
              'asyncStream': {'nameJa': 'ストリーム', 'power': 6},
              'asyncVacuum': {'nameJa': 'バキューム', 'power': 7},
              'asyncPendulum': {'nameJa': 'ペンデュラム', 'power': 8},
            },
          },
        },
      });

      expect(config.synchroCharge.nameJa, 'チャージ');
      expect(config.synchroCharge.power, 1);
      expect(config.synchroAttack.nameJa, 'アタック');
      expect(config.synchroAttack.power, 2);
      expect(config.synchroGuard.nameJa, 'ガード');
      expect(config.synchroGuard.power, 3);
      expect(config.yugarockRoll.nameJa, 'ロール');
      expect(config.yugarockRoll.power, 4);
      expect(config.yugarockLandfill.nameJa, '土砂');
      expect(config.yugarockLandfill.power, 5);
      expect(config.asyncStream.nameJa, 'ストリーム');
      expect(config.asyncStream.power, 6);
      expect(config.asyncVacuum.nameJa, 'バキューム');
      expect(config.asyncVacuum.power, 7);
      expect(config.asyncPendulum.nameJa, 'ペンデュラム');
      expect(config.asyncPendulum.power, 8);
    });

    test('fromJsonでactions自体が欠損している場合は各ActionConfigも空のデフォルト値になる', () {
      final config = ActionsConfig.fromJson({});
      expect(config.synchroAttack.nameJa, '');
      expect(config.synchroAttack.power, 0);
      expect(config.yugarockRoll.nameJa, '');
      expect(config.yugarockLandfill.nameJa, '');
      expect(config.asyncStream.nameJa, '');
      expect(config.asyncVacuum.nameJa, '');
      expect(config.asyncPendulum.nameJa, '');
    });
  });
}
