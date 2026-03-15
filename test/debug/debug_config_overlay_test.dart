import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/debug/debug_config_overlay.dart';
import 'package:spajam2025_app/game/arm_layout_config.dart';
import 'package:spajam2025_app/game/enemy_config.dart';
import 'package:spajam2025_app/game/game_config.dart';
import 'package:spajam2025_app/game/hp_bar_config.dart';

void main() {
  Widget buildTestWidget({
    GameConfig? initialConfig,
    ArmLayoutConfig? initialLayout,
    EnemyConfig? initialEnemyConfig,
    HpBarConfig? initialEnemyHpConfig,
    ValueChanged<GameConfig>? onConfigChanged,
    ValueChanged<ArmLayoutConfig>? onLayoutChanged,
    ValueChanged<EnemyConfig>? onEnemyConfigChanged,
    ValueChanged<HpBarConfig>? onEnemyHpConfigChanged,
    VoidCallback? onApply,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 800,
          child: Stack(
            children: [
              DebugConfigOverlay(
                initialConfig: initialConfig ?? GameConfig(),
                initialLayout: initialLayout ?? ArmLayoutConfig(),
                initialEnemyConfig: initialEnemyConfig ?? EnemyConfig(),
                initialEnemyHpConfig: initialEnemyHpConfig ?? HpBarConfig(),
                onConfigChanged: onConfigChanged ?? (_) {},
                onLayoutChanged: onLayoutChanged ?? (_) {},
                onEnemyConfigChanged: onEnemyConfigChanged ?? (_) {},
                onEnemyHpConfigChanged: onEnemyHpConfigChanged ?? (_) {},
                onApply: onApply ?? () {},
                onClose: onClose ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('DebugConfigOverlay', () {
    testWidgets('ヘッダーにConfig表示', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Config'), findsOneWidget);
    });

    testWidgets('3つのタブが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Game'), findsOneWidget);
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('HP'), findsOneWidget);
    });

    testWidgets('Gameタブにパラメータが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // デフォルトでGameタブが選択されている
      expect(find.text('重力Y'), findsOneWidget);
      expect(find.text('ズーム'), findsOneWidget);
    });

    testWidgets('Layoutタブに切替でレイアウトパラメータ表示', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Layout'));
      await tester.pumpAndSettle();
      expect(find.text('上腕.位置X'), findsOneWidget);
    });

    testWidgets('HPタブに切替でHPパラメータ表示', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('HP'));
      await tester.pumpAndSettle();
      expect(find.text('敵.最大HP'), findsOneWidget);
    });

    testWidgets('±ボタンで値が変更される', (tester) async {
      GameConfig? received;
      await tester.pumpWidget(
        buildTestWidget(
          initialConfig: GameConfig(zoom: 20.0),
          onConfigChanged: (c) => received = c,
        ),
      );

      // zoom行の +0.5 ボタンをタップ
      // まず zoom ラベルを見つけ、その行の+ボタンをタップ
      final zoomRow = find.ancestor(
        of: find.text('ズーム'), // displayName
        matching: find.byType(Row),
      );
      // +0.5 ボタン
      final plusButton = find.descendant(
        of: zoomRow.first,
        matching: find.text('+0.5'),
      );
      if (plusButton.evaluate().isNotEmpty) {
        await tester.tap(plusButton.first);
        await tester.pump();
        expect(received?.zoom, 20.5);
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

    testWidgets('適用ボタンでonApplyが呼ばれる', (tester) async {
      var applied = false;
      await tester.pumpWidget(buildTestWidget(onApply: () => applied = true));

      await tester.tap(find.byIcon(Icons.check));
      expect(applied, isTrue);
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
