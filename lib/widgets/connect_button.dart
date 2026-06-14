import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ConnectButtonColor {
  blue(
    'assets/images/connect_button_blue.svg',
    Color(0xFF0D47A1),
    Color(0xFF39619F),
  ),
  red(
    'assets/images/connect_button_red.svg',
    Color(0xFFD32F2F),
    Color(0xFFC24949),
  );

  final String asset;
  final Color enabledFill;
  final Color disabledFill;

  const ConnectButtonColor(this.asset, this.enabledFill, this.disabledFill);
}

class _FillColorMapper extends ColorMapper {
  const _FillColorMapper(this.from, this.to);

  final Color from;
  final Color to;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (attributeName == 'fill' && color == from) {
      return to;
    }
    return color;
  }
}

class ConnectButton extends StatelessWidget {
  final String label;
  final ConnectButtonColor color;
  final bool disabled;
  final VoidCallback? onTap;

  const ConnectButton({
    super.key,
    required this.label,
    required this.color,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            color.asset,
            colorMapper: disabled
                ? _FillColorMapper(color.enabledFill, color.disabledFill)
                : null,
          ),
          Text(
            label,
            style: TextStyle(
              color: disabled
                  ? const Color(0xFFC5C5C5)
                  : const Color(0xFFF5F5F5),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
