import 'package:flutter/material.dart';

import '../interfaces/gesture_input.dart';

class LongPressInputArea extends StatelessWidget {
  final GestureInput input;
  final VoidCallback? onFed;
  final Widget? child;

  const LongPressInputArea({
    super.key,
    required this.input,
    this.onFed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        input.feed(0, 0);
        onFed?.call();
      },
      child: child ?? const SizedBox.expand(),
    );
  }
}
