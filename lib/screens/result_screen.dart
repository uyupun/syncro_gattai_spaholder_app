import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/primary_button.dart';

class ResultScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onTitle;

  const ResultScreen({super.key, required this.result, required this.onTitle});

  String get _backgroundImage => switch (result) {
    GameResult.yugarockLose => 'assets/images/result_screen_background_2.png',
    GameResult.asyncronLose ||
    GameResult.allClear => 'assets/images/result_screen_background_1.png',
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(_backgroundImage, fit: BoxFit.cover),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: PrimaryButton(label: '帰還する', onTap: onTitle),
          ),
        ),
      ],
    );
  }
}
