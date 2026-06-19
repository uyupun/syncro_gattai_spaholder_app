import 'package:flutter/material.dart';

import '../main.dart';
import '../resources/game_se.dart';
import '../widgets/primary_button.dart';

class ResultScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onTitle;

  const ResultScreen({super.key, required this.result, required this.onTitle});

  String get _backgroundImage => switch (result) {
    GameResult.yugarockLose => 'assets/bg/defeat.png',
    GameResult.asyncronLose || GameResult.allClear => 'assets/bg/victory.png',
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(_backgroundImage, fit: BoxFit.cover),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            switch (result) {
              GameResult.yugarockLose => '負けてしまった...',
              GameResult.asyncronLose => '勝利！',
              GameResult.allClear => '完全勝利！',
            },
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: PrimaryButton(
              label: '帰還する',
              onTap: () {
                GameSe.giveUpButton.play();
                onTitle();
              },
            ),
          ),
        ),
      ],
    );
  }
}
