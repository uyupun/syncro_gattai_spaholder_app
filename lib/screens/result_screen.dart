import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/primary_button.dart';

class ResultScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onTitle;

  const ResultScreen({super.key, required this.result, required this.onTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: PrimaryButton(label: '帰還する', onTap: onTitle),
        ),
      ),
    );
  }
}
