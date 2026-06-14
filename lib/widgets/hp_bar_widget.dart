import 'package:flutter/material.dart';

class HpBarWidget extends StatelessWidget {
  final double hp;
  final double maxHp;
  final double width;
  final double barHeight;

  static const _green = Color(0xFF3AB84E);
  static const _yellow = Color(0xFFC8A000);
  static const _red = Color(0xFFC03020);

  const HpBarWidget({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.width,
    required this.barHeight,
  });

  double get _ratio => (maxHp > 0 ? hp / maxHp : 0.0).clamp(0.0, 1.0);

  Color get _mainColor {
    if (_ratio > 0.5) return _green;
    if (_ratio > 0.25) return _yellow;
    return _red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _mainColor;
    final currentHp = hp.round().toString();
    final maxHpLabel = maxHp.round().toString();

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      color: const Color(0xFF434343),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HP',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currentHp/$maxHpLabel',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: barHeight,
                    color: color.withValues(alpha: 0.15),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * _ratio,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
