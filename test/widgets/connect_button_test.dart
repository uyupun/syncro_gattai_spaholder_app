import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncro_gattai_spaholder_app/widgets/connect_button.dart';

void main() {
  group('ConnectButton', () {
    testWidgets('ラベルが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectButton(label: '接続', color: ConnectButtonColor.blue),
        ),
      );

      expect(find.text('接続'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('タップでonTapが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectButton(
            label: '接続',
            color: ConnectButtonColor.blue,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ConnectButton));
      expect(tapped, isTrue);
    });

    testWidgets('disabled時はタップしてもonTapが呼ばれない', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectButton(
            label: '接続',
            color: ConnectButtonColor.red,
            disabled: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ConnectButton));
      expect(tapped, isFalse);
    });

    testWidgets('disabled時はSVGの塗り色がdisabledFillに変更される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectButton(
            label: '接続',
            color: ConnectButtonColor.blue,
            disabled: true,
          ),
        ),
      );

      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svgPicture.bytesLoader as SvgAssetLoader;
      final mapper = loader.colorMapper!;
      expect(
        mapper.substitute(
          null,
          'path',
          'fill',
          ConnectButtonColor.blue.enabledFill,
        ),
        ConnectButtonColor.blue.disabledFill,
      );
    });

    testWidgets('非disabled時はSVGの塗り色を変更しない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectButton(label: '接続', color: ConnectButtonColor.blue),
        ),
      );

      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svgPicture.bytesLoader as SvgAssetLoader;
      expect(loader.colorMapper, isNull);
    });

    testWidgets('非disabled時は文字色がF5F5F5になる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectButton(label: '接続', color: ConnectButtonColor.blue),
        ),
      );

      final text = tester.widget<Text>(find.text('接続'));
      expect(text.style?.color, const Color(0xFFF5F5F5));
    });

    testWidgets('disabled時は文字色がC5C5C5になる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectButton(
            label: '接続中...',
            color: ConnectButtonColor.blue,
            disabled: true,
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('接続中...'));
      expect(text.style?.color, const Color(0xFFC5C5C5));
    });
  });
}
