import 'package:flutter/material.dart';

class CountdownScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const CountdownScreen({super.key, required this.onComplete});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  int _count = 3;
  bool _showGameStart = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    // 3, 2, 1 カウントダウン
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() {
        _count = i;
        _showGameStart = false;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    // 0 → ゲームスタート表示
    if (!mounted) return;
    setState(() {
      _count = 0;
      _showGameStart = true;
    });
    await Future.delayed(const Duration(seconds: 1));

    // ゲーム画面へ遷移
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Text(
          _showGameStart ? 'ゲームスタート' : '$_count',
          style: TextStyle(
            color: Colors.black87,
            fontSize: _showGameStart ? 48 : 120,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                blurRadius: 10,
                color: Colors.blueAccent,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
