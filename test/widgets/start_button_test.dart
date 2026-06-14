import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/widgets/start_button.dart';

void main() {
  group('StartButton', () {
    testWidgets('ラベルが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StartButton(label: '出動')),
      );

      expect(find.text('出動'), findsOneWidget);
    });

    testWidgets('タップでonTapが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StartButton(label: '出動', onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(StartButton));
      expect(tapped, isTrue);
    });

    testWidgets('disabled時はタップしてもonTapが呼ばれない', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StartButton(
            label: '出動',
            disabled: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(StartButton));
      expect(tapped, isFalse);
    });

    testWidgets('非disabled時は背景色6F09AE・文字色F5F5F5になる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StartButton(label: '出動')),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF6F09AE));
      expect(decoration.border?.top.color, const Color(0xFF1A1A1A));
      expect(decoration.border?.top.width, 1);

      final text = tester.widget<Text>(find.text('出動'));
      expect(text.style?.color, const Color(0xFFF5F5F5));
    });

    testWidgets('disabled時は背景色844BA8・文字色C5C5C5になる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StartButton(label: '出動', disabled: true)),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF844BA8));

      final text = tester.widget<Text>(find.text('出動'));
      expect(text.style?.color, const Color(0xFFC5C5C5));
    });

    testWidgets('125x125のサイズになる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: StartButton(label: '出動')),
        ),
      );

      final size = tester.getSize(find.byType(StartButton));
      expect(size, const Size(125, 125));
    });
  });
}
