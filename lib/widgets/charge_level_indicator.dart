import 'package:flutter/material.dart';

/// シンクロチャージの蓄積状況を表す5つの円
class ChargeLevelIndicator extends StatelessWidget {
  final int chargeLevel;

  static const int _maxLevel = 5;
  static const double _circleSize = 16.0;
  static const double _gap = 10.0;
  static const Color _inactiveColor = Color(0xFFC5C5C5);
  static const Color _activeColor = Color(0xFFFCC727);

  const ChargeLevelIndicator({super.key, required this.chargeLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_maxLevel, (index) {
        final isActive = index < chargeLevel;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : _gap),
          child: Container(
            width: _circleSize,
            height: _circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _activeColor : _inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}
