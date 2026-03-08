import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/debug/debug_config_overlay.dart';
import 'package:spajam2025_app/game/game_config.dart';

void main() {
  Widget buildTestWidget({
    GameConfig? initialConfig,
    ValueChanged<GameConfig>? onConfigChanged,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            DebugConfigOverlay(
              initialConfig: initialConfig ?? GameConfig(),
              onConfigChanged: onConfigChanged ?? (_) {},
              onClose: onClose ?? () {},
            ),
          ],
        ),
      ),
    );
  }

  group('DebugConfigOverlay', () {
    testWidgets('ヘッダーにConfig表示', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Config'), findsOneWidget);
    });

    testWidgets('全パラメータのSliderが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      for (final label in [
        'gravity.y',
        'zoom',
        'shoulderTorque',
        'elbowTorque',
        'armLength',
        'tipRadius',
        'enemyRadius',
        'straighteningDuration',
        'randomChangeInterval',
        'shoulderSpeedRange',
        'elbowSpeedRange',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label が見つからない');
      }
    });

    testWidgets('閉じるボタンでonCloseが呼ばれる', (tester) async {
      var closed = false;
      await tester.pumpWidget(buildTestWidget(onClose: () => closed = true));

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets('リセットボタンでデフォルト値に復元', (tester) async {
      GameConfig? received;
      await tester.pumpWidget(
        buildTestWidget(
          initialConfig: GameConfig(zoom: 99.0),
          onConfigChanged: (c) => received = c,
        ),
      );

      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pump();

      expect(received?.zoom, 20.0);
    });

    testWidgets('エクスポートボタンでSnackBar表示', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async => null,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      expect(find.text('JSONをクリップボードにコピーしました'), findsOneWidget);
    });
  });
}
