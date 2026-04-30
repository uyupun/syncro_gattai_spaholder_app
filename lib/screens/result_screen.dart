import 'package:flutter/material.dart';

import '../main.dart';

class ResultScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onTitle;
  final VoidCallback onRetry;

  const ResultScreen({
    super.key,
    required this.result,
    required this.onTitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: switch (result) {
            GameResult.allClear => _TitleButton(onTap: onTitle),
            _ => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RetryButton(onTap: onRetry),
                const SizedBox(width: 40),
                _TitleButton(onTap: onTitle),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      child: const Text('再挑戦'),
    );
  }
}

class _TitleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TitleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      child: const Text('タイトル'),
    );
  }
}
