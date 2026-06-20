import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// シンクロチャージの蓄積状況を表す5つのインジケーター
class ChargeLevelIndicator extends StatelessWidget {
  final int chargeLevel;

  static const int _maxLevel = 5;
  static const double _gap = 10.0;
  static const String _activeSvgPath = 'assets/images/charge-active.svg';
  static const String _inactiveSvgPath = 'assets/images/charge-inactive.svg';

  const ChargeLevelIndicator({super.key, required this.chargeLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_maxLevel, (index) {
        final isActive = index < chargeLevel;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : _gap),
          child: SvgPicture.asset(
            isActive ? _activeSvgPath : _inactiveSvgPath,
            width: 11,
            height: 17,
          ),
        );
      }),
    );
  }
}
