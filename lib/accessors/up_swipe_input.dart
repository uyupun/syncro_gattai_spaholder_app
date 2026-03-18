import 'dart:async';

import '../interfaces/gesture_input.dart';

class UpSwipeInput implements GestureInput {
  static const _kVelocityThreshold = 10.0;
  static const _kTimeout = Duration(seconds: 5);

  bool _detected = false;
  Timer? _timer;

  @override
  void feed(double dx, double dy) {
    if (dy == 0.0 || dy.abs() < _kVelocityThreshold) return;

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
