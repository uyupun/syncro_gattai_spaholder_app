import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/widgets/hp_bar_widget.dart';

const _green = Color(0xFF3AB84E);
const _yellow = Color(0xFFC8A000);
const _red = Color(0xFFC03020);

void main() {
  group('HpBarWidget', () {
    Widget buildWidget(double hp, double maxHp) {
      return MaterialApp(
        home: Scaffold(
          body: HpBarWidget(hp: hp, maxHp: maxHp, width: 300, barHeight: 8),
        ),
      );
    }

    Color barColor(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      return (container.decoration as BoxDecoration).color!;
    }

    Color hpLabelColor(WidgetTester tester) {
      final text = tester.widget<Text>(find.text('HP'));
      return text.style!.color!;
    }

    testWidgets('HPが51〜100のとき緑色で表示される', (tester) async {
      await tester.pumpWidget(buildWidget(100, 100));
      await tester.pumpAndSettle();

      expect(barColor(tester), _green);
      expect(hpLabelColor(tester), _green);
      expect(find.text('100/100'), findsOneWidget);
    });

    testWidgets('HPが26〜50のとき黄色で表示される', (tester) async {
      await tester.pumpWidget(buildWidget(50, 100));
      await tester.pumpAndSettle();

      expect(barColor(tester), _yellow);
      expect(hpLabelColor(tester), _yellow);
      expect(find.text('50/100'), findsOneWidget);
    });

    testWidgets('HPが0〜25のとき赤色で表示される', (tester) async {
      await tester.pumpWidget(buildWidget(25, 100));
      await tester.pumpAndSettle();

      expect(barColor(tester), _red);
      expect(hpLabelColor(tester), _red);
      expect(find.text('25/100'), findsOneWidget);
    });

    testWidgets('HPが減少すると色とバーの幅がアニメーションしながら変化する', (tester) async {
      double hp = 100;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    HpBarWidget(hp: hp, maxHp: 100, width: 300, barHeight: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => hp = 25),
                      child: const Text('damage'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fullWidth = tester.getSize(find.byType(AnimatedContainer)).width;
      expect(barColor(tester), _green);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final midWidth = tester.getSize(find.byType(AnimatedContainer)).width;
      final quarterWidth = fullWidth * 0.25;
      expect(midWidth, lessThan(fullWidth));
      expect(midWidth, greaterThan(quarterWidth));

      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(AnimatedContainer)).width,
        quarterWidth,
      );
      expect(barColor(tester), _red);
    });
  });
}
