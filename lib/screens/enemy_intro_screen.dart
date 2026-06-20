import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/outlined_text.dart';

class EnemyIntroScreen extends StatefulWidget {
  final BattleStage stage;
  final VoidCallback onComplete;

  const EnemyIntroScreen({
    super.key,
    required this.stage,
    required this.onComplete,
  });

  @override
  State<EnemyIntroScreen> createState() => _EnemyIntroScreenState();
}

class _EnemyIntroScreenState extends State<EnemyIntroScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onComplete();
    });
  }

  String get _message => switch (widget.stage) {
    BattleStage.yugarock => '岩石怪獣ユガロック現る！',
    BattleStage.asyncron => '恐怖！岩石魔王アシンクロン',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF434343),
      child: Stack(
        children: [
          if (widget.stage == BattleStage.asyncron)
            Positioned.fill(
              child: Image.asset(
                'assets/bg/asyncron_title.png',
                fit: BoxFit.cover,
              ),
            ),
          Center(
            child: OutlinedText(
              text: _message,
              fontSize: 40,
              strokeWidth: widget.stage == BattleStage.asyncron ? 8 : 4,
            ),
          ),
        ],
      ),
    );
  }
}
