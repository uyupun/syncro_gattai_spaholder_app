import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/hp_bar_config.dart';
import 'package:spajam2025_app/interfaces/json_exportable.dart';

void main() {
  group('HpBarConfig', () {
    test('デフォルト値が正しい', () {
      final config = HpBarConfig();
      expect(config.maxHp, 100);
      expect(config.barPositionX, 0);
      expect(config.barPositionY, 0);
      expect(config.barSizeX, 100);
      expect(config.barSizeY, 10);
    });

    test('コンストラクタで全値を指定できる', () {
      final config = HpBarConfig(
        maxHp: 200,
        barPositionX: 10,
        barPositionY: 20,
        barSizeX: 150,
        barSizeY: 15,
      );
      expect(config.maxHp, 200);
      expect(config.barPositionX, 10);
      expect(config.barPositionY, 20);
      expect(config.barSizeX, 150);
      expect(config.barSizeY, 15);
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = HpBarConfig();
      final modified = original.copyWith(maxHp: 50);
      expect(modified.maxHp, 50);
      expect(modified.barSizeX, 100);
    });

    test('toJson/fromJsonラウンドトリップで値が保持される', () {
      final original = HpBarConfig(
        maxHp: 200,
        barPositionX: 5,
        barPositionY: 10,
        barSizeX: 120,
        barSizeY: 12,
      );
      final json = original.toJson();
      final restored = HpBarConfig.fromJson(json);

      expect(restored.maxHp, original.maxHp);
      expect(restored.barPositionX, original.barPositionX);
      expect(restored.barPositionY, original.barPositionY);
      expect(restored.barSizeX, original.barSizeX);
      expect(restored.barSizeY, original.barSizeY);
    });

    test('fromJsonで欠損フィールドはデフォルト値', () {
      final config = HpBarConfig.fromJson({});
      expect(config.maxHp, 100);
      expect(config.barSizeX, 100);
    });

    test('JsonExportableを実装している', () {
      final config = HpBarConfig();
      expect(config, isA<JsonExportable>());
    });

    group('loadFromAsset', () {
      TestWidgetsFlutterBinding.ensureInitialized();

      tearDown(() {
        rootBundle.evict('assets/hp_bar_config.json');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('JSONファイルからplayer/enemy両方読み込める', () async {
        final testData = {
          'player': {'maxHp': 200.0, 'barSizeX': 80.0},
          'enemy': {'maxHp': 250.0, 'barSizeX': 60.0},
        };
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
              final key = utf8.decode(message!.buffer.asUint8List());
              if (key == 'assets/hp_bar_config.json') {
                return ByteData.sublistView(
                  utf8.encoder.convert(jsonEncode(testData)),
                );
              }
              return null;
            });

        final configs = await HpBarConfig.loadFromAsset();
        expect(configs.player.maxHp, 200.0);
        expect(configs.player.barSizeX, 80.0);
        expect(configs.enemy.maxHp, 250.0);
        expect(configs.enemy.barSizeX, 60.0);
        expect(configs.enemy.barSizeY, 10);
      });
    });
  });
}
