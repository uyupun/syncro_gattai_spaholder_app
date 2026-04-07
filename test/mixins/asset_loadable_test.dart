import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/mixins/asset_loadable.dart';

void main() {
  group('AssetLoadable', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    tearDown(() {
      rootBundle.evict('assets/test.json');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('JSONファイルから読み込める', () async {
      final testData = {'value': 42};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final key = utf8.decode(message!.buffer.asUint8List());
            if (key == 'assets/test.json') {
              return ByteData.sublistView(
                utf8.encoder.convert(jsonEncode(testData)),
              );
            }
            return null;
          });

      final result = await AssetLoadable.loadFromAsset<int>(
        'assets/test.json',
        (json) => (json['value'] as num).toInt(),
        () => 0,
      );
      expect(result, 42);
    });

    test('ファイルが無い場合はデフォルト値', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final key = utf8.decode(message!.buffer.asUint8List());
            if (key == 'assets/test.json') {
              return ByteData.sublistView(utf8.encoder.convert('invalid'));
            }
            return null;
          });

      final result = await AssetLoadable.loadFromAsset<int>(
        'assets/test.json',
        (json) => (json['value'] as num).toInt(),
        () => -1,
      );
      expect(result, -1);
    });
  });
}
