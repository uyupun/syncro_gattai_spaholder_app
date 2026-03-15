import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/accessors/ble_mock_accessor.dart';
import 'package:spajam2025_app/screens/debug_screen.dart';

void main() {
  group('DebugScreen', () {
    late BleMockAccessor mockBle;

    setUp(() {
      mockBle = BleMockAccessor();
    });

    tearDown(() {
      mockBle.dispose();
    });

    testWidgets('BLEタブと設定タブが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DebugScreen(bleService: mockBle)),
      );

      expect(find.text('BLE'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('AppBarにデバッグタイトルが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DebugScreen(bleService: mockBle)),
      );

      expect(find.text('デバッグ'), findsOneWidget);
    });
  });
}
