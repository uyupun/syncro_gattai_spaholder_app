import 'package:flutter/material.dart';

import '../interfaces/gesture_input.dart';

class GestureInputArea extends StatelessWidget {
  final GestureInput input;
  final VoidCallback? onFed;
  final Widget? child;

  const GestureInputArea({
    super.key,
    required this.input,
    this.onFed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        input.feed(0, details.primaryVelocity ?? 0);
        onFed?.call();
      },
      child: child ?? const SizedBox.expand(),
    );
  }
}
