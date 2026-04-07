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

    testWidgets('小さい画面でもオーバーフローしない（BLEタブ）', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: DebugScreen(bleService: mockBle)),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('小さい画面でもオーバーフローしない（設定タブ）', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: DebugScreen(bleService: mockBle)),
      );

      // 設定タブに切り替え
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
