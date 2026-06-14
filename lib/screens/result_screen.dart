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

  /// キャラクター画像のリスト
  List<String> get _characterImages => switch (result) {
    GameResult.yugarockLose => [
      'assets/images/spaholder_lose.png',
      'assets/images/yugarock.png',
    ],
    GameResult.asyncronLose => [
      'assets/images/yugarock_splashA.png',
      'assets/images/spaholder.png',
      'assets/images/yugarock_splashA.png',
    ],
    GameResult.allClear => [
      'assets/images/yugarock_splashA.png',
      'assets/images/spaholder.png',
      'assets/images/asyncron_lose.png',
    ],
  };

  List<Widget> _buildCharacterWidgets() {
    if (_characterImages.length == 3) {
      return [
        Image.asset(_characterImages[0], width: 180, fit: BoxFit.contain),
        Image.asset(_characterImages[1], width: 350, fit: BoxFit.contain),
        Image.asset(_characterImages[2], width: 180, fit: BoxFit.contain),
      ];
    } else {
      return _characterImages
          .map((path) => Image.asset(path, width: 250, fit: BoxFit.contain))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(_backgroundImage, fit: BoxFit.cover),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildCharacterWidgets(),
          ),
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
