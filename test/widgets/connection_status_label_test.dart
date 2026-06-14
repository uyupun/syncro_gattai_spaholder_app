import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncro_gattai_spaholder_app/widgets/connection_status_label.dart';

void main() {
  group('ConnectionStatusLabel', () {
    testWidgets('テキストが縁取り用と塗り用の2重で表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ConnectionStatusLabel(text: '接続しました')),
      );

      expect(find.text('接続しました'), findsNWidgets(2));
    });

    testWidgets('塗りテキストのスタイルが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ConnectionStatusLabel(text: '切断完了')),
      );

      final texts = tester.widgetList<Text>(find.text('切断完了'));
      final fillText = texts.firstWhere((t) => t.style?.foreground == null);
      expect(fillText.style?.fontSize, 16);
      expect(fillText.style?.color, const Color(0xFF1A1A1A));
    });

    testWidgets('縁取りテキストのスタイルが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ConnectionStatusLabel(text: '切断完了')),
      );

      final texts = tester.widgetList<Text>(find.text('切断完了'));
      final outlineText = texts.firstWhere((t) => t.style?.foreground != null);
      final paint = outlineText.style!.foreground!;
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.strokeWidth, 2);
      expect(paint.color.toARGB32(), const Color(0xFFF5F5F5).toARGB32());
    });
  });
}
