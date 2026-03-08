import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/game/game_config.dart';

void main() {
  group('GameConfig', () {
    test('デフォルト値が既存定数と一致', () {
      final config = GameConfig();
      expect(config.gravity.x, 0);
      expect(config.gravity.y, 15);
      expect(config.zoom, 20.0);
      expect(config.shoulderTorque, 8000.0);
      expect(config.elbowTorque, 15000.0);
      expect(config.armLength, 14.0);
      expect(config.shoulderPos.x, -10);
      expect(config.shoulderPos.y, -7);
      expect(config.tipRadius, 0.8);
      expect(config.enemyRadius, 6.0);
      expect(config.straighteningDuration, 0.2);
      expect(config.randomChangeInterval, 0.3);
      expect(config.shoulderSpeedRange, 24.0);
      expect(config.elbowSpeedRange, 36.0);
    });

    test('defaultConfig でデフォルト値が返る', () {
      final config = GameConfig.defaultConfig();
      expect(config.zoom, 20.0);
      expect(config.gravity.y, 15);
    });

    test('fromJson で全フィールド正しく読込', () {
      final json = {
        'gravity': {'x': 1.0, 'y': 25.0},
        'zoom': 30.0,
        'shoulderTorque': 5000.0,
        'elbowTorque': 10000.0,
        'armLength': 20.0,
        'shoulderPos': {'x': -5.0, 'y': -3.0},
        'tipRadius': 1.5,
        'enemyRadius': 8.0,
        'straighteningDuration': 0.5,
        'randomChangeInterval': 0.6,
        'shoulderSpeedRange': 30.0,
        'elbowSpeedRange': 50.0,
      };

      final config = GameConfig.fromJson(json);
      expect(config.gravity.x, 1.0);
      expect(config.gravity.y, 25.0);
      expect(config.zoom, 30.0);
      expect(config.shoulderTorque, 5000.0);
      expect(config.elbowTorque, 10000.0);
      expect(config.armLength, 20.0);
      expect(config.shoulderPos.x, -5.0);
      expect(config.shoulderPos.y, -3.0);
      expect(config.tipRadius, 1.5);
      expect(config.enemyRadius, 8.0);
      expect(config.straighteningDuration, 0.5);
      expect(config.randomChangeInterval, 0.6);
      expect(config.shoulderSpeedRange, 30.0);
      expect(config.elbowSpeedRange, 50.0);
    });

    test('toJson 往復で値が保持される', () {
      final original = GameConfig(
        zoom: 35.0,
        shoulderTorque: 9000.0,
        elbowTorque: 12000.0,
      );

      final json = original.toJson();
      final restored = GameConfig.fromJson(json);

      expect(restored.gravity.x, original.gravity.x);
      expect(restored.gravity.y, original.gravity.y);
      expect(restored.zoom, original.zoom);
      expect(restored.shoulderTorque, original.shoulderTorque);
      expect(restored.elbowTorque, original.elbowTorque);
      expect(restored.armLength, original.armLength);
      expect(restored.tipRadius, original.tipRadius);
      expect(restored.enemyRadius, original.enemyRadius);
      expect(restored.straighteningDuration, original.straighteningDuration);
      expect(restored.randomChangeInterval, original.randomChangeInterval);
      expect(restored.shoulderSpeedRange, original.shoulderSpeedRange);
      expect(restored.elbowSpeedRange, original.elbowSpeedRange);
    });

    test('fromJson で欠損フィールドはデフォルト値', () {
      final config = GameConfig.fromJson({});
      expect(config.gravity.y, 15);
      expect(config.zoom, 20.0);
      expect(config.shoulderTorque, 8000.0);
    });

    test('copyWith で指定フィールドのみ変更される', () {
      final original = GameConfig();
      final modified = original.copyWith(zoom: 50.0, elbowTorque: 999.0);

      expect(modified.zoom, 50.0);
      expect(modified.elbowTorque, 999.0);
      expect(modified.shoulderTorque, original.shoulderTorque);
      expect(modified.gravity.y, original.gravity.y);
      expect(modified.armLength, original.armLength);
    });

    test('copyWith で元のインスタンスは変更されない', () {
      final original = GameConfig();
      original.copyWith(zoom: 99.0);

      expect(original.zoom, 20.0);
    });

    group('loadFromAsset', () {
      TestWidgetsFlutterBinding.ensureInitialized();

      tearDown(() {
        rootBundle.evict('assets/game_config.json');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
        GameConfig.instance = GameConfig();
      });

      test('JSONファイルから読み込める', () async {
        final testConfig = {'zoom': 42.0, 'shoulderTorque': 7777.0};
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
              final key = utf8.decode(message!.buffer.asUint8List());
              if (key == 'assets/game_config.json') {
                return ByteData.sublistView(
                  utf8.encoder.convert(jsonEncode(testConfig)),
                );
              }
              return null;
            });

        final config = await GameConfig.loadFromAsset();
        expect(config.zoom, 42.0);
        expect(config.shoulderTorque, 7777.0);
        expect(config.gravity.y, 15);
        expect(GameConfig.instance.zoom, 42.0);
      });

      test('ファイルが無い場合はデフォルト値', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
              final key = utf8.decode(message!.buffer.asUint8List());
              if (key == 'assets/game_config.json') {
                return ByteData.sublistView(utf8.encoder.convert('invalid'));
              }
              return null;
            });

        final config = await GameConfig.loadFromAsset();
        expect(config.zoom, 20.0);
        expect(config.shoulderTorque, 8000.0);
        expect(GameConfig.instance.zoom, 20.0);
      });
    });
  });
}
