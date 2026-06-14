import 'package:flutter/material.dart';

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  static const Color _color = Color(0xFF6F09AE);

  const OutlineButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: _color, width: 3),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
