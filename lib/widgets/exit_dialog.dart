import 'package:flutter/material.dart';

import 'outline_button.dart';
import 'primary_button.dart';

class ExitDialog extends StatelessWidget {
  final String continueLabel;
  final String exitLabel;
  final VoidCallback onContinue;
  final VoidCallback onExit;

  const ExitDialog({
    super.key,
    required this.continueLabel,
    required this.exitLabel,
    required this.onContinue,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '諦めますか？',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlineButton(label: continueLabel, onTap: onContinue),
                const SizedBox(width: 40),
                PrimaryButton(label: exitLabel, onTap: onExit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
