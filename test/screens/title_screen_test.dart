import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/accessors/ble_mock_accessor.dart';
import 'package:syncro_gattai_spaholder_app/screens/title_screen.dart';
import 'package:syncro_gattai_spaholder_app/widgets/connect_button.dart';
import 'package:syncro_gattai_spaholder_app/widgets/start_button.dart';

void main() {
  group('TitleScreen', () {
    late BleMockAccessor mockBle;

    setUp(() {
      mockBle = BleMockAccessor();
    });

    tearDown(() {
      mockBle.dispose();
    });

    Finder findConnectButton(ConnectButtonColor color) {
      return find.byWidgetPredicate(
        (widget) => widget is ConnectButton && widget.color == color,
      );
    }

    testWidgets('初期表示で接続ボタンと出動ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () {}, bleService: mockBle),
        ),
      );

      expect(find.text('接続'), findsNWidgets(2));
      expect(find.text('出動'), findsOneWidget);
    });

    testWidgets('未接続時は出動ボタンが無効でonStartが呼ばれない', (tester) async {
      var started = false;
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () => started = true, bleService: mockBle),
        ),
      );

      final startButton = tester.widget<StartButton>(find.byType(StartButton));
      expect(startButton.disabled, isTrue);

      await tester.tap(find.byType(StartButton));
      expect(started, isFalse);
    });

    testWidgets('接続ボタンをタップすると接続→切断の状態遷移が行われる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () {}, bleService: mockBle),
        ),
      );

      // blueデバイスを接続
      await tester.tap(findConnectButton(ConnectButtonColor.blue));
      await tester.pump();
      expect(find.text('接続中...'), findsOneWidget);
      expect(find.text('接続しました'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('切断'), findsOneWidget);
      expect(find.text('接続'), findsOneWidget); // red側はまだ未接続
      expect(find.text('接続しました'), findsNWidgets(2)); // 縁取り+塗りの2重表示

      // この時点では出動ボタンは無効
      var startButton = tester.widget<StartButton>(find.byType(StartButton));
      expect(startButton.disabled, isTrue);

      // redデバイスも接続
      await tester.tap(findConnectButton(ConnectButtonColor.red));
      await tester.pump();
      expect(find.text('切断中...'), findsNothing);
      expect(find.text('接続中...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('切断'), findsNWidgets(2));

      // 両方接続されたので出動ボタンが有効になる
      startButton = tester.widget<StartButton>(find.byType(StartButton));
      expect(startButton.disabled, isFalse);

      // blueデバイスを切断
      await tester.tap(findConnectButton(ConnectButtonColor.blue));
      await tester.pump();
      expect(find.text('切断中...'), findsOneWidget);
      expect(find.text('接続しました'), findsNWidgets(2)); // blue側のメッセージは消え、red側のみ残る

      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('接続'), findsOneWidget);
      expect(find.text('切断完了'), findsNWidgets(2));

      // 切断されたので出動ボタンは再び無効になる
      startButton = tester.widget<StartButton>(find.byType(StartButton));
      expect(startButton.disabled, isTrue);

      // メッセージの自動消去タイマー・Timer.periodicを停止
      await mockBle.disconnectAll();
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('接続完了メッセージは2秒後に自動的に消える', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () {}, bleService: mockBle),
        ),
      );

      await tester.tap(findConnectButton(ConnectButtonColor.blue));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('接続しました'), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('接続しました'), findsNothing);

      // Timer.periodicを停止
      await mockBle.disconnectAll();
      await tester.pump();
    });

    testWidgets('両方接続済みで出動ボタンをタップするとonStartが呼ばれる', (tester) async {
      var started = false;
      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () => started = true, bleService: mockBle),
        ),
      );

      await tester.tap(findConnectButton(ConnectButtonColor.blue));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(findConnectButton(ConnectButtonColor.red));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(StartButton));
      expect(started, isTrue);

      // メッセージの自動消去タイマー・Timer.periodicを停止
      await mockBle.disconnectAll();
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('小さい画面でもオーバーフローしない（未接続時）', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () {}, bleService: mockBle),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('小さい画面でもオーバーフローしない（接続済み時）', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreen(onStart: () {}, bleService: mockBle),
        ),
      );

      await tester.tap(findConnectButton(ConnectButtonColor.blue));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(findConnectButton(ConnectButtonColor.red));
      await tester.pump(const Duration(seconds: 1));

      await mockBle.disconnectAll();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
