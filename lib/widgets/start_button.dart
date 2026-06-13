import 'package:flutter/material.dart';

class StartButton extends StatelessWidget {
  final String label;
  final bool disabled;
  final VoidCallback? onTap;

  static const double _size = 125;
  static const Color _enabledColor = Color(0xFF6F09AE);
  static const Color _disabledColor = Color(0xFF844BA8);
  static const Color _borderColor = Color(0xFF1A1A1A);
  static const Color _enabledTextColor = Color(0xFFF5F5F5);
  static const Color _disabledTextColor = Color(0xFFC5C5C5);

  const StartButton({
    super.key,
    required this.label,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled ? _disabledColor : _enabledColor,
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? _disabledTextColor : _enabledTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
