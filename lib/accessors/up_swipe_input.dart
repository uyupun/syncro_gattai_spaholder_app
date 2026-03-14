import 'dart:async';

import '../interfaces/gesture_input.dart';

class UpSwipeInput implements GestureInput {
  static const _kVelocityThreshold = -200.0;
  static const _kTimeout = Duration(milliseconds: 500);

  bool _detected = false;
  Timer? _timer;

  @override
  void feed(double dx, double dy) {
    if (dy >= _kVelocityThreshold) return;

    _detected = true;
    _timer?.cancel();
    _timer = Timer(_kTimeout, reset);
  }

  @override
  bool get isDetected => _detected;

  @override
  void reset() {
    _timer?.cancel();
    _detected = false;
  }

  void dispose() {
    _timer?.cancel();
  }
}
