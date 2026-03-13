import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/accessors/ble_mock_accessor.dart';
import 'package:spajam2025_app/screens/title_screen.dart';

void main() {
  group('TitleScreen', () {
    late BleMockAccessor mockBle;

    setUp(() {
      mockBle = BleMockAccessor();
    });

    tearDown(() {
      mockBle.dispose();
    });

    testWidgets('初期表示でデバイス接続ボタンとスタートボタンが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(
            onStart: () {},
            bleService: mockBle,
          ),
        ),
      );

      expect(find.text('デバイス接続'), findsOneWidget);
      expect(find.text('ゲームスタート'), findsOneWidget);
    });

    testWidgets('未接続時はスタートボタンが無効', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(
            onStart: () {},
            bleService: mockBle,
          ),
        ),
      );

      // スタートボタンを探す
      final startButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'ゲームスタート'),
      );
      expect(startButton.onPressed, isNull);
    });

    testWidgets('接続デバイス数が表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(
            onStart: () {},
            bleService: mockBle,
          ),
        ),
      );

      expect(find.text('接続デバイス数: 0/2'), findsOneWidget);
    });
  });
}
